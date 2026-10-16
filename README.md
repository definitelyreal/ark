<!-- ai-suggestion:unverified | date:2026-10-15 -->
# Ark

**An offline knowledge, tools, and backup kit you can build for yourself.**

Ark helps you keep useful information, working software, and recoverable copies of your data when the internet, a service, or your main computer is unavailable. Build it on a spare laptop, use external storage for the larger library, and keep a portable selection ready to take with you.

This repository is a build plan and a set of tool recipes. It does not install a complete system or contain an existing user's archive. Start with the essentials, add the modules you need, and test the result with the network disconnected.

## Start here

1. Read the plan below and choose your storage budget.
2. Use the [build checklist](docs/build-checklist.ai.md) to assemble and test your kit.
3. Choose applications from the [software catalog](docs/software.ai.md).
4. Follow the [backup recipe](docs/backup.ai.md) to collect exports, create versioned backups, and restore them.
5. Record your own downloads in a private copy of the [inventory template](examples/inventory.csv).

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

Build an offline library around [Kiwix](https://kiwix.org/en/) and downloadable ZIM collections. Start with an encyclopedia, repair guides, technical references, textbooks, dictionaries, and books in the languages you use. Kiwix provides readers for downloaded collections; select the available collections that fit your disk budget.

Add locally saved PDFs and ebooks for equipment manuals, food and water preparation, gardening, basic first aid, and household repair. Prefer identifiable publishers, record the edition or publication date, and retain attribution and licenses. Keep references distinct from AI-generated answers.

Use a normal PDF reader and an ebook reader alongside Kiwix. Test the actual books, images, diagrams, and indexes offline. A downloaded web page that still needs remote images is incomplete.

### Local AI and language tools

Keep local AI as an optional assistant for writing, coding, explanation, and translation. A small model that runs comfortably on the laptop is more useful than a large model that requires an unavailable external drive or exceeds memory.

Choose a local runtime such as [llama.cpp](https://github.com/ggml-org/llama.cpp), download a compatible model, and save its license and instructions. Add a coding or vision model only if you have a use for it. The basic plan does not connect the model to your backups or build a searchable personal-data system.

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

Keep the backup repository on a separate storage device, outside every source folder it backs up. Keep credentials, passwords, and live configuration outside both this public repository and its example files.

## What belongs in this repository

General instructions, original helper code, public source links, and synthetic examples belong here. Actual downloads, personal exports, account details, logs, device inventories, credentials, and private configuration do not. The default `.gitignore` allows only the named publication files; contributors should deliberately extend it when adding material.

This repository does not bundle third-party applications, books, models, or datasets. Acquire those from their publishers and follow their licenses. The repository's original material is available under the [MIT license](LICENSE).
