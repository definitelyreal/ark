<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Ark

**An offline knowledge, tools, and backup kit you can build for yourself.**

Ark helps you keep useful information, working software, and recoverable copies of your data when the internet, a service, or your main computer is unavailable. Build it on a spare laptop, use external storage for the larger library, and keep a portable selection ready to take with you.

This repository is a build plan, a catalog of what to download, scripts that download and verify it, and checklists for assembling, backing up, and hardening the machine. It contains no downloaded content and no one's personal archive. Start with the essentials, add the modules you need, and test the result with the network disconnected.

It also includes a [security guide](docs/security.ai.md) for the computer, phone, and accounts you use every day, with a prompt that has Claude review your setup with you.

## Who it is for

Anyone who wants a computer that still answers questions, opens documents, plays media, and restores their files when the network or a service is gone: households preparing for outages, people in places with unreliable internet, travelers, field workers, and anyone who prefers to own copies of the references they depend on. You should be comfortable installing applications and pasting commands into a terminal. No programming is required.

## Start here

1. Read the plan below and choose your storage budget.
2. Use the [build checklist](docs/build-checklist.ai.md) to assemble and test your kit.
3. Choose libraries and models from the [download catalog](docs/downloads.ai.md), then fetch and verify them with the [download scripts](docs/download-scripts.ai.md) or by hand.
4. Choose applications from the [software catalog](docs/software.ai.md).
5. Follow the [backup recipe](docs/backup.ai.md) to collect exports, create versioned backups, and restore them.
6. Harden the machine with the [hardening checklist](docs/hardening.ai.md) before relying on it offline.
7. Record your own downloads in a private copy of the [inventory template](examples/inventory.csv).
8. Secure your everyday computer, phone, and accounts with the [security guide](docs/security.ai.md).

## Quick start

On macOS or Linux, with `bash`, `curl`, `python3`, and `git` installed, connect an external drive with a folder for the archive, then:

```bash
git clone <this repository's URL> ark && cd ark
export ARK_ROOT=/Volumes/ARK          # your archive folder, e.g. /mnt/ark on Linux
bash scripts/ark-files.sh             # reference libraries and PDFs (about 78 GB in the core tier)
bash scripts/ark-models.sh            # local AI and speech models (needs ollama and hf for those items)
bash scripts/ark-git.sh               # malware signatures and repositories
bash scripts/ark-status.sh            # progress at any time
```

Each script resumes where it left off, so run them in separate terminals and restart them whenever you like. The core tier is about 90 GB; add `ARK_TIERS="core optional"` for about 215 GB more. The [script guide](docs/download-scripts.ai.md) covers settings, tools, and troubleshooting.

## Repository layout

```text
README.md                    This overview and plan
CHANGELOG.md                 Release notes
LICENSE                      MIT license for the original material
docs/build-checklist.ai.md   Assembly, offline acceptance tests, maintenance
docs/downloads.ai.md         Download catalog: sources, sizes, licenses, verification
docs/download-scripts.ai.md  How to run the download scripts
docs/software.ai.md          Software catalog, activation traps, saving installers
docs/backup.ai.md            Collecting exports, versioned backups, restores
docs/hardening.ai.md         Turning off network access and other exposure
docs/security.ai.md          Securing everyday devices and accounts, with a Claude review prompt
docs/threats-2026-10.ai.md   Dated snapshot of security threats, October 2026
scripts/ark-*.sh             Download lanes and the status script
scripts/ark-helper.py        Planning, verification, and status helper (standard library only)
scripts/queues/*.tsv         The lists of what to download, by tier
examples/inventory.csv       Blank template for your private download record
```

The `.ai.md` suffix and the comment on each document's first line mark text drafted with AI assistance.

## The basic plan

### A working computer and two kinds of storage

Use a laptop you can maintain, with a healthy battery, a charger, and software that supports its processor and operating system. The plan is adaptable to macOS, Linux, and Windows; individual applications and installation steps vary. The command examples use a macOS or Linux shell.

Keep a **portable working set** on the laptop: essential references, local maps, documents, a small AI model if useful, and the applications needed to open everything. Keep a **larger archive** on external storage: additional books, models, media, installers, and backup history.

Maintain another backup on a separate device. A second folder or a RAID array alone does not provide an independent backup. Keep one copy disconnected between updates and, where practical, in another location. Store all downloaded content and private data outside this Git checkout.

The following are planning allowances, not measured download sizes or hardware requirements. A reference-only kit can be smaller; a media-heavy kit can be much larger.

| Component | Starting allowance | What determines the actual size |
|---|---:|---|
| Operating system and applications | 50–100 GB | Platform and chosen applications |
| Reference library | 30–150 GB | Languages, images, books, and learning packs |
| Local AI | 5–40 GB | Model size, precision, and optional speech models |
| Maps and field references | 5–50 GB | Regions, detail, and imagery |
| Your exports and documents | Measure locally | Selected source data |
| Free working space | About 20% of the working drive | Updates, temporary conversions, and growth |
| Backup storage | Size separately | Data volume, change rate, and retained versions |

### Knowledge and practical references

Build an offline library around [Kiwix](https://kiwix.org/en/) and downloadable ZIM collections. Start with an encyclopedia, repair guides, technical references, textbooks, dictionaries, and books in the languages you use. Kiwix provides readers for downloaded collections; select the available collections that fit your disk budget. The [download catalog](docs/downloads.ai.md) suggests a core set of about 78 GB in English, with sizes and checksums for each library.

Add locally saved PDFs and ebooks for equipment manuals, food and water preparation, gardening, basic first aid, and household repair. Prefer identifiable publishers, record the edition or publication date, and retain attribution and licenses. Keep references distinct from AI-generated answers.

Use a normal PDF reader and an ebook reader alongside Kiwix. Test the actual books, images, diagrams, and indexes offline. A downloaded web page that still needs remote images is incomplete.

### Local AI and language tools

Keep local AI as an optional assistant for writing, coding, explanation, and translation. A small model that runs comfortably on the laptop is more useful than a large model that requires an unavailable external drive or exceeds memory.

Choose a local runtime such as [Ollama](https://ollama.com/) or [llama.cpp](https://github.com/ggml-org/llama.cpp), download a compatible model, and save its license and instructions. The [download catalog](docs/downloads.ai.md) lists models by size. Add a coding or vision model only if you have a use for it. The basic plan does not connect the model to your backups or build a searchable personal-data system.

Optional additions include local transcription with [whisper.cpp](https://github.com/ggml-org/whisper.cpp), offline translation with [Argos Translate](https://www.argosopentech.com/), and ordinary text-to-speech. Download the required model and language files before testing offline. AI output still needs checking against reliable references.

### Maps and navigation

Download the regions you need, including alternate destinations and routes. [Organic Maps](https://organicmaps.app/) is an option for offline phone maps and navigation. Test address search and a route in airplane mode.

For desktop use, keep readable regional maps or configure a GIS viewer with local data. A raw map extract is source material, not a ready navigation system: verify the viewer, styling, search, and any routing data together. Add topographic PDFs or printable maps for critical areas.

### Documents, creative work, and conversion

Keep an office suite, a PDF reader, an ebook reader, a plain-text editor, and media playback. Add the creative tools you use: image editing, drawing, audio editing, video editing, photography, or 3D work.

Include conversion tools for documents, images, audio, and video. Preserve originals alongside accessible exports. Before depending on a project offline, collect its linked assets, fonts, plugins, and other dependencies. Export open interchange where supported and a flattened reference copy where appropriate; reopen both and compare them with the original.

Do not assume that installing a subscription application guarantees indefinite offline access. Check its current licensing requirements and include a tested alternative for essential tasks.

### Engineering, learning, and communication

Add modules that match your interests: CAD, electronics design, circuit simulation, 3D-print preparation, microcontroller development, unit conversion, astronomy, dictionaries, or educational courses. Save libraries, board support packages, examples, and documentation as well as the application itself.

Radio and local communication tools are optional modules. Include the matching hardware, cables, drivers, and operating instructions, then test the complete setup. Check the local reception and transmission rules, any required operating license, and permitted bands before use. Configure a mesh radio's [region settings](https://meshtastic.org/docs/configuration/radio/lora/) for its location. Installing a radio application by itself does not create a communication link.

Keep a small offline entertainment collection: music, films, audiobooks, games, or other material you have the right to store. Test playback and game startup without an account refresh.

### Simple data backups

The data feature has one purpose: make your selected data recoverable.

```text
Service exports → Local collection folder ─┐
                                          ├→ Versioned encrypted backup
Selected local folders ────────────────────┘             ↓
                                             Restore to a separate folder
```

Use official exports for services that offer them. Where a supported file service can be read by a copy tool, pull selected folders into local storage. Use narrowly scoped read access where the provider supports it. Preserve original export files and attachments.

Use [restic](https://restic.readthedocs.io/en/stable/) for encrypted, versioned backups. The [backup recipe](docs/backup.ai.md) explains collection, snapshots, verification, and recovery. Optional file collection uses rclone in the source-to-local direction. There is no writeback to the source service, messaging, account automation, query service, or AI indexing in this plan.

Copying alone is not version history. Preserve a successful backup before refreshing a collection, retain snapshots, and verify that an older version can actually be restored.

### Recovery, power, and maintenance

Keep application installers, required packages, manuals, and a printed recovery note. Save the official restic program and its checksum for each recovery platform beside the backup repository, as well as in your software archive; a program stored only inside the encrypted backup cannot help open that backup. Record which files matter most, which application opens each format, and how to access the backup without relying on the computer being recovered. Keep backup passwords and recovery material separately and privately.

Include spare charging cables, adapters, and storage connections. Estimate daily energy in watt-hours by adding each device's measured watts multiplied by its hours of use. Compare that with the battery's usable energy after conversion losses, and allow for reserve time. Check charger and USB-C power compatibility; treat solar output as variable and measure your actual setup. Optional external power should be tested with the equipment it will support.

Use device encryption on the laptop and any portable storage holding private files. Restic encrypts its repository, not the original exports or restored folders. Remove unneeded test restores after checking them. The goal is a usable, maintainable offline kit. Reconnect for deliberate updates as needed, then repeat the offline checks. Verify stored data periodically and replace failing media; no storage medium should be treated as permanent.

The [hardening checklist](docs/hardening.ai.md) covers what to turn off before relying on the machine offline: remote access and sharing services, automatic updates and telemetry, network time, and finally the network itself, with read-only commands to confirm each step.

## A suggested private archive layout

Create this outside the Git repository. Names and contents are yours to choose.

```text
ArkData/
  catalog/       Download inventory, licenses, checksums, instructions
  knowledge/     ZIMs, PDFs, ebooks, learning packs
  maps/          Regional maps and viewer data
  models/        Local AI, speech, and translation models
  software/      Installers, dependencies, and documentation
  tools/         Local utilities and your own scripts
  incoming/      Incomplete collection batches, outside the backup source
  exports/       Selected source exports and copied files
  media/         Offline playback and entertainment
  recovery/      Recovery instructions and non-secret reference files
```

The download scripts use the same folder names under their archive root (`ARK_ROOT`, by default `/Volumes/ARK`), so libraries land in `knowledge/`, models in `models/`, and their logs and checksums in `catalog/downloads/`. Point `ARK_ROOT` at this folder if you keep everything together.

Keep the backup repository on a separate storage device, outside every source folder it backs up. Keep credentials, passwords, and live configuration outside both this public repository and its example files.

## Verification

Every download in the catalog is checked against what its publisher provides: Kiwix's published SHA-256 for each library, Geofabrik's MD5 for map extracts, Ollama's per-layer SHA-256 digests, the per-file hashes Hugging Face publishes, git's object hashes with the HEAD commit recorded, and ClamAV's digital signatures. Where a publisher gives no checksum, as with most PDFs, the scripts record a SHA-256 on arrival so later changes can be detected. A `.sha256` or `.md5` file is kept beside each download for offline re-checks.

A checksum shows that a file matches what the server offered, not that the server is trustworthy. For anything critical, also compare against a second source, such as a different mirror or a signed checksum list. The [download catalog](docs/downloads.ai.md) explains how to check each kind of item by hand, and the [build checklist](docs/build-checklist.ai.md) covers testing that everything actually opens and runs offline.

## What belongs in this repository

General instructions, original helper code, public source links, and synthetic examples belong here. Actual downloads, personal exports, account details, logs, device inventories, credentials, and private configuration do not. The default `.gitignore` allows only the named publication files; contributors should deliberately extend it when adding material.

This repository does not bundle third-party applications, books, models, or datasets. Acquire those from their publishers and follow their licenses.

## Contributing and reporting problems

Open an issue on this repository's GitHub page to report a broken link, a renamed library, a script error, or an instruction that did not work, and include your operating system and the exact command and message. Pull requests are welcome for corrections, new well-sourced catalog entries, and script fixes. Please:

- link to the publisher's own download page, with the size and how to verify the file;
- run `bash -n` (and `shellcheck` if you have it) on changed scripts, and test them on a small item;
- keep personal details, account names, machine names, logs, and downloaded content out of the repository;
- add any new public file to the allowlist in `.gitignore` deliberately.

## License

The repository's original material (documents, scripts, and queue lists) is available under the [MIT license](LICENSE). Third-party software, libraries, books, and models keep their own licenses, which are noted in the catalogs where the publisher declares them.
