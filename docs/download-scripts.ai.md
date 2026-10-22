<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Ark download scripts

Three download "lanes" fetch the items in the [download catalog](downloads.ai.md), check each one against its publisher's checksum, and record the result. A fourth script shows progress. They run on macOS (including its built-in bash 3.2) and on Linux.

| Script | Downloads |
|---|---|
| `scripts/ark-files.sh` | Kiwix libraries, PDFs, and any direct file you add (map extracts, installer images) |
| `scripts/ark-models.sh` | Ollama models, then Hugging Face files |
| `scripts/ark-git.sh` | ClamAV signatures, git repositories, and the optional GitHub archive |
| `scripts/ark-status.sh` | Nothing; shows what is planned, running, finished, or failed |

The scripts have been exercised on macOS with small items from every lane: a Kiwix library, a PDF, a map extract, an Ollama model, two Hugging Face repositories, two git repositories, and a two-repository GitHub archive, including an interrupted download that resumed. That tests the mechanics, not a full multi-day run on your equipment.

## What they promise

- **Nothing is deleted.** A file that fails its check is renamed with a `.bad-<time>` suffix; a broken earlier clone is renamed `.partial-<time>`. Inspect and remove those yourself.
- **Everything resumes.** Stop a lane at any time (Ctrl-C, closing the terminal, a restart). Run it again and it skips finished items and continues partial ones.
- **Polite downloads.** One file at a time per lane, at most `ARK_CONNECTIONS` connections per file (spread across mirrors when a metalink is available) and `ARK_PER_SERVER` to any single server. `ARK_MAX_SPEED` caps the rate.
- **Free space is protected.** Before each item, a lane checks that the download leaves at least `ARK_MIN_FREE_GB` free, and skips the item if not.
- **An unplugged drive is not an empty folder.** On macOS the lanes check that the volume holding `ARK_ROOT` is mounted; if it disappears they wait and check again.
- **No accounts.** No login is used or sent. Gated Hugging Face repositories are skipped.
- **Nothing downloaded is run.** Git clones have hooks, submodules, symlinks, and LFS downloads turned off.

## Requirements

Required: `bash`, `curl`, `python3` (3.8 or newer), and `git` for the git lane. Optional, used when present:

| Tool | Used for | Get it |
|---|---|---|
| `aria2c` | Kiwix downloads from several mirrors with piece checks; faster resumes | [aria2](https://aria2.github.io/) or `brew install aria2` |
| `ollama` | Ollama models | [ollama.com/download](https://ollama.com/download) |
| `hf` | Hugging Face files | `pip install -U huggingface_hub` ([guide](https://huggingface.co/docs/huggingface_hub/guides/cli)) |
| `freshclam`, `sigtool` | ClamAV signatures | [clamav.net/downloads](https://www.clamav.net/downloads) or `brew install clamav` |

A lane marks items SKIPPED when the tool it needs is missing, and keeps going with the rest.

## Quick start

Connect the archive drive, create the archive folder, then start each lane in its own terminal. The default archive is `/Volumes/ARK` (a macOS volume named ARK); set `ARK_ROOT` to use another place, such as `/mnt/ark` on Linux.

```bash
export ARK_ROOT=/Volumes/ARK          # where the archive lives; must already exist
cd /path/to/ark                       # this repository

bash scripts/ark-files.sh             # terminal 1: reference libraries and PDFs
bash scripts/ark-models.sh            # terminal 2: AI models
bash scripts/ark-git.sh               # terminal 3: malware signatures, repositories

bash scripts/ark-status.sh            # any time: progress (add -a to list finished items)
```

To keep a lane running after you close the terminal:

```bash
nohup bash scripts/ark-files.sh >> "$ARK_ROOT/catalog/downloads/lane-files.out" 2>&1 < /dev/null &
```

On macOS, prefix the command with `caffeinate -i` to keep the computer from sleeping while it runs. Start each lane once; a second copy of the same lane refuses to start.

A correct result: `ark-status.sh` shows items moving from QUEUED to DOWNLOADING to VERIFIED (or RECORDED for PDFs without a publisher checksum), and each lane prints `END ... 0 item(s) not finished` when it is done.

## Choosing what to download

```bash
ARK_TIERS="core optional" bash scripts/ark-files.sh       # add the optional tier
ARK_TIERS="core optional giant" bash scripts/ark-models.sh
ARK_ONLY="wikipedia ifixit" bash scripts/ark-files.sh     # only items whose name contains a word
ARK_GITHUB_TOP=1000 ARK_ONLY=github bash scripts/ark-git.sh   # only the GitHub archive
```

To change the lists, edit the queue files in `scripts/queues/` (or point `ARK_QUEUES` at your own copies). Each queue file explains its columns at the top. Fields are separated by a single tab, and `-` marks an empty field.

| Queue | One row per | Columns |
|---|---|---|
| `kiwix.tsv` | Kiwix library | tier, category, file-name prefix, folder, note |
| `files.tsv` | Direct download | tier, id, folder, file name, URL, check, checksum, note |
| `ollama.tsv` | Ollama model | tier, model, approximate bytes, note |
| `huggingface.tsv` | Hugging Face selection | tier, name, repository, kind, folder, include patterns, note |
| `git.tsv` | Git repository | tier, name, URL, folder, note |

In `files.tsv`, the check is `sha256` or `md5` (the value goes in the checksum column), `sha256-url` or `md5-url` (a checksum file published beside the download; put its URL in the checksum column, or `-` for the download URL plus `.sha256` or `.md5`; a `SHA256SUMS` list works), or `record` when the publisher offers no checksum.

## Settings

| Variable | Default | Meaning |
|---|---|---|
| `ARK_ROOT` | `/Volumes/ARK` | Archive root. Must already exist. |
| `ARK_LOGS` | `$ARK_ROOT/catalog/downloads` | State log, per-lane logs, pinned lists |
| `ARK_QUEUES` | `scripts/queues` | Folder of queue files |
| `ARK_TIERS` | `core` | Tiers to download: any of `core optional giant` |
| `ARK_ONLY` | empty | Space-separated words; only matching items are processed |
| `ARK_MIN_FREE_GB` | `20` | Free space to keep on the archive drive |
| `ARK_CONNECTIONS` | `4` | Connections for one file, spread over mirrors |
| `ARK_PER_SERVER` | `2` | Connections to any single server |
| `ARK_MAX_SPEED` | empty | Download rate cap such as `5M`; empty means none |
| `ARK_PASSES` | `3` | Passes over the list before a lane stops |
| `ARK_RETRY_WAIT` | `300` | Seconds between passes |
| `ARK_MOUNT` | the macOS volume holding `ARK_ROOT` | Path that must be a mount point; set it empty to skip the check |
| `ARK_OLLAMA_STORE` | `$ARK_ROOT/models/ollama` | Where Ollama models are stored |
| `ARK_OLLAMA_HOST` | `127.0.0.1:11436` | Address of the private Ollama server the models lane starts |
| `ARK_OLLAMA_REUSE` | `0` | `1` lets the lane use a server already on that address (only if it stores models in `ARK_OLLAMA_STORE`) |
| `ARK_REHASH` | `1` | `0` checks Ollama layer sizes only, instead of re-hashing them |
| `ARK_HF_HOME` | `$ARK_LOGS/hf-home` | Settings folder for the `hf` tool, kept apart from your usual one |
| `ARK_GIT_RESERVE_GB` | `5` | Free space required before each git clone |
| `ARK_GITHUB_TOP` | `0` | Number of most-starred GitHub repositories to archive; 0 turns it off |
| `ARK_GITHUB_FLAG_AFTER` | empty | A date (`YYYY-MM-DD`); repositories pushed after it are marked RECENT in the manifest |

## Where files go

Under `ARK_ROOT`, using the folder names from the [suggested archive layout](../README.md#a-suggested-private-archive-layout):

```text
ARK_ROOT/
  catalog/downloads/   state.tsv, items and plan lists, logs, pinned editions and commits
  knowledge/kiwix/     ZIM libraries, each with its .sha256
  knowledge/pdfs/      PDFs by subject, each with the SHA-256 recorded at download
  maps/                Map extracts you add
  models/ollama/       Ollama model store
  models/speech/       whisper.cpp, faster-whisper and Parakeet models
  models/tts/, models/ocr/, models/embeddings/, models/image/, models/llm-gguf/
                       Other Hugging Face selections
  software/clamav-db/  ClamAV signatures
  software/os-images/  Installer and restore images you add
  media/fonts/ media/icons/   Font and icon repositories
  tools/               YARA rules, source code, and the GitHub archive (tools/github/)
```

## Pinning: why a resumed download does not change under you

The first time a Kiwix library is planned, the newest edition's file name and checksum are written to `catalog/downloads/kiwix-resolved.tsv`. Hugging Face selections are pinned to one commit in `hf-pinned.tsv`, and the GitHub archive list is saved in `github-top.tsv`. Later runs reuse these, so a resumed download always matches its checksum. To look for newer editions, rename the pinned file (for example add `.old`) and run the lane again; files already downloaded stay where they are.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `The archive at ARK_ROOT=... is not available` | Connect and mount the drive, create the folder, or set `ARK_ROOT`. |
| `Lane '...' already looks busy` | Another copy is running; check `ark-status.sh`. If no lane is running, rename the named `.pid` file and start again. |
| An item stays `SKIPPED-SPACE` | Free space, choose fewer tiers, or lower `ARK_MIN_FREE_GB` if you are sure. |
| An item is `VERIFY-FAILED` | The bad copy was renamed and the next pass downloads it again. Repeated failures can mean a bad mirror or a failing drive; check the drive's health. |
| A Kiwix library is missing from the plan | Kiwix renamed or retired it. Find the current name at [download.kiwix.org](https://download.kiwix.org/zim/) and update `kiwix.tsv`. |
| An Ollama pull fails immediately after an interruption | Rename the model's `*-partial*` files in `models/ollama/blobs/` (for example add `.old`) and run the lane again; that layer downloads afresh. |
| `something already answers on 127.0.0.1:11436` | Another program uses that port. Set `ARK_OLLAMA_HOST` to a free one, such as `127.0.0.1:11437`. |
| ClamAV download refused | ClamAV's mirror limits repeat downloads. Wait an hour, then run the git lane again. |
| GitHub archive stops listing | The unauthenticated GitHub search allows about 10 requests a minute; the helper waits and retries. Rerun later if it gives up. |

Logs for each lane are in `catalog/downloads/`: `files-download.log`, `hf-download.log`, `ollama-serve.log`, `ollama-pull-*.jsonl`, `git-clone.log`, and `freshclam.out`.
