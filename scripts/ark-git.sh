#!/usr/bin/env bash
# ai-suggestion:unverified | date:2026-10-21
#
# Ark "git" lane: ClamAV malware signatures (core tier, when freshclam is installed), the git
# repositories in queues/git.tsv (fonts, icons, rule sets), and, only when you ask for it with
# ARK_GITHUB_TOP=<count>, an archive of the most-starred GitHub repositories.
#
# Every clone is shallow (newest commit only), with hooks, submodules, symlinks and Git LFS
# downloads turned off. Archived repositories are reading material; nothing in them is run.
# Git computes the hash of every object it receives, so a finished clone matches the commit
# recorded in the state log (and, for the GitHub archive, in tools/github/manifest.csv).
#
# Usage:   ARK_ROOT=/Volumes/ARK bash scripts/ark-git.sh
#          ARK_GITHUB_TOP=1000 ARK_ONLY=github bash scripts/ark-git.sh   (the GitHub archive alone)
# Options: ARK_GIT_RESERVE_GB (free space required per repository, default 5),
#          ARK_GITHUB_FLAG_AFTER=YYYY-MM-DD (mark repositories pushed after that date as RECENT
#          in the manifest, for extra caution when reading them later).
set -u
# shellcheck source=ark-common.sh
. "$(cd "$(dirname "$0")" && pwd)/ark-common.sh"

ark_require git python3
ark_ready || ark_die "$ARK_NOT_READY"
ark_lane_start git
ARK_GIT_RESERVE_GB=${ARK_GIT_RESERVE_GB:-5}
ARK_GITHUB_TOP=${ARK_GITHUB_TOP:-0}
ARK_GITHUB_FLAG_AFTER=${ARK_GITHUB_FLAG_AFTER:-}
export ARK_GITHUB_TOP
GLOG="$ARK_LOGS/git-clone.log"

# clone_complete <dir>: HEAD resolves, the index was written, and no tracked file is missing.
# (Missing files, not changed ones, mark an interrupted checkout: on a case-insensitive disk a
# repository with names differing only in case shows changed files even when complete.)
clone_complete() {
  local missing
  ark_git -C "$1" rev-parse -q --verify HEAD >/dev/null 2>&1 || return 1
  [ -f "$1/.git/index" ] || return 1
  missing=$(ark_git -C "$1" ls-files --deleted 2>/dev/null) || return 1
  [ -z "$missing" ]
}

# clone_one <url> <dir>: 0 when <dir> holds a complete clone.
# A clone whose commit arrived but whose checkout was interrupted is repaired in place from its own
# data. A clone without a usable commit is moved aside and cloned again, at most twice per folder,
# so a repository that can never be written to this disk does not pile up copies.
clone_one() {
  local url=$1 dir=$2 tries
  if [ -d "$dir/.git" ] && ark_git -C "$dir" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    clone_complete "$dir" && return 0
    ark_git -C "$dir" reset -q --hard HEAD < /dev/null
    clone_complete "$dir"
    return
  fi
  if [ -e "$dir" ]; then
    tries=$(ls -d "$dir".partial-* 2>/dev/null | wc -l | tr -d ' ')
    if [ "$tries" -ge 2 ]; then
      echo "not retrying $dir: two earlier attempts failed (see $dir.partial-*)" >&2
      return 1
    fi
    ark_move_aside "$dir" partial
  fi
  mkdir -p "$(dirname "$dir")" || return 1
  ark_git clone -c core.symlinks=false -c core.hooksPath=/dev/null -c credential.helper= --depth 1 \
    --no-recurse-submodules --quiet "$url" "$dir" < /dev/null || return 1
  clone_complete "$dir"
}

do_clamav() {
  local db="$ARK_ROOT/software/clamav-db" conf="$ARK_LOGS/freshclam.conf" f res= rc
  ark_done clamav-db && return 0
  if ! ark_has freshclam || ! ark_has sigtool; then
    ark_state git clamav-db SKIPPED "ClamAV is not installed (https://www.clamav.net/downloads)"
    return 0
  fi
  mkdir -p "$db" || { ark_state git clamav-db FAILED "cannot create $db"; return 0; }
  printf 'DatabaseDirectory %s\nDatabaseMirror database.clamav.net\nUpdateLogFile %s\nLogTime yes\nForeground yes\n' \
    "$db" "$ARK_LOGS/freshclam.log" > "$conf"
  ark_state git clamav-db DOWNLOADING "freshclam into $db"
  freshclam --config-file="$conf" >> "$ARK_LOGS/freshclam.out" 2>&1 < /dev/null
  rc=$?
  # freshclam exits 0 after an update and 1 when the database is already up to date.
  if [ "$rc" = 0 ] || [ "$rc" = 1 ]; then
    for f in "$db"/*.cvd "$db"/*.cld; do
      [ -e "$f" ] || continue
      if sigtool --info="$f" 2>&1 | grep -q 'Verification OK'; then res="$res $(basename "$f"):OK"
      else res="$res $(basename "$f"):BAD"; fi
    done
    case $res in
      ""|*BAD*)
        # Move bad database files aside so the next run downloads them again.
        for f in "$db"/*.cvd "$db"/*.cld; do
          [ -e "$f" ] || continue
          case $res in *" $(basename "$f"):BAD"*) ark_move_aside "$f" bad ;; esac
        done
        ark_state git clamav-db VERIFY-FAILED "signature check:${res:- no database files found}; bad files moved aside" ;;
      *) ark_state git clamav-db VERIFIED "ClamAV digital signatures:$res" ;;
    esac
  else
    ark_state git clamav-db FAILED "freshclam stopped (see freshclam.out); ClamAV's mirror limits repeat downloads, so wait an hour before retrying"
  fi
}

do_repo() { # id url subdir
  local id=$1 url=$2 dir="$ARK_ROOT/$3" head
  ark_done "$id" && return 0
  if ! ark_room_for $(( ARK_GIT_RESERVE_GB * 1000000000 )); then
    ark_state git "$id" SKIPPED-SPACE "keeps $ARK_GIT_RESERVE_GB GB per repository on top of $ARK_MIN_FREE_GB GB free"
    return 0
  fi
  ark_state git "$id" DOWNLOADING "$url"
  ark_reserve $(( ARK_GIT_RESERVE_GB * 1000000000 )) "$dir"
  if clone_one "$url" "$dir" >> "$GLOG" 2>&1; then
    ark_reserve 0
    if ! ark_git -C "$dir" fsck --connectivity-only --no-dangling >> "$GLOG" 2>&1; then
      ark_move_aside "$dir" bad
      ark_state git "$id" VERIFY-FAILED "git fsck reported a problem (see git-clone.log); moved the clone aside, next pass clones again"
      return 0
    fi
    head=$(ark_git -C "$dir" rev-parse HEAD)
    ark_state git "$id" VERIFIED "HEAD $head; $(ark_gb "$(ark_dir_bytes "$dir")") GB"
  else
    ark_reserve 0
    ark_state git "$id" FAILED "git clone did not complete (see git-clone.log); next pass tries again"
  fi
}

do_github() {
  local base="$ARK_ROOT/tools/github" list="$ARK_LOGS/github-top.tsv" man rank repo stars pushed branch
  local n=0 cloned=0 failed=0 dir head kb flag ok attempt
  ark_done github-top && return 0
  mkdir -p "$base/repos" || { ark_state git github-top FAILED "cannot create $base"; return 0; }
  man="$base/manifest.csv"
  if ! ark_helper github-top "$ARK_GITHUB_TOP" "$list"; then
    ark_state git github-top FAILED "could not list repositories from the GitHub search API; next pass tries again"
    return 0
  fi
  [ -s "$man" ] || echo "rank,repo,stars,pushed_at,default_branch,head,disk_kb,flag,status,time" > "$man"
  ark_state git github-top DOWNLOADING "$(wc -l < "$list" | tr -d ' ') repositories, newest commit only"
  while IFS=$'\t' read -r rank repo stars pushed branch <&3; do
    [ -n "$repo" ] || continue
    n=$(( n + 1 ))
    if grep -q "^$rank,$repo,.*,cloned," "$man"; then cloned=$(( cloned + 1 )); continue; fi
    ark_ready || return 2
    if ! ark_room_for $(( ARK_GIT_RESERVE_GB * 1000000000 )); then
      ark_state git github-top SKIPPED-SPACE "stopped at rank $rank ($repo) to keep free space; $cloned cloned"
      return 0
    fi
    dir="$base/repos/$repo"
    flag=ok
    if [ -n "$ARK_GITHUB_FLAG_AFTER" ] && [[ "$pushed" > "$ARK_GITHUB_FLAG_AFTER" ]]; then flag=RECENT; fi
    ok=0
    for attempt in 1 2; do
      if clone_one "https://github.com/$repo.git" "$dir" >> "$GLOG" 2>&1; then ok=1; break; fi
      sleep 30
    done
    if [ "$ok" = 1 ]; then
      head=$(ark_git -C "$dir" rev-parse HEAD 2>/dev/null || echo unknown)
      kb=$(du -sk "$dir" 2>/dev/null | cut -f1)
      echo "$rank,$repo,$stars,$pushed,$branch,$head,$kb,$flag,cloned,$(ark_now)" >> "$man"
      cloned=$(( cloned + 1 ))
    else
      echo "$rank,$repo,$stars,$pushed,$branch,,0,$flag,FAILED,$(ark_now)" >> "$man"
      failed=$(( failed + 1 ))
    fi
    if [ $(( n % 50 )) = 0 ]; then
      ark_state git github-top DOWNLOADING "$n processed, $cloned cloned, $failed failed; $(ark_gb "$(ark_free_bytes)") GB free"
    fi
    sleep 1
  done 3< "$list"
  # Finished only when every repository in the pinned list has a latest manifest row saying cloned.
  # (Status is the second-to-last field, so a comma in a branch name cannot shift it.)
  set -- $(awk -F'\t' 'FILENAME == ARGV[1] { want[$2] = 1; next }
    FNR > 1 { n = split($0, a, ","); st[a[2]] = a[n - 1] }
    END { c = 0; f = 0; for (r in want) { if (st[r] == "cloned") c++; else f++ } print c, f }' "$list" "$man")
  cloned=${1:-0}; failed=${2:-0}
  if [ "$failed" = 0 ]; then
    ark_state git github-top VERIFIED "$cloned cloned; HEAD commits in $man"
  else
    ark_state git github-top FAILED "$cloned cloned, $failed failed; the next pass retries the failed ones"
  fi
}

run_pass() {
  local plan="$ARK_LOGS/plan-git.tsv" id tier kind url subdir rc
  ark_helper git-plan "$plan" "$ARK_LOGS/items-git.tsv" || return 1
  while IFS=$'\t' read -r id tier kind url subdir <&3; do
    [ -n "$id" ] || continue
    ark_ready || return 2
    case $kind in
      clamav) do_clamav ;;
      git) do_repo "$id" "$url" "$subdir" ;;
      github) do_github; rc=$?; [ "$rc" = 2 ] && return 2 ;;
    esac
  done 3< "$plan"
  return 0
}

ark_run_passes git run_pass
ark_lane_end
