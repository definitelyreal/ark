#!/usr/bin/env bash
# ai-suggestion:unverified | date:2026-10-21
#
# Ark "files" lane: Kiwix ZIM libraries (the newest edition of each, pinned once it is looked up)
# and the direct downloads in queues/files.tsv (PDFs, map extracts, operating-system images).
# One file at a time, resumable. Each file is checked against the publisher's checksum; when a
# publisher offers none, its SHA-256 is recorded instead. Nothing is deleted: a file that fails
# its check is renamed with a .bad-<time> suffix.
#
# Usage:   ARK_ROOT=/Volumes/ARK bash scripts/ark-files.sh
# Options: ARK_TIERS="core optional giant", ARK_ONLY="wikipedia", and the rest in ark-common.sh.
# Needs:   bash, curl, python3; aria2c is used when installed (mirrors, piece checks).
set -u
# shellcheck source=ark-common.sh
. "$(cd "$(dirname "$0")" && pwd)/ark-common.sh"

ark_require curl python3
ark_ready || ark_die "$ARK_NOT_READY"
ark_lane_start files
PLAN="$ARK_LOGS/plan-files.tsv"
DLOG="$ARK_LOGS/files-download.log"

# verify_one <id> <dir> <filename> <url> <check> <checksum>; returns 0 when the file passes.
verify_one() {
  local id=$1 dir=$2 fname=$3 url=$4 check=$5 sum=$6 out algo want got src fails
  out="$dir/$fname"
  case $check in
    kiwix|sha256) algo=sha256; want=$sum ;;
    md5) algo=md5; want=$sum ;;
    sha256-url|md5-url)
      algo=${check%-url}
      src=${sum:-$url.$algo}
      # A one-line checksum file gives its first field; a SUMS file gives the line naming this file.
      want=$(curl -q -fsSL --retry 5 -A "$ARK_USER_AGENT" "$src" | awk -v f="$fname" '
        NR == 1 { first = $1 }
        { n = $2; sub(/^\*/, "", n); sub(/^.*\//, "", n); if (n == f) { print $1; hit = 1; exit } }
        END { if (!hit && NR == 1) print first }')
      if [ -z "$want" ]; then
        ark_state files "$id" FAILED "could not read the checksum at $src; will try again next pass"
        return 1
      fi ;;
    record) algo=sha256; want= ;;
    *) ark_state files "$id" FAILED "unknown check '$check' in files.tsv"; return 1 ;;
  esac
  case $fname in
    *.pdf|*.PDF)
      if ark_has file && ! file -b "$out" | grep -qi 'pdf'; then
        ark_move_aside "$out" not-pdf
        ark_state files "$id" VERIFY-FAILED "the server did not return a PDF (often an error page); moved it aside"
        return 1
      fi ;;
  esac
  if [ "$algo" = md5 ]; then got=$(ark_md5 "$out"); else got=$(ark_sha256 "$out"); fi
  want=$(printf '%s' "$want" | tr 'A-F' 'a-f')
  if [ -z "$want" ]; then
    ark_write_sum "$out" sha256 "$got"
    ark_state files "$id" RECORDED "publisher gives no checksum; recorded sha256 $got in $fname.sha256"
    return 0
  fi
  if [ "$got" = "$want" ]; then
    ark_write_sum "$out" "$algo" "$got"
    ark_state files "$id" VERIFIED "$algo $got matches the publisher"
    return 0
  fi
  fails=$(ark_count_state "$id" VERIFY-FAILED)
  if [ "$check" = kiwix ] && ark_has aria2c && [ "$fails" -lt 1 ]; then
    ark_state files "$id" VERIFY-FAILED "$algo $got, expected $want; next pass re-checks every piece and fetches only the bad ones"
  else
    ark_move_aside "$out" bad
    ark_move_aside "$out.aria2" bad
    ark_state files "$id" VERIFY-FAILED "$algo $got, expected $want; moved the bad copy aside, next pass downloads it again"
  fi
  return 1
}

run_pass() {
  local id tier subdir fname url bytes check sum dir out have written need prev complete meta integ rc
  if ! ark_helper files-plan "$PLAN" "$ARK_LOGS/items-files.tsv"; then
    ark_state files plan FAILED "could not build the download list (message above)"
    return 1
  fi
  while IFS=$'\t' read -r id tier subdir fname url bytes check sum <&3; do
    [ -n "$id" ] || continue
    ark_done "$id" && continue
    ark_ready || return 2
    [ "$bytes" = "-" ] && bytes=
    [ "$sum" = "-" ] && sum=
    dir="$ARK_ROOT/$subdir"
    out="$dir/$fname"
    if ! mkdir -p "$dir"; then
      ark_state files "$id" FAILED "cannot create $dir"
      continue
    fi
    have=$(ark_size "$out")
    written=$(ark_alloc_bytes "$out")
    need=0
    if [ -n "$bytes" ] && [ "$bytes" -gt "$written" ]; then need=$(( bytes - written )); fi
    if ! ark_room_for "$need"; then
      ark_state files "$id" SKIPPED-SPACE "needs $(ark_gb "$need") GB more; $(ark_gb "$(ark_free_bytes)") GB free; keeping $ARK_MIN_FREE_GB GB free"
      continue
    fi
    prev=$(ark_last_state "$id")
    complete=0
    if [ -n "$bytes" ] && [ "$have" = "$bytes" ] && [ ! -e "$out.aria2" ] && [ "$prev" != VERIFY-FAILED ]; then complete=1; fi
    if [ -z "$bytes" ] && [ "$have" -gt 0 ] && [ "$prev" = DOWNLOADED ]; then complete=1; fi
    if [ "$complete" = 0 ]; then
      ark_state files "$id" DOWNLOADING "$url${bytes:+ ($(ark_gb "$bytes") GB)}"
      ark_reserve "$need" "$out"
      meta=
      if [ "$check" = kiwix ] && ark_has aria2c; then
        meta="$dir/$fname.meta4"
        curl -q -fsSL --retry 5 -A "$ARK_USER_AGENT" -o "$meta" "$url.meta4" 2>> "$DLOG" || meta=
      fi
      integ=false
      [ "$prev" = VERIFY-FAILED ] && integ=true
      ark_fetch "$url" "$dir" "$fname" "$meta" "$integ" >> "$DLOG" 2>&1
      rc=$?
      if [ "$rc" != 0 ]; then
        ark_reserve 0
        # Only when the server says it cannot resume (curl exit 33, aria2c exit 8) is the partial
        # file moved aside so the next pass starts it fresh. Network outages simply resume.
        if [ "$rc" = 33 ] || { [ "$rc" = 8 ] && ark_has aria2c; }; then
          ark_move_aside "$out" no-resume
          ark_move_aside "$out.aria2" no-resume
          ark_state files "$id" FAILED "the server cannot resume this file; moved the partial copy aside, next pass starts over"
        else
          ark_state files "$id" FAILED "download stopped at $(ark_size "$out") bytes (exit $rc); it resumes next pass (details in files-download.log)"
        fi
        continue
      fi
      ark_reserve 0
      have=$(ark_size "$out")
      if [ -n "$bytes" ] && [ "$have" != "$bytes" ]; then
        ark_state files "$id" FAILED "have $have of $bytes bytes after the download; it resumes next pass"
        continue
      fi
      ark_state files "$id" DOWNLOADED "$have bytes"
    fi
    verify_one "$id" "$dir" "$fname" "$url" "$check" "$sum"
  done 3< "$PLAN"
  return 0
}

ark_run_passes files run_pass
ark_lane_end
