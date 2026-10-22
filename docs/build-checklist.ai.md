<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Ark build checklist

Use a private copy of this checklist to record your setup. A box means the complete task passed on your equipment; an application merely being installed does not count.

## Choose and prepare

- [ ] Choose a computer, operating system, and storage devices.
- [ ] Measure source data and choose the portable subset.
- [ ] Reserve free space for updates and temporary work.
- [ ] Create the archive folders outside the public Git checkout.
- [ ] Choose a separate backup device and a second-copy location.
- [ ] Record device-specific recovery instructions privately.
- [ ] Enable device encryption on the laptop and portable drives holding private exports or restores.

## Assemble while connected

- [ ] Install the readers, office tools, media players, and converters you need.
- [ ] Download reference collections, manuals, books, and relevant maps. The [download catalog](downloads.ai.md) lists sources by tier, and the [download scripts](download-scripts.ai.md) fetch and verify them.
- [ ] Install a local AI runtime and suitable model if wanted.
- [ ] Download speech models and translation packs if wanted.
- [ ] Install optional creative, engineering, education, and radio modules.
- [ ] Download their fonts, plugins, drivers, libraries, and dependencies.
- [ ] Save installers and documentation for essential applications.
- [ ] Save the official restic program and checksum for each recovery platform beside each backup repository, outside its encrypted contents.
- [ ] Record source URLs, versions, licenses, sizes, and available checksums in a private inventory.
- [ ] Check publisher-provided checksums or signatures where available. With the scripts, every chosen item should show VERIFIED or RECORDED in `bash scripts/ark-status.sh -a`.
- [ ] Export important proprietary projects to accessible formats and collect linked assets.

## Collect and back up

- [ ] Select explicit folders and official service exports; do not assume all account data is covered.
- [ ] Check that cloud files are fully downloaded, not placeholders.
- [ ] Include attachments and relevant metadata in exports.
- [ ] Use a supported export or consistent snapshot for live databases.
- [ ] Create a backup and record its snapshot ID privately.
- [ ] Run the repository integrity check.
- [ ] Restore a sample to a new folder and open the restored files.
- [ ] In a separate disposable folder and test repository, change and delete test files, then prove that the earlier snapshot restores them by ID.
- [ ] Restore a sample offline on a second computer using the saved restic program and separately stored password.
- [ ] Remove unneeded plaintext test restores after checking them.
- [ ] Create and verify an independent second backup.
- [ ] Keep passwords and recovery instructions accessible without the source computer.

## Harden before relying on it offline

- [ ] Work through the [hardening checklist](hardening.ai.md): encryption, boot security, accounts, remote access and sharing, updates and telemetry, then the firewall and radios at the computer itself.
- [ ] Refresh malware signatures and build the tamper-detection baseline as the last steps before going offline.
- [ ] Run the hardening checklist's read-only checks, restart, and run them again.

## Test the actual offline kit

Disconnect networking and any archive drive you do not intend to carry. Restart the laptop and test the following with the portable working set.

| Task | Pass condition |
|---|---|
| Reference reading | Representative articles, diagrams, PDFs, and ebooks open and remain navigable |
| Maps | Needed regions display; planned offline search and routing work |
| Local AI, if selected | A response completes without fetching a model or contacting a service |
| Speech and translation, if selected | A local audio file is transcribed and selected language pairs work |
| Office work | A document and spreadsheet can be opened, edited, saved, and reopened |
| Creative work, if selected | A representative project opens with assets present and exports successfully |
| Conversion | A sample file converts and its result opens in the intended reader |
| Engineering, if selected | An example project builds, simulates, or exports using the saved dependencies |
| Communication hardware, if selected | The intended local hardware workflow completes |
| Media and learning | Representative content starts and plays or runs |
| Backup recovery | A selected snapshot restores to a separate folder and the restored files open |
| Restart and power | Essential tools still work after a restart; chargers and adapters work |

Spend a normal day using the kit without the network. Write down missing components, fix them, and repeat the failed tasks. Record the date and selected versions; success applies to that tested combination.

## Maintain

- [ ] Set an update and backup frequency appropriate to how often the source data changes.
- [ ] Check that expected exports arrived; a successful copy of old files is not fresh coverage.
- [ ] Inspect backup results and investigate incomplete runs.
- [ ] Repeat sample restores after significant changes and periodically between them.
- [ ] Refresh maps, reference editions, and installers intentionally.
- [ ] Verify stored data and the separate copy; monitor media health.
- [ ] Review retention before deleting older snapshots.
- [ ] Re-run offline acceptance after application, operating-system, or hardware changes.

For operating-system recovery, follow the hardware vendor's current procedure and test it separately. A working data restore does not prove a full offline operating-system reinstall.
