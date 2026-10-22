#!/usr/bin/env bash
# ai-suggestion:unverified | date:2026-10-21
#
# Ark "models" lane: Ollama models (queues/ollama.tsv) into a model store on the archive, then
# Hugging Face files (queues/huggingface.tsv). One download at a time, resumable.
#
# Ollama: a private Ollama server is started just for this lane, storing models under
# ARK_OLLAMA_STORE and listening on ARK_OLLAMA_HOST, then stopped. It does not touch the models of
# an Ollama app you already run. Ollama checks each layer's SHA-256 while pulling; afterwards the
# helper re-hashes every layer against its digest (ARK_REHASH=0 checks sizes only).
# Hugging Face: each repository is pinned to one commit, downloaded with the official "hf" tool
# without a login, then every file is re-hashed against the hashes the Hub publishes.
#
# Usage:   ARK_ROOT=/Volumes/ARK bash scripts/ark-models.sh
# Needs:   bash, curl, python3; "ollama" for Ollama items; "hf" (pip install -U huggingface_hub)
#          for Hugging Face items. Items whose tool is missing are marked SKIPPED.
set -u
# shellcheck source=ark-common.sh
. "$(cd "$(dirname "$0")" && pwd)/ark-common.sh"

ark_require curl python3
ark_ready || ark_die "$ARK_NOT_READY"
ark_lane_start models

ARK_OLLAMA_STORE=${ARK_OLLAMA_STORE:-$ARK_ROOT/models/ollama}
ARK_OLLAMA_HOST=${ARK_OLLAMA_HOST:-127.0.0.1:11436}   # not 11434, which the Ollama app uses
export ARK_OLLAMA_STORE
OPID=

ollama_up() { curl -q -s --max-time 3 "http://$ARK_OLLAMA_HOST/api/version" >/dev/null 2>&1; }

start_ollama() {
  local i=0
  if ollama_up; then
    [ -n "$OPID" ] && return 0
    [ "${ARK_OLLAMA_REUSE:-0}" = 1 ] && return 0
    ark_state models ollama FAILED "something already answers on $ARK_OLLAMA_HOST. Set ARK_OLLAMA_HOST to a free port, or ARK_OLLAMA_REUSE=1 if that server already stores its models in $ARK_OLLAMA_STORE"
    return 1
  fi
  # OLLAMA_NOPRUNE keeps Ollama from removing unreferenced files from the store at startup.
  # HOME points inside the archive so the server's identity key is not written to your home folder.
  mkdir -p "$ARK_LOGS/ollama-home"
  HOME="$ARK_LOGS/ollama-home" OLLAMA_MODELS="$ARK_OLLAMA_STORE" OLLAMA_HOST="$ARK_OLLAMA_HOST" OLLAMA_NOPRUNE=1 \
    nohup ollama serve >> "$ARK_LOGS/ollama-serve.log" 2>&1 < /dev/null &
  OPID=$!
  while [ "$i" -lt 60 ]; do
    ollama_up && return 0
    sleep 2; i=$(( i + 1 ))
  done
  return 1
}

stop_ollama() {
  if [ -n "$OPID" ]; then
    kill "$OPID" 2>/dev/null
    wait "$OPID" 2>/dev/null
    OPID=
  fi
}
trap stop_ollama EXIT
trap 'exit 130' INT TERM

mark_skipped() { # plan-file reason
  local id _rest
  while IFS=$'\t' read -r id _rest; do
    [ -n "$id" ] || continue
    ark_done "$id" || ark_state models "$id" SKIPPED "$2"
  done < "$1"
}

do_ollama() {
  local plan="$ARK_LOGS/plan-ollama.tsv" id tier model bytes log
  ark_helper ollama-plan "$plan" "$ARK_LOGS/items-models-ollama.tsv" || return 1
  [ -s "$plan" ] || return 0
  if ! ark_has ollama; then
    mark_skipped "$plan" "ollama is not installed (https://ollama.com/download)"
    return 0
  fi
  mkdir -p "$ARK_OLLAMA_STORE" || { ark_state models ollama FAILED "cannot create $ARK_OLLAMA_STORE"; return 1; }
  while IFS=$'\t' read -r id tier model bytes <&3; do
    [ -n "$id" ] || continue
    ark_done "$id" && continue
    ark_ready || { stop_ollama; return 2; }
    [ "$bytes" = "-" ] && bytes=0
    if ! ark_room_for "$bytes"; then
      ark_state models "$id" SKIPPED-SPACE "needs about $(ark_gb "$bytes") GB; $(ark_gb "$(ark_free_bytes)") GB free; keeping $ARK_MIN_FREE_GB GB free"
      continue
    fi
    if ! start_ollama; then
      ark_state models "$id" FAILED "no private Ollama server on $ARK_OLLAMA_HOST (reason in the line above or in ollama-serve.log)"
      return 1
    fi
    log="$ARK_LOGS/ollama-pull-$(printf '%s' "$model" | tr -c 'A-Za-z0-9._-' '_').jsonl"
    ark_state models "$id" DOWNLOADING "pull from registry.ollama.ai (about $(ark_gb "$bytes") GB)"
    ark_reserve "$bytes" "$ARK_OLLAMA_STORE/blobs"
    curl -q -sN --max-time 86400 -H 'Content-Type: application/json' \
      -d "{\"model\":\"$model\",\"name\":\"$model\",\"stream\":true}" \
      "http://$ARK_OLLAMA_HOST/api/pull" > "$log" 2>&1
    ark_reserve 0
    if tail -n 1 "$log" | grep -q '"status":"success"'; then
      if detail=$(ark_helper ollama-verify "$ARK_OLLAMA_STORE" "$model"); then
        ark_state models "$id" VERIFIED "$detail"
      else
        ark_state models "$id" VERIFY-FAILED "$detail"
      fi
    else
      ark_state models "$id" FAILED "pull did not finish ($(tail -n 1 "$log" | cut -c1-160)); it resumes next pass"
    fi
  done 3< "$plan"
  stop_ollama
  return 0
}

do_hf() {
  local plan="$ARK_LOGS/plan-hf.tsv" id tier repo kind subdir include rev bytes need dir p oldifs detail
  ark_helper hf-plan "$plan" "$ARK_LOGS/items-models-hf.tsv" || return 1
  [ -s "$plan" ] || return 0
  if ! ark_has hf; then
    mark_skipped "$plan" "the Hugging Face 'hf' tool is not installed (pip install -U huggingface_hub)"
    return 0
  fi
  # No login, no telemetry, no token from your usual Hugging Face settings or environment, no
  # extra cache, and one file at a time with at most ARK_CONNECTIONS range requests.
  unset HF_TOKEN HUGGING_FACE_HUB_TOKEN HF_HUB_ENABLE_HF_TRANSFER HF_HUB_OFFLINE
  HF_HOME=${ARK_HF_HOME:-$ARK_LOGS/hf-home}
  export HF_HOME HF_HUB_DISABLE_TELEMETRY=1 HF_HUB_DISABLE_IMPLICIT_TOKEN=1 \
    HF_HUB_DISABLE_PROGRESS_BARS=1 HF_XET_CHUNK_CACHE_SIZE_BYTES=0 \
    HF_XET_NUM_CONCURRENT_RANGE_GETS="$ARK_CONNECTIONS"
  while IFS=$'\t' read -r id tier repo kind subdir include rev bytes need <&3; do
    [ -n "$id" ] || continue
    ark_done "$id" && continue
    ark_ready || return 2
    [ "$include" = "-" ] && include=
    [ "$bytes" = "-" ] && bytes=0
    case $need in ''|-|*[!0-9]*) need=$bytes ;; esac
    dir="$ARK_ROOT/$subdir"
    if ! ark_room_for "$need"; then
      ark_state models "$id" SKIPPED-SPACE "needs about $(ark_gb "$need") GB more; $(ark_gb "$(ark_free_bytes)") GB free; keeping $ARK_MIN_FREE_GB GB free"
      continue
    fi
    mkdir -p "$dir" || { ark_state models "$id" FAILED "cannot create $dir"; continue; }
    set -- download "$repo" --revision "$rev" --local-dir "$dir" --max-workers 1
    [ "$kind" = dataset ] && set -- "$@" --repo-type dataset
    oldifs=$IFS; IFS=,; set -f
    for p in $include; do
      [ -n "$p" ] && set -- "$@" --include "$p"
    done
    set +f; IFS=$oldifs
    ark_state models "$id" DOWNLOADING "$repo at commit ${rev:0:12} ($(ark_gb "$bytes") GB)"
    ark_reserve "$need" "$dir"
    if hf "$@" >> "$ARK_LOGS/hf-download.log" 2>&1 < /dev/null; then
      ark_reserve 0
      if detail=$(ark_helper hf-verify "$repo" "$kind" "$rev" "$dir" "$include"); then
        ark_state models "$id" VERIFIED "$detail"
      else
        ark_state models "$id" VERIFY-FAILED "$detail"
      fi
    else
      ark_reserve 0
      ark_state models "$id" FAILED "hf download stopped; it resumes next pass (details in hf-download.log)"
    fi
  done 3< "$plan"
  return 0
}

run_pass() {
  local rc
  do_ollama; rc=$?
  [ "$rc" = 2 ] && return 2
  do_hf; rc=$?
  [ "$rc" = 2 ] && return 2
  return 0
}

ark_run_passes models run_pass
ark_lane_end
