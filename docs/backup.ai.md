<!-- ai-suggestion:unverified | date:2026-10-15 -->
# Simple backups for Ark

Collect only the folders and exports you choose, preserve versions, and prove recovery. This recipe uses existing tools; it does not include a custom account connector or personal-data application.

The initial backup and restore workflow was exercised with synthetic data on macOS using restic 0.19.1 and rclone 1.73.2. That checks command behavior, not your source coverage or the complete offline kit. The AI provenance marker labels the plan's authorship; your own installation still needs the checklist tests.

## Choose what to collect

| Source | Collection method | Check before calling it complete |
|---|---|---|
| Local documents and photos | Select ordinary local folders | Files are fully downloaded and readable |
| Cloud file storage | Official export or a supported rclone source | Scope, attachments, cloud-native document exports, and failures |
| Email, calendar, and contacts | Official exports such as MBOX, EML, ICS, or vCard | Date coverage and attachments; verify with a suitable reader |
| Notes and bookmarks | Application-supported export | Attachments and links survive; an accessible copy opens locally |
| Application databases | Supported application export or consistent database backup | An open database is not backed up by copying one file blindly |

Keep original exports and a short private record of the source, requested coverage, collection date, tool version, file count, and failures. An export can omit service-specific data; inspect the provider's export options. Source coverage must be checked separately from backup integrity.

## Prepare the storage

Install [restic](https://restic.readthedocs.io/en/stable/020_installation.html) and Python 3, which the small mount check below uses. Install [rclone](https://rclone.org/install/) only if using its optional collection step. Keep data and credentials outside the Ark Git checkout. Save the official restic program for every intended recovery platform, with its checksum, beside each backup repository and in your software archive. It must be accessible before the backup is opened.

The following shell recipe is for macOS or Linux. Run the setup in the terminal where you will use the later blocks; repeat it in a new terminal. Replace the backup-device path with the actual mount point of your external device, such as `/Volumes/ARK_BACKUP` on macOS or `/mnt/ark-backup` on Linux. Confirm it is the intended separate device. The helper refuses an ordinary unmounted directory; it does not establish that two volumes are on different physical devices.

```bash
export ARK_EXPORTS="$HOME/ArkData/exports"
export ARK_BACKUP_DEVICE="/Volumes/ARK_BACKUP"
mkdir -p "$ARK_EXPORTS"

# Keep errors visible in this terminal and stop the failed operation.
ark_repo() {
  if [ -z "${ARK_BACKUP_DEVICE:-}" ]; then
    printf '%s\n' 'Run the storage setup first.' >&2
    return 1
  fi
  if ! python3 -c 'import os, sys; sys.exit(0 if os.path.ismount(sys.argv[1]) else 1)' "$ARK_BACKUP_DEVICE"; then
    printf '%s\n' 'Backup mount check failed. Check Python 3 and the mounted device path.' >&2
    return 1
  fi
  restic --repo "$ARK_BACKUP_DEVICE/restic" "$@"
}
```

For a **new** repository only, run `ark_repo init` and enter its password. For an existing repository, skip initialization and run `ark_repo snapshots` to check access. If a command fails, resolve the error before continuing; chained commands using `&&` run only after the previous command succeeds.

Keep the password recoverable separately from the repository. Restic encrypts the backup; losing every usable password prevents recovery. See [repository setup](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html).

Do not place the backup repository inside a source folder. These commands cover the collection folder only. Local folders can be backed up directly without making a second collection copy. If you also selected your Documents folder, for example, use `ark_repo backup --host ark --tag ark -- "$ARK_EXPORTS" "$HOME/Documents"`. Repeat the recovery test for every added source.

Only the restic repository is encrypted by restic. Export, incoming, and restore folders contain readable files. Use device encryption on their storage, keep access limited to the intended users, and remove unneeded test restores after inspection.

## Collect files

For downloaded service exports, receive and inspect them in `ArkData/incoming/`, then move each completed export into a new dated subfolder of `ARK_EXPORTS`. The backup command excludes `incoming/` because that folder is outside its selected source. Keep the previous export until the new one has passed collection and backup checks.

For an optional rclone source, configure your own remote outside this repository using the provider's normal authorization flow. Choose read-only permission where available. Keep the rclone configuration out of `ArkData` and exports; it can contain account tokens. Protect its storage with device encryption or use [rclone configuration encryption](https://rclone.org/docs/#configuration-encryption). Replace `source:chosen-folder` below with that selected remote folder. The command copies from it into a new local folder; it does not write to the service.

```bash
export ARK_INCOMING="$HOME/ArkData/incoming"
export ARK_BATCH_NAME="$(date -u +%Y%m%dT%H%M%SZ)"
export ARK_PARTIAL="$ARK_INCOMING/$ARK_BATCH_NAME.partial"
export ARK_BATCH="${ARK_EXPORTS:?Run storage setup first}/$ARK_BATCH_NAME"
mkdir -p "$ARK_INCOMING" &&
  mkdir "$ARK_PARTIAL" &&
  rclone copy "source:chosen-folder" "$ARK_PARTIAL" --immutable --dry-run
```

After a successful dry run, review the selected source, destination, and expected coverage. Then collect; only a successful copy is promoted into the backup source:

```bash
if [ -d "${ARK_PARTIAL:?Run the collection setup first}" ] &&
   [ ! -e "${ARK_BATCH:?Run the collection setup first}" ]; then
  rclone copy "source:chosen-folder" "$ARK_PARTIAL" --immutable &&
    mv "$ARK_PARTIAL" "$ARK_BATCH"
else
  printf '%s\n' 'Staging folder missing or final batch already exists. Inspect before retrying.' >&2
fi
```

[rclone copy](https://rclone.org/commands/rclone_copy/) leaves destination-only files in place. Each batch above has a new destination, and `--immutable` rejects a conflicting modification during a retry. A failed copy remains in `incoming/` with its `.partial` name and is not included by the backup command. Inspect completed exports for application-level completeness before treating them as current. Some provider APIs cannot enforce read-only access; the selected operation still needs its source and destination checked.

This basic recipe preserves file exports. It does not promise provider permissions, sharing relationships, revision history, or every service feature. Service exports and configured cloud reads require a network connection; a completed local collection can be backed up and restored offline.

## Create and check a snapshot

After confirming the collection is complete, run:

```bash
ark_repo backup --host ark --tag ark -- "${ARK_EXPORTS:?Run storage setup first}" &&
  ark_repo snapshots --host ark --tag ark &&
  ark_repo check
```

Save the successful snapshot ID in your private backup record. A nonzero backup exit status needs attention; status 3 means some source files could not be read even though a partial snapshot may exist. See [backup behavior](https://restic.readthedocs.io/en/stable/040_backup.html).

After the first backup, and periodically thereafter, run `ark_repo check --read-data` to read all stored data as well as checking repository structure. Plan time for this on a large archive. Routine `check` validates structure but does not read every stored data block. See [integrity checks](https://restic.readthedocs.io/en/stable/045_working_with_repos.html).

Snapshots preserve earlier versions when source files change. Do not add automatic snapshot deletion or pruning until you have chosen a retention policy and verified the separate backup.

## Restore to a new folder

Use the same repository and password. This restores the latest snapshot labeled for this kit; choose an explicit snapshot ID from `ark_repo snapshots` instead of `latest` when recovering an earlier version.

```bash
export ARK_RESTORE_PARENT="$HOME/ArkRestore"
export ARK_RESTORE="$ARK_RESTORE_PARENT/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$ARK_RESTORE_PARENT" &&
  mkdir "$ARK_RESTORE" &&
  ark_repo restore latest --host ark --tag ark --target "$ARK_RESTORE" --verify
```

Restored absolute source paths appear beneath the destination. Open the restored documents and attachments in their intended applications, then compare a sample with the originals. Do not aim a test restore at your live source folders. See [restoring snapshots](https://restic.readthedocs.io/en/stable/050_restore.html).

To test version history, create a separate disposable source folder and set `ARK_TEST_REPOSITORY` to a separate test repository. Every test command must explicitly select that repository: use `restic --repo "$ARK_TEST_REPOSITORY" init`, then `restic --repo "$ARK_TEST_REPOSITORY" backup -- /path/to/disposable-source`. Save the first snapshot ID from `restic --repo "$ARK_TEST_REPOSITORY" snapshots`, change one sample file, delete another, and repeat the test backup command. Set `ARK_FIRST_SNAPSHOT` and `ARK_TEST_RESTORE` to that first snapshot ID and a new destination, then restore with:

```bash
mkdir "${ARK_TEST_RESTORE:?Set a new test restore path}" &&
  restic --repo "${ARK_TEST_REPOSITORY:?Set the disposable test repository}" \
    restore "${ARK_FIRST_SNAPSHOT:?Set the first test snapshot ID}" \
    --target "$ARK_TEST_RESTORE" --verify
```

Both earlier contents should return. Keep this experiment out of the real collection and repository; remove its disposable files after checking. Also test a real sample restore offline on a second computer using only the saved restic program, backup device, and separately stored password.

## A second copy and repeat runs

Create another restic repository on a different device and back up the same selected sources to it. Check and restore from that repository too. The commands above exercise one destination at a time; one successful destination is not proof of a second copy.

For repeat runs, repeat the storage setup, check access with `ark_repo snapshots`, collect a fresh batch, and run backup and verification. Do not repeat initialization for an existing repository. Scheduling is optional and is not installed by this plan. If you later schedule it, preserve failure reporting and keep logs private.

The public repository contains no account configurations or exports. No source-side updates, outbound messages, webhook triggers, remote commands, or advanced queries are needed for this workflow.
