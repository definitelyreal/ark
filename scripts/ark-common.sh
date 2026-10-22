# shellcheck shell=bash
# ai-suggestion:unverified | date:2026-10-21
#
# Shared settings and helpers for the Ark download scripts. The lane scripts source this file;
# it is not run on its own. Works with the bash 3.2 that ships with macOS and with current Linux.
#
# Every location is a variable. Set any of them in your shell (or on the command line) before
# starting a lane, for example:
#   ARK_ROOT=/mnt/ark ARK_TIERS="core optional" bash scripts/ark-files.sh
#
# Rules these scripts follow: they only add files under ARK_ROOT, resume interrupted downloads,
# keep a few connections per server, and never delete anything. A file that fails its check is
# renamed with a ".bad-<time>" suffix so you can inspect it.

# --- Settings -----------------------------------------------------------------------------
ARK_ROOT=${ARK_ROOT:-/Volumes/ARK}                   # archive root on your storage; must already exist
ARK_LOGS=${ARK_LOGS:-$ARK_ROOT/catalog/downloads}    # state log, per-lane logs, pinned download lists
ARK_SCRIPTS=${ARK_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
ARK_QUEUES=${ARK_QUEUES:-$ARK_SCRIPTS/queues}        # the lists of what to download
ARK_TIERS=${ARK_TIERS:-core}                         # any of: core optional giant
ARK_ONLY=${ARK_ONLY:-}                               # optional words; only items whose name contains one are processed
ARK_MIN_FREE_GB=${ARK_MIN_FREE_GB:-20}               # never let a download take free space below this
ARK_CONNECTIONS=${ARK_CONNECTIONS:-4}                # total connections for one file (spread over mirrors)
ARK_PER_SERVER=${ARK_PER_SERVER:-2}                  # connections to any single server
ARK_MAX_SPEED=${ARK_MAX_SPEED:-}                     # optional cap such as 5M (bytes per second); empty = none
ARK_PASSES=${ARK_PASSES:-3}                          # passes over the list before a lane stops
ARK_RETRY_WAIT=${ARK_RETRY_WAIT:-300}                # seconds between passes
ARK_USER_AGENT=${ARK_USER_AGENT:-ark-offline-kit/1.0}

# ARK_MOUNT: a mount point that must be mounted before anything is written. On macOS it defaults
# to the volume holding ARK_ROOT (for /Volumes/ARK/x it is /Volumes/ARK), so an unplugged drive is
# never mistaken for an empty folder. Set ARK_MOUNT= (empty) to turn the check off.
if [ -z "${ARK_MOUNT+x}" ]; then
  case $ARK_ROOT in
    /Volumes/?*) ARK_MOUNT=/Volumes/$(printf '%s' "${ARK_ROOT#/Volumes/}" | cut -d/ -f1) ;;
    *) ARK_MOUNT= ;;
  esac
fi

export ARK_ROOT ARK_LOGS ARK_SCRIPTS ARK_QUEUES ARK_TIERS ARK_ONLY ARK_MIN_FREE_GB ARK_USER_AGENT ARK_MOUNT

ARK_NOT_READY="The archive at ARK_ROOT=$ARK_ROOT is not available${ARK_MOUNT:+ (checked that $ARK_MOUNT is mounted)}. Connect and mount the drive, create the folder, or set ARK_ROOT to the right place."

# --- Small utilities ----------------------------------------------------------------------
ark_now() { date '+%Y-%m-%dT%H:%M:%S%z'; }
ark_log() { printf '[%s] %s\n' "$(ark_now)" "$*"; }
ark_die() { printf 'ark: %s\n' "$*" >&2; exit 1; }
ark_has() { command -v "$1" >/dev/null 2>&1; }
ark_require() {
  local t
  for t in "$@"; do
    ark_has "$t" || ark_die "'$t' is required but was not found in PATH. Install it, then run this again."
  done
}
ark_helper() { python3 -I "$ARK_SCRIPTS/ark-helper.py" "$@"; }
ark_gb() { awk -v b="${1:-0}" 'BEGIN { printf "%.2f", b / 1e9 }'; }

# ark_ready: true when ARK_ROOT exists and, if ARK_MOUNT is set, that path is a mount point.
ark_ready() {
  [ -d "$ARK_ROOT" ] || return 1
  if [ -n "$ARK_MOUNT" ]; then
    python3 -I -c 'import os, sys; sys.exit(0 if os.path.ismount(sys.argv[1]) else 1)' "$ARK_MOUNT" || return 1
  fi
  return 0
}

ark_free_bytes() { df -Pk "$ARK_ROOT" 2>/dev/null | awk 'NR == 2 { printf "%.0f", $4 * 1024 }'; }

# ark_room_for <bytes>: true if downloading that many more bytes keeps ARK_MIN_FREE_GB free.
ark_room_for() {
  local need=${1:-0} free
  free=$(ark_free_bytes)
  [ -n "$free" ] || return 1
  [ $(( free - need )) -gt $(( ARK_MIN_FREE_GB * 1000000000 )) ]
}

ark_size() {
  [ -f "$1" ] || { echo 0; return; }
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || wc -c < "$1" | tr -d ' '
}
ark_dir_bytes() {
  [ -d "$1" ] || { echo 0; return; }
  du -sk "$1" 2>/dev/null | awk '{ printf "%.0f", $1 * 1024 }'
}

ark_sha256() {
  if ark_has sha256sum; then sha256sum "$1" | awk '{ print $1 }'
  else shasum -a 256 "$1" | awk '{ print $1 }'; fi
}
ark_md5() {
  if ark_has md5sum; then md5sum "$1" | awk '{ print $1 }'
  elif ark_has md5; then md5 -q "$1"
  else openssl md5 -r "$1" | awk '{ print $1 }'; fi
}

# ark_move_aside <path> <reason>: rename instead of deleting, e.g. file.zim.bad-20261021-101500
ark_move_aside() {
  local p=$1 why=$2 dest
  [ -e "$p" ] || return 0
  dest="$p.$why-$(date +%Y%m%d-%H%M%S)"
  mv "$p" "$dest" && ark_log "moved aside: $p -> $dest"
}

# ark_write_sum <file> <sha256|md5> <hex>: keep a checksum file beside the download for later
# offline re-checks ("shasum -a 256 -c file.sha256" or "md5sum -c file.md5").
ark_write_sum() {
  local f=$1 algo=$2 hex=$3 side line
  side="$f.$algo"
  line="$hex  $(basename "$f")"
  if [ -f "$side" ] && [ "$(cat "$side")" != "$line" ]; then ark_move_aside "$side" old; fi
  [ -f "$side" ] || printf '%s\n' "$line" > "$side"
}

# --- Item selection -----------------------------------------------------------------------
ark_tier_on() { case " $ARK_TIERS " in *" $1 "*) return 0 ;; esac; return 1; }

# --- State log ----------------------------------------------------------------------------
# One append-only file: time, lane, item, state, detail. ark-status.sh reads it.
# States: QUEUED (implied), DOWNLOADING, DOWNLOADED, VERIFIED, RECORDED (hash recorded, no
# publisher checksum exists), VERIFY-FAILED, FAILED, SKIPPED-SPACE, SKIPPED, WAITING.
ark_state() {
  local lane=$1 id=$2 st=$3
  shift 3
  printf '%s\t%s\t%s\t%s\t%s\n' "$(ark_now)" "$lane" "$id" "$st" "$*" >> "$ARK_LOGS/state.tsv"
  ark_log "$lane $id $st $*"
}
ark_last_state() {
  [ -f "$ARK_LOGS/state.tsv" ] || return 0
  awk -F'\t' -v id="$1" '$3 == id { s = $4 } END { print s }' "$ARK_LOGS/state.tsv"
}
ark_count_state() {
  [ -f "$ARK_LOGS/state.tsv" ] || { echo 0; return; }
  awk -F'\t' -v id="$1" -v st="$2" '$3 == id && $4 == st { n++ } END { print n + 0 }' "$ARK_LOGS/state.tsv"
}
ark_done() {
  case $(ark_last_state "$1") in VERIFIED|RECORDED) return 0 ;; esac
  return 1
}

# ark_items_left <lane>: items in this lane's plan that are not finished or skipped for space.
ark_items_left() {
  local f n=0
  for f in "$ARK_LOGS"/items-"$1"*.tsv; do
    [ -f "$f" ] || continue
    n=$(( n + $(awk -F'\t' 'FILENAME == ARGV[1] { if ($3 != "lane") s[$3] = $4; next }
      { st = s[$1]; if (st != "VERIFIED" && st != "RECORDED" && st != "SKIPPED-SPACE" && st != "SKIPPED") c++ }
      END { print c + 0 }' "$ARK_LOGS/state.tsv" "$f") ))
  done
  echo "$n"
}

# --- Lane lifecycle -----------------------------------------------------------------------
ark_lane_start() {
  ARK_LANE=$1
  mkdir -p "$ARK_LOGS" || ark_die "Cannot create the log folder $ARK_LOGS. Check that the drive is writable."
  local pidf="$ARK_LOGS/lane-$ARK_LANE.pid" old
  if [ -f "$pidf" ]; then
    old=$(cat "$pidf" 2>/dev/null)
    if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
      ark_die "Lane '$ARK_LANE' already looks busy (pid $old in $pidf). Check with scripts/ark-status.sh. If that process is not an Ark lane, rename $pidf and start again."
    fi
  fi
  echo $$ > "$pidf"
  touch "$ARK_LOGS/state.tsv"
  ark_state "$ARK_LANE" lane START "pid $$; tiers: $ARK_TIERS${ARK_ONLY:+; only: $ARK_ONLY}; root: $ARK_ROOT"
}
ark_lane_end() { ark_state "$ARK_LANE" lane END "pid $$; $(ark_items_left "$ARK_LANE") item(s) not finished"; }

# ark_run_passes <lane> <function>: run the function up to ARK_PASSES times. The function returns
# 2 when the archive drive disappears; the lane then waits 10 minutes and tries again.
ark_run_passes() {
  local lane=$1 fn=$2 pass=1 rc left
  while [ "$pass" -le "$ARK_PASSES" ]; do
    "$fn"; rc=$?
    if [ "$rc" = 2 ]; then
      ark_state "$lane" lane WAITING "archive not available; checking again in 10 minutes"
      sleep 600; pass=$(( pass + 1 )); continue
    fi
    left=$(ark_items_left "$lane")
    [ "$left" = 0 ] && break
    if [ "$pass" -lt "$ARK_PASSES" ]; then
      ark_state "$lane" lane RETRY "pass $pass: $left item(s) not finished; next pass in $ARK_RETRY_WAIT seconds"
      sleep "$ARK_RETRY_WAIT"
    fi
    pass=$(( pass + 1 ))
  done
}

# --- Downloads ----------------------------------------------------------------------------
# ark_fetch <url> <dir> <filename> [metalink-file] [re-check-pieces true|false]
# Resumable. Uses aria2c when installed (a metalink spreads one connection per mirror), else curl.
ark_fetch() {
  local url=$1 dir=$2 name=$3 meta=${4:-} integ=${5:-false}
  if ark_has aria2c; then
    set -- --dir="$dir" --continue=true --check-integrity="$integ" --file-allocation=none \
      --auto-file-renaming=false --allow-overwrite=false --max-tries=30 --retry-wait=30 \
      --timeout=60 --lowest-speed-limit=10K --summary-interval=300 --console-log-level=warn \
      --enable-color=false --user-agent="$ARK_USER_AGENT" --min-split-size=32M
    [ -n "$ARK_MAX_SPEED" ] && set -- "$@" --max-overall-download-limit="$ARK_MAX_SPEED"
    if [ -n "$meta" ]; then
      aria2c "$@" --metalink-file="$meta" --split="$ARK_CONNECTIONS" --max-connection-per-server=1 \
        --uri-selector=adaptive --metalink-enable-unique-protocol=true
    else
      aria2c "$@" --split="$ARK_PER_SERVER" --max-connection-per-server="$ARK_PER_SERVER" --out="$name" "$url"
    fi
  else
    set -- -fL --retry 10 --retry-delay 30 --connect-timeout 60 -C - -A "$ARK_USER_AGENT" -o "$dir/$name"
    [ -n "$ARK_MAX_SPEED" ] && set -- "$@" --limit-rate "$ARK_MAX_SPEED"
    curl "$@" "$url"
  fi
}

# Git with everything that could run repository code turned off. Archived repositories are
# reading material; nothing in them is executed.
ark_git() {
  GIT_TERMINAL_PROMPT=0 GIT_LFS_SKIP_SMUDGE=1 git -c core.hooksPath=/dev/null -c core.fsmonitor=false \
    -c core.symlinks=false -c protocol.file.allow=never -c submodule.recurse=false \
    -c advice.detachedHead=false "$@"
}
