#!/usr/bin/env python3
# ai-suggestion:unverified | date:2026-10-21
"""Planning, verification and status helper for the Ark download scripts.

The ark-*.sh lane scripts call this; you normally run only scripts/ark-status.sh yourself.
Standard library only (Python 3.8 or newer). Settings come from the environment variables that
ark-common.sh exports: ARK_ROOT, ARK_LOGS, ARK_QUEUES, ARK_TIERS, ARK_ONLY, ARK_USER_AGENT.

Network use is limited to public metadata: Kiwix directory listings and checksum files, HEAD
requests for file sizes, the Hugging Face public API, and the GitHub public search API. No
account or token is read or sent. This helper never deletes files.

Subcommands:
  files-plan PLAN ITEMS          Kiwix + direct files: resolve and pin, write the work list
  ollama-plan PLAN ITEMS         Ollama models to pull
  ollama-verify STORE MODEL      check every layer of a pulled model (size and SHA-256)
  hf-plan PLAN ITEMS             Hugging Face repos: pin a commit, total the selected files
  hf-verify REPO KIND REV DIR INCLUDE   re-hash downloaded files against the Hub's hashes
  git-plan PLAN ITEMS            git repositories, ClamAV signatures, optional GitHub archive
  github-top COUNT OUT           list the most-starred GitHub repositories (pinned once)
  status [-a]                    progress and verification state of every planned item
"""
import csv
import fnmatch
import hashlib
import json
import os
import re
import shutil
import sys
import time
import urllib.error
import urllib.request

UA = os.environ.get("ARK_USER_AGENT", "ark-offline-kit/1.0")
KIWIX = "https://download.kiwix.org/zim"
HF = "https://huggingface.co"
DONE = ("VERIFIED", "RECORDED")


def env(name, default=""):
    return os.environ.get(name, default)


def now():
    return time.strftime("%Y-%m-%dT%H:%M:%S%z")


def fail(msg):
    sys.stderr.write("ark-helper: " + msg + "\n")
    sys.exit(1)


# --- HTTP ----------------------------------------------------------------------------------
def request(url, method="GET", timeout=60, tries=4, headers=None):
    h = {"User-Agent": UA}
    h.update(headers or {})
    last = None
    for i in range(tries):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, method=method, headers=h), timeout=timeout)
        except urllib.error.HTTPError as e:
            if e.code in (400, 401, 403, 404, 410, 451):
                raise
            last = e
        except Exception as e:  # timeouts, resets, DNS hiccups
            last = e
        time.sleep(5 * (i + 1))
    raise last


def get_text(url):
    with request(url) as r:
        return r.read().decode("utf-8", "replace")


def get_json(url, headers=None):
    with request(url, headers=headers) as r:
        return json.load(r)


def remote_size(url):
    try:
        with request(url, method="HEAD", tries=2) as r:
            n = r.headers.get("Content-Length", "")
            return int(n) if n.isdigit() else None
    except Exception:
        return None


# --- Files and queues ----------------------------------------------------------------------
def read_tsv(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if line and not line.startswith("#"):
                rows.append(["" if c == "-" else c for c in line.split("\t")])
    return rows


def read_queue(name, ncols):
    path = os.path.join(env("ARK_QUEUES"), name)
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, encoding="utf-8") as f:
        for ln, line in enumerate(f, 1):
            line = line.rstrip("\r\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            cols = [c.strip() for c in line.split("\t")]
            if len(cols) < ncols:
                fail(f"{path} line {ln}: expected {ncols} tab-separated fields, found {len(cols)}. "
                     "Separate fields with one tab and use - for an empty field.")
            rows.append(["" if c == "-" else c for c in cols[:ncols]])
    return rows


def write_tsv(path, rows):
    tmp = path + ".new"
    with open(tmp, "w", encoding="utf-8") as f:
        for r in rows:
            f.write("\t".join("-" if c is None or str(c) == "" else str(c).replace("\t", " ") for c in r) + "\n")
    os.replace(tmp, path)


def append_tsv(path, rows):
    with open(path, "a", encoding="utf-8") as f:
        for r in rows:
            f.write("\t".join("-" if c is None or str(c) == "" else str(c) for c in r) + "\n")


def safe_subdir(subdir, where):
    p = subdir.strip("/")
    if not p or os.path.isabs(subdir) or ".." in p.split("/"):
        fail(f"{where}: folder '{subdir}' must be a relative path inside ARK_ROOT without '..'")
    return p


def selected(tier, name):
    if tier not in env("ARK_TIERS", "core").split():
        return False
    words = env("ARK_ONLY").split()
    return not words or any(w in name for w in words)


def last_states():
    """Last recorded state per item from state.tsv: {item: (time, state, detail)}."""
    out = {}
    path = os.path.join(env("ARK_LOGS"), "state.tsv")
    if os.path.exists(path):
        with open(path, encoding="utf-8", errors="replace") as f:
            for row in csv.reader(f, delimiter="\t", quoting=csv.QUOTE_NONE):
                if len(row) >= 4 and row[2] != "lane":
                    out[row[2]] = (row[0], row[3], row[4] if len(row) > 4 else "")
    return out


def record_state(lane, ident, state, detail):
    """Append one line to the shared state log, in the same format the shell lanes write."""
    path = os.path.join(env("ARK_LOGS"), "state.tsv")
    with open(path, "a", encoding="utf-8") as f:
        f.write("\t".join([now(), lane, ident, state, detail.replace("\t", " ").replace("\n", " ")]) + "\n")


def move_aside(path, why):
    """Rename instead of deleting, matching ark_move_aside in ark-common.sh."""
    if os.path.lexists(path):
        dest = f"{path}.{why}-{time.strftime('%Y%m%d-%H%M%S')}"
        os.rename(path, dest)
        return dest
    return None


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(8 << 20), b""):
            h.update(block)
    return h.hexdigest()


def git_blob_sha1(path):
    h = hashlib.sha1()
    h.update(b"blob %d\0" % os.path.getsize(path))
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(8 << 20), b""):
            h.update(block)
    return h.hexdigest()


# --- Kiwix and direct files ----------------------------------------------------------------
def resolve_kiwix(category, prefix, listings):
    base = f"{KIWIX}/{category}/"
    if base not in listings:
        listings[base] = get_text(base)
    pat = re.compile(r'href="(' + re.escape(prefix) + r'_(\d{4}-\d{2})\.zim)"')
    cands = sorted(set(pat.findall(listings[base])), key=lambda c: c[1])
    if not cands:
        return None
    fname = cands[-1][0]
    url = base + fname
    sha = (get_text(url + ".sha256").split() or [""])[0].lower()
    if not re.fullmatch(r"[0-9a-f]{64}", sha):
        raise ValueError(f"the published checksum for {fname} is not a SHA-256 value")
    return [prefix, category, fname, url, remote_size(url) or "", sha, now()]


def cmd_files_plan(plan_path, items_path):
    root, logs = env("ARK_ROOT"), env("ARK_LOGS")
    states = last_states()
    pinned_path = os.path.join(logs, "kiwix-resolved.tsv")
    pinned = {r[0]: r for r in read_tsv(pinned_path) if len(r) >= 6}
    listings, new, plan, items = {}, [], [], []
    for tier, category, prefix, subdir, _note in read_queue("kiwix.tsv", 5):
        if not selected(tier, prefix):
            continue
        subdir = safe_subdir(subdir, "kiwix.tsv")
        r = pinned.get(prefix)
        if not r:
            problem = ""
            try:
                r = resolve_kiwix(category, prefix, listings)
                if r is None:
                    problem = f"no {prefix}_YYYY-MM.zim in {KIWIX}/{category}/ (renamed or retired?)"
            except Exception as e:
                problem = f"could not look it up on Kiwix ({e}); will retry next pass"
            if problem:
                # Keep the item visible and unfinished, so status shows it and the lane tries again.
                ident = "kiwix:" + prefix
                items.append([ident, "files", tier, os.path.join(root, subdir), "", "SHA-256 published by Kiwix",
                              f"{KIWIX}/{category}/"])
                record_state("files", ident, "FAILED", problem)
                sys.stderr.write(f"ark-helper: {prefix}: {problem}\n")
                continue
            pinned[prefix] = r
            new.append(r)
        fname, url, nbytes, sha = r[2], r[3], r[4], r[5]
        ident = "kiwix:" + fname
        plan.append([ident, tier, subdir, fname, url, nbytes, "kiwix", sha])
        items.append([ident, "files", tier, os.path.join(root, subdir, fname), nbytes,
                      "SHA-256 published by Kiwix", url])
    if new:
        append_tsv(pinned_path, new)
    checks = {"sha256": "SHA-256 given in the queue", "md5": "MD5 given in the queue",
              "sha256-url": "SHA-256 file published beside the download",
              "md5-url": "MD5 file published beside the download",
              "record": "no publisher checksum; SHA-256 recorded locally"}
    for tier, ident, subdir, fname, url, check, checksum, _note in read_queue("files.tsv", 8):
        if not selected(tier, ident):
            continue
        if check not in checks:
            fail(f"files.tsv item {ident}: unknown check '{check}' (use one of {', '.join(checks)})")
        if check in ("sha256", "md5") and not checksum:
            fail(f"files.tsv item {ident}: check '{check}' needs the checksum value in the checksum column")
        subdir = safe_subdir(subdir, "files.tsv")
        if "/" in fname or fname in (".", ".."):
            fail(f"files.tsv item {ident}: filename must not contain '/'")
        size = "" if states.get(ident, ("", ""))[1] in DONE else (remote_size(url) or "")
        plan.append([ident, tier, subdir, fname, url, size, check, checksum])
        items.append([ident, "files", tier, os.path.join(root, subdir, fname), size, checks[check], url])
    write_tsv(plan_path, plan)
    write_tsv(items_path, items)
    print(f"files plan: {len(plan)} item(s)")


# --- Ollama --------------------------------------------------------------------------------
def cmd_ollama_plan(plan_path, items_path):
    store = env("ARK_OLLAMA_STORE") or os.path.join(env("ARK_ROOT"), "models", "ollama")
    plan, items = [], []
    for tier, model, approx, _note in read_queue("ollama.tsv", 4):
        ident = "ollama:" + model
        if not selected(tier, ident):
            continue
        if not re.fullmatch(r"[A-Za-z0-9._:/-]+", model):
            fail(f"ollama.tsv: '{model}' is not a valid model name")
        plan.append([ident, tier, model, approx if approx.isdigit() else ""])
        items.append([ident, "models", tier, store, approx if approx.isdigit() else "",
                      "Ollama checks each layer's SHA-256 on pull; re-hashed after", "registry.ollama.ai/" + model])
    write_tsv(plan_path, plan)
    write_tsv(items_path, items)
    print(f"ollama plan: {len(plan)} model(s)")


def ollama_manifest(store, model):
    name, tag = model, "latest"
    if ":" in model.rsplit("/", 1)[-1]:
        name, tag = model.rsplit(":", 1)
    parts = name.split("/")
    if len(parts) == 1:
        parts = ["registry.ollama.ai", "library"] + parts
    elif len(parts) == 2:
        parts = ["registry.ollama.ai"] + parts
    return os.path.join(store, "manifests", *parts, tag)


def cmd_ollama_verify(store, model):
    path = ollama_manifest(store, model)
    try:
        with open(path, encoding="utf-8") as f:
            m = json.load(f)
    except (OSError, ValueError) as e:
        print(f"FAIL cannot read manifest {path}: {e}")
        sys.exit(1)
    rehash = env("ARK_REHASH", "1") != "0"
    bad, total, layers = [], 0, m.get("layers", []) + [m["config"]]
    for layer in layers:
        digest = layer["digest"]
        blob = os.path.join(store, "blobs", digest.replace(":", "-"))
        total += layer["size"]
        if not os.path.isfile(blob) or os.path.getsize(blob) != layer["size"]:
            bad.append("size " + digest[:19])
        elif rehash and digest.startswith("sha256:") and sha256_file(blob) != digest[7:]:
            bad.append("sha256 " + digest[:19])
    if bad:
        # Bad layers go to a quarantine folder outside blobs/, where Ollama never looks (and never
        # prunes), so the next pull fetches them again. Other models sharing a layer are re-checked
        # the next time they are verified.
        moved, qdir = 0, os.path.join(store, "quarantine")
        for layer in layers:
            digest = layer["digest"]
            src = os.path.join(store, "blobs", digest.replace(":", "-"))
            if any(digest[:19] in b for b in bad) and os.path.lexists(src):
                os.makedirs(qdir, exist_ok=True)
                os.rename(src, os.path.join(qdir, f"{os.path.basename(src)}.bad-{time.strftime('%Y%m%d-%H%M%S')}"))
                moved += 1
        print("FAIL " + "; ".join(bad[:5]) + f"; moved {moved} bad layer file(s) to {qdir}, next pass fetches them again")
        sys.exit(1)
    how = "SHA-256 re-hashed" if rehash else "sizes checked"
    print(f"OK {len(layers)} blobs, {total} bytes, {how}")


# --- Hugging Face --------------------------------------------------------------------------
def hf_tree(kind, repo, rev):
    url = f"{HF}/api/{kind}s/{repo}/tree/{rev}?recursive=true"
    files = []
    while url:
        with request(url) as r:
            files += [e for e in json.load(r) if e.get("type") == "file"]
            link = r.headers.get("Link", "") or ""
        m = re.search(r'<([^>]+)>;\s*rel="next"', link)
        url = m.group(1) if m else None
    return files


def hf_filter(files, include):
    globs = [g for g in include.split(",") if g]
    if not globs:
        return files
    return [f for f in files if any(fnmatch.fnmatch(f["path"], g) for g in globs)]


def cmd_hf_plan(plan_path, items_path):
    root, logs = env("ARK_ROOT"), env("ARK_LOGS")
    states = last_states()
    pinned_path = os.path.join(logs, "hf-pinned.tsv")
    pinned = {r[0]: r for r in read_tsv(pinned_path) if len(r) >= 5}
    new, plan, items = [], [], []
    for tier, name, repo, kind, subdir, include, _note in read_queue("huggingface.tsv", 7):
        ident = "hf:" + name
        if not selected(tier, ident):
            continue
        if kind not in ("model", "dataset"):
            fail(f"huggingface.tsv item {name}: kind must be model or dataset")
        if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repo):
            fail(f"huggingface.tsv item {name}: '{repo}' is not an owner/name repository id")
        subdir = safe_subdir(subdir, "huggingface.tsv")
        dest = os.path.join(root, subdir)
        item = [ident, "models", tier, dest, "", "per-file SHA-256 (large files) or git blob hash (small files) from the Hub",
                f"{HF}/{repo}"]
        listing = os.path.join(logs, f"hf-files-{re.sub(r'[^A-Za-z0-9._-]', '_', name)}.tsv")
        p = pinned.get(name)
        if not p or p[1] != repo or p[5:6] != [include]:
            if states.get(ident, ("", ""))[1] in DONE and p:
                pass
            else:
                problem, state = "", "FAILED"
                try:
                    info = get_json(f"{HF}/api/{kind}s/{repo}")
                    if info.get("gated"):
                        problem, state = "gated: needs a Hugging Face account and accepted terms; download it yourself", "SKIPPED"
                    else:
                        rev = info["sha"]
                        files = hf_filter(hf_tree(kind, repo, rev), include)
                        if not files:
                            problem = f"no files match '{include}'; check the include patterns"
                except Exception as e:
                    problem = f"could not read it from Hugging Face ({e}); will retry next pass"
                if problem:
                    items.append(item)
                    record_state("models", ident, state, problem)
                    sys.stderr.write(f"ark-helper: {repo}: {problem}\n")
                    continue
                p = [name, repo, rev, sum(f.get("size", 0) for f in files), len(files), include, now()]
                pinned[name] = p
                new.append(p)
                write_tsv(listing, [[f["path"], f.get("size", 0)] for f in files])
        total = int(p[3]) if str(p[3]).isdigit() else 0
        # Bytes still needed: the pinned file list minus what is already on disk for this item.
        need = total
        if os.path.exists(listing):
            have = 0
            for path, size in (r[:2] for r in read_tsv(listing) if len(r) >= 2):
                try:
                    have += min(os.path.getsize(os.path.join(dest, path)), int(size))
                except (OSError, ValueError):
                    pass
            need = max(0, total - have)
        plan.append([ident, tier, repo, kind, subdir, include, p[2], total, need])
        item[4] = total
        items.append(item)
    if new:
        append_tsv(pinned_path, new)
    write_tsv(plan_path, plan)
    write_tsv(items_path, items)
    print(f"huggingface plan: {len(plan)} item(s)")


def cmd_hf_verify(repo, kind, rev, local, include):
    try:
        files = hf_filter(hf_tree(kind, repo, rev), include)
    except Exception as e:
        print(f"FAIL could not read the file list from Hugging Face: {e}")
        sys.exit(1)
    bad, wrong, total = [], [], 0
    for f in files:
        p = os.path.join(local, f["path"])
        if not os.path.isfile(p):
            bad.append("missing " + f["path"])
            continue
        size = os.path.getsize(p)
        if size != f.get("size"):
            bad.append(f"size {f['path']} {size} != {f.get('size')}")
            wrong.append(f["path"])
            continue
        lfs = f.get("lfs") or {}
        if lfs.get("oid"):
            if sha256_file(p) != lfs["oid"]:
                bad.append("sha256 " + f["path"])
                wrong.append(f["path"])
        elif git_blob_sha1(p) != f.get("oid"):
            bad.append("git-sha1 " + f["path"])
            wrong.append(f["path"])
        total += size
    if bad or not files:
        # Rename wrong files and the download record hf keeps for them, so the next pass
        # downloads them again instead of trusting the record.
        for path in wrong:
            move_aside(os.path.join(local, path), "bad")
            move_aside(os.path.join(local, ".cache", "huggingface", "download", path + ".metadata"), "bad")
        extra = f"; moved {len(wrong)} wrong file(s) aside" if wrong else ""
        print("FAIL " + ("; ".join(bad[:5]) if bad else "no files matched") + extra)
        sys.exit(1)
    print(f"OK {len(files)} files, {total} bytes at commit {rev[:12]}")


# --- Git, ClamAV, GitHub archive -----------------------------------------------------------
def cmd_git_plan(plan_path, items_path):
    root = env("ARK_ROOT")
    plan, items = [], []
    if selected("core", "clamav-db"):
        db = os.path.join(root, "software", "clamav-db")
        plan.append(["clamav-db", "core", "clamav", "database.clamav.net", "software/clamav-db"])
        items.append(["clamav-db", "git", "core", db, "", "ClamAV's own digital signature (sigtool)",
                      "https://www.clamav.net/"])
    for tier, name, url, subdir, _note in read_queue("git.tsv", 5):
        ident = "git:" + name
        if not selected(tier, ident):
            continue
        subdir = safe_subdir(subdir, "git.tsv")
        plan.append([ident, tier, "git", url, subdir])
        items.append([ident, "git", tier, os.path.join(root, subdir), "",
                      "git checks every object hash; HEAD commit recorded", url])
    top = env("ARK_GITHUB_TOP", "0")
    if top.isdigit() and int(top) > 0 and (not env("ARK_ONLY") or "github" in env("ARK_ONLY")):
        plan.append(["github-top", "giant", "github", top, "tools/github"])
        items.append(["github-top", "git", "giant", os.path.join(root, "tools", "github"), "",
                      "git checks every object hash; HEAD per repository in manifest.csv",
                      f"top {top} GitHub repositories by stars"])
    write_tsv(plan_path, plan)
    write_tsv(items_path, items)
    print(f"git plan: {len(plan)} item(s)")


def cmd_github_top(count, out):
    count = int(count)
    if os.path.exists(out) and os.path.getsize(out) > 0:
        print(f"using the pinned list {out} ({sum(1 for _ in open(out))} repositories)")
        return
    rows, page, per = [], 1, min(100, count)
    hdr = {"Accept": "application/vnd.github+json"}
    while len(rows) < count and page <= 10:
        url = (f"https://api.github.com/search/repositories?q=stars:%3E1000&sort=stars&order=desc"
               f"&per_page={per}&page={page}")
        for attempt in range(4):
            try:
                data = get_json(url, headers=hdr)
                break
            except urllib.error.HTTPError as e:
                if e.code in (403, 429) and attempt < 3:
                    time.sleep(65)  # unauthenticated search allows about 10 requests a minute
                    continue
                raise
        found = data.get("items", [])
        if not found:
            break
        for it in found:
            full = it.get("full_name", "")
            if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", full) and ".." not in full:
                rows.append([len(rows) + 1, full, it.get("stargazers_count", ""), it.get("pushed_at", ""),
                             it.get("default_branch", "")])
        page += 1
        time.sleep(7)
    write_tsv(out, rows[:count])
    print(f"listed {len(rows[:count])} repositories into {out}")


# --- Status --------------------------------------------------------------------------------
def human(b):
    return f"{b / 1e9:.2f} GB" if b >= 1e9 else f"{b / 1e6:.1f} MB"


def lane_line(logs, lane, states_rows):
    pidf = os.path.join(logs, f"lane-{lane}.pid")
    try:
        pid = int(open(pidf).read().strip())
        try:
            os.kill(pid, 0)
            return f"RUNNING (pid {pid})"
        except PermissionError:
            return f"RUNNING (pid {pid})"
        except ProcessLookupError:
            pass
    except (OSError, ValueError):
        pass
    last = [r for r in states_rows if len(r) >= 4 and r[1] == lane and r[2] == "lane"]
    if not last:
        return "not started"
    return f"not running (last: {last[-1][3]} at {last[-1][0]})"


def ollama_progress(logs, model):
    p = os.path.join(logs, "ollama-pull-" + re.sub(r"[^A-Za-z0-9._-]", "_", model) + ".jsonl")
    try:
        with open(p, "rb") as f:
            f.seek(max(0, os.path.getsize(p) - 4000))
            tail = f.read().decode("utf-8", "replace").strip().splitlines()
        j = json.loads(tail[-1])
        if j.get("total") and j.get("completed"):
            return f"{human(j['completed'])} of {human(j['total'])} in the current layer"
        return j.get("status", "") or j.get("error", "")
    except Exception:
        return ""


def bytes_on_disk(path):
    try:
        st = os.stat(path)
        return min(st.st_size, getattr(st, "st_blocks", 0) * 512 or st.st_size)
    except OSError:
        return 0


def tree_bytes(path):
    total = 0
    for dirpath, _dirs, names in os.walk(path):
        for n in names:
            try:
                total += os.lstat(os.path.join(dirpath, n)).st_size
            except OSError:
                pass
    return total


def cmd_status(flag):
    root, logs = env("ARK_ROOT"), env("ARK_LOGS")
    show_all = flag == "-a"
    print(f"Ark download status, {time.strftime('%Y-%m-%d %H:%M %z')}")
    if not os.path.isdir(logs):
        print(f"No download log at {logs}. Either the archive drive is not mounted, ARK_ROOT is wrong,")
        print("or no lane has been started yet. Start one with: bash scripts/ark-files.sh")
        return 1
    try:
        du = shutil.disk_usage(root)
        print(f"Archive: {root}   free {du.free / 1e9:.1f} GB of {du.total / 1e9:.1f} GB "
              f"(lanes keep {env('ARK_MIN_FREE_GB', '20')} GB free)")
    except OSError as e:
        print(f"Archive: {root}   (cannot read free space: {e})")
    rows = []
    sp = os.path.join(logs, "state.tsv")
    if os.path.exists(sp):
        with open(sp, encoding="utf-8", errors="replace") as f:
            rows = list(csv.reader(f, delimiter="\t", quoting=csv.QUOTE_NONE))
    last = {}
    for r in rows:
        if len(r) >= 4 and r[2] != "lane":
            last[r[2]] = (r[0], r[3], r[4] if len(r) > 4 else "")
    for lane in ("files", "models", "git"):
        print(f"lane {lane:7s} {lane_line(logs, lane, rows)}")
    items = []
    for name in sorted(os.listdir(logs)):
        if name.startswith("items-") and name.endswith(".tsv"):
            items += [r for r in read_tsv(os.path.join(logs, name)) if len(r) >= 7]
    if not items:
        print("\nNo planned items yet. A lane writes its list when it starts.")
        return 0
    order = {"DOWNLOADING": 0, "FAILED": 1, "VERIFY-FAILED": 1, "WAITING": 2, "SKIPPED-SPACE": 2,
             "SKIPPED": 2, "DOWNLOADED": 3, "QUEUED": 4, "RECORDED": 5, "VERIFIED": 5}
    counts, planned, finished, out = {}, 0, 0, []
    for ident, lane, tier, dest, nbytes, _verify, _source in items:
        t, state, detail = last.get(ident, ("", "QUEUED", ""))
        counts[state] = counts.get(state, 0) + 1
        exp = int(nbytes) if nbytes.isdigit() else 0
        planned += exp
        prog = ""
        if state in DONE:
            finished += exp
        elif ident == "github-top":
            man = os.path.join(dest, "manifest.csv")
            if os.path.exists(man):
                with open(man, encoding="utf-8", errors="replace") as f:
                    r = list(csv.reader(f))[1:]
                ok = [x for x in r if len(x) > 8 and x[8] == "cloned"]
                kb = sum(int(x[6]) for x in ok if x[6].isdigit())
                bad = sum(1 for x in r if len(x) > 8 and x[8] == "FAILED")
                prog = f"{len(ok)} cloned, {bad} failed, {kb / 1e6:.1f} GB on disk"
        elif lane == "files" and state in ("DOWNLOADING", "FAILED", "QUEUED", "WAITING"):
            have = bytes_on_disk(dest)
            if exp:
                prog = f"{human(min(have, exp))} of {human(exp)} ({100 * min(have, exp) / exp:.0f}%)"
        elif ident.startswith("ollama:") and state == "DOWNLOADING":
            prog = ollama_progress(logs, ident[7:])
        elif ident.startswith("hf:") and state == "DOWNLOADING":
            prog = f"{human(tree_bytes(dest))} of {human(exp)} on disk" if exp else ""
        elif state == "QUEUED" and exp:
            prog = f"about {human(exp)}"
        out.append((order.get(state, 3), lane, ident, state, t[11:16], tier, prog or detail[:100]))
    print()
    print(f"{'lane':6} {'tier':8} {'item':50} {'state':13} {'time':5}  progress / detail")
    for _o, lane, ident, state, t, tier, text in sorted(out):
        if state in DONE and not show_all:
            continue
        print(f"{lane:6} {tier:8} {ident[:50]:50} {state:13} {t:5}  {text}")
    print()
    print("Totals: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) +
          f"  |  finished {human(finished)} of {human(planned)} with known sizes")
    if not show_all:
        print("Add -a to list finished items too. Full history: " + sp)
    return 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd, args = argv[1], argv[2:]
    table = {
        "files-plan": (cmd_files_plan, 2), "ollama-plan": (cmd_ollama_plan, 2),
        "ollama-verify": (cmd_ollama_verify, 2), "hf-plan": (cmd_hf_plan, 2),
        "hf-verify": (cmd_hf_verify, 5), "git-plan": (cmd_git_plan, 2),
        "github-top": (cmd_github_top, 2),
    }
    if cmd == "status":
        return cmd_status(args[0] if args else "")
    if cmd not in table or len(args) != table[cmd][1]:
        print(__doc__)
        return 2
    return table[cmd][0](*args) or 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
