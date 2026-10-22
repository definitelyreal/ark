<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Changelog

Notable changes to the Ark plan, catalogs, and scripts. Dates are release dates.

## v1.0.0 (2026-10-21)

First official release: everything needed to choose, download, verify, assemble, back up, and harden an offline kit.

### Added

- **Download catalog** (`docs/downloads.ai.md`): reference libraries, public-domain manuals, local AI models, speech, voice, OCR and image models, fonts, and source code, grouped into core (about 90 GB), optional (about 215 GB more), and giant (about 345 GB more) tiers. Each entry has its source, size checked on 2026-10-21, license where the publisher declares one, and how to verify it.
- **Download scripts** (`scripts/`): three resumable lanes (`ark-files.sh` for Kiwix libraries, PDFs and direct files; `ark-models.sh` for Ollama and Hugging Face models; `ark-git.sh` for ClamAV signatures, git repositories and an optional GitHub archive), a read-only `ark-status.sh`, and a standard-library Python helper. Every location is a setting with a neutral default. Downloads resume, keep connections per server low, check publisher checksums, protect free space, and never delete files.
- **Download queues** (`scripts/queues/*.tsv`): the catalog in a form the scripts read, editable to add or remove items.
- **Script guide** (`docs/download-scripts.ai.md`): requirements, quick start, settings, folder layout, pinning, and troubleshooting.
- **Hardening checklist** (`docs/hardening.ai.md`): what to turn off and how on macOS and Linux, with Windows notes and read-only checks.
- **Changelog** (this file).

### Changed

- **Software catalog**: security and integrity tools, more optional modules, a table of activation and account traps, and how to save installers for an offline reinstall.
- **README**: who the kit is for, quick start, repository layout, verification, contributing, and license sections.
- **Build checklist**: links to the download catalog, scripts, and hardening checklist, and a hardening step before the offline acceptance test.

## Before v1.0.0 (2026-10-15)

- Initial public plan, build checklist, software catalog, backup recipe, blank inventory template, and MIT license.
