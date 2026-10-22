<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Hardening an offline Ark machine

A checklist for turning a laptop into a machine that other computers cannot reach, that does not reach out, that keeps its data encrypted, and that notices tampering. Do everything that needs the internet first. The steps that cut networking come last, at the computer itself, because they end any remote session.

Steps are given for recent macOS and for systemd-based Linux distributions such as Debian, Ubuntu, and Fedora, with short Windows notes at the end. Menu names move between operating-system versions; search the settings window if a path has changed. Commands that start with `sudo` need an administrator password. Each section ends with read-only commands you can run to confirm the result.

Software switches can be turned back on by malicious software. The packet filter in section 6 and physical measures in section 9 are the backstops.

## 1. Before you go offline

- [ ] Choose the operating-system version you will keep, and apply the updates you want. The machine gets no security patches afterwards.
- [ ] Save a clean reinstall path. On a Mac, keep the restore image (IPSW) for your exact model and version; [ipsw.me](https://ipsw.me/) lists Apple's download links with SHA-256 values. On Linux, keep the installer image and verify it against the distribution's signed checksum list ([Debian](https://www.debian.org/CD/verify), [Ubuntu](https://ubuntu.com/tutorials/how-to-verify-ubuntu)). Store it on write-protected or write-once media and practice the reinstall. A working data restore does not prove a working reinstall.
- [ ] Install every application you need and open each one once (see the [software catalog](software.ai.md)). Many fetch plugins, language data, or models on first launch.
- [ ] Download and verify your libraries and models (see the [download catalog](downloads.ai.md)).
- [ ] Refresh malware signatures as late as possible (`freshclam`) and save scanning rules. Note the signature date; it is frozen from then on.
- [ ] Move the passwords and recovery codes you need into an offline password manager such as KeePassXC, and write the master password and disk recovery key on paper.
- [ ] Back up the machine's data to a separate device and test a restore (see the [backup recipe](backup.ai.md)).

## 2. Encryption and boot security

| Item | macOS | Linux |
|---|---|---|
| Internal disk encryption | System Settings > Privacy & Security > FileVault > Turn On. Choose to create a recovery key rather than storing it with an online account. Write the key on paper, keep two copies in separate places, and test it. Terminal alternative: `sudo fdesetup enable` (prints the key) | Choose full-disk encryption (LUKS) when installing. Adding it to an existing install usually means reinstalling |
| External drives with private data | Finder: right-click the drive > Encrypt, or Disk Utility | LUKS (`cryptsetup luksFormat` erases the drive), or a VeraCrypt container |
| Boot security | Apple silicon: shut down, hold the power button until startup options appear, choose Options, then Utilities > Startup Security Utility > Full Security. Note the firmware version shown | In the firmware setup: Secure Boot on, a firmware (BIOS/UEFI) password, and booting limited to the internal disk |
| Built-in protections | Leave System Integrity Protection and Gatekeeper on | Keep the distribution's mandatory access control (AppArmor or SELinux) on |

Check:

```bash
fdesetup status                      # macOS: "FileVault is On."
csrutil status                       # macOS: "System Integrity Protection status: enabled."
spctl --status                       # macOS: "assessments enabled"
diskutil apfs list | grep -i filevault   # macOS: "Yes" for each encrypted volume
lsblk -f                             # Linux: crypto_LUKS under the system disk
mokutil --sb-state                   # Linux: "SecureBoot enabled"
```

## 3. Accounts

- [ ] Copy anything you need that lives only in a cloud account, turn off keychain or password sync, then sign out (macOS: System Settings > your name > Sign Out). This keeps recovery keys and passwords from being stored where the machine can no longer reach them.
- [ ] Use a standard (non-administrator) account for daily work; keep an administrator account for changes.
- [ ] Turn off the guest account (macOS: System Settings > Users & Groups) and remove or lock accounts nobody uses.

## 4. Remote access, sharing, and background services

| Turn off | macOS | Linux |
|---|---|---|
| Remote login (SSH) | System Settings > General > Sharing > Remote Login off, or `sudo systemsetup -f -setremotelogin off` (Terminal may need Full Disk Access). Remove keys you no longer need from `~/.ssh/authorized_keys` | `sudo systemctl disable --now ssh` (Debian, Ubuntu) or `sshd` (Fedora). Review `~/.ssh/authorized_keys` |
| Remote desktop | Sharing > Screen Sharing and Remote Management off | Desktop settings > Sharing or Remote Desktop off |
| File, media, printer, and internet sharing; remote scripting | Sharing > turn each off | Disable Samba (`smbd`) if installed |
| Local network discovery | Covered by the sharing settings and firewall | `sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket cups-browsed` |
| Nearby-device features | System Settings > General > AirDrop & Handoff: AirDrop "No One", Handoff off, AirPlay Receiver off | Disable KDE Connect, GSConnect, or similar if installed |
| Third-party remote-access tools, VPN and mesh-network clients, cloud-sync clients | Quit them and remove them with their own uninstallers | Remove the packages and their services |
| Waking for network access | System Settings > Battery or Energy > Wake for network access off | Not usually enabled |

Then look for anything left that starts by itself or listens on the network:

```bash
# macOS
ls /Library/LaunchDaemons /Library/LaunchAgents ~/Library/LaunchAgents
launchctl list | grep -v com.apple
sudo lsof -nP -iTCP -sTCP:LISTEN     # ideally empty, or only 127.0.0.1 and ::1
sudo lsof -nP -iUDP
# Linux
systemctl list-unit-files --state=enabled
systemctl --user list-unit-files --state=enabled
sudo ss -tulpn                       # ideally only 127.0.0.1 and ::1
```

Also review System Settings > General > Login Items & Extensions on macOS. A service listening only on 127.0.0.1 or ::1 is reachable from this computer only.

## 5. Updates, telemetry, location, and time

| Item | macOS | Linux |
|---|---|---|
| Automatic updates | System Settings > General > Software Update > Automatic Updates: all off | `sudo systemctl disable --now unattended-upgrades` (Debian, Ubuntu) or `sudo systemctl disable --now dnf-automatic.timer` (Fedora); turn off automatic updates in the software center; `sudo snap refresh --hold` if you use snaps |
| Analytics and diagnostics | System Settings > Privacy & Security > Analytics & Improvements: all off. In Spotlight settings, turn off help improving search. Turn off assistant features you do not use | Settings > Privacy: problem reporting off; remove `popularity-contest` if installed |
| Location | Privacy & Security > Location Services off | Settings > Privacy > Location off |
| Network time | System Settings > General > Date & Time: set automatically off, or `sudo systemsetup -setusingnetworktime off` | `sudo timedatectl set-ntp false` |

With network time off, set the clock by hand and check it now and then. Some tools, such as WSJT-X for radio, need an accurate clock.

Check: `sudo systemsetup -getusingnetworktime` (macOS: "Network Time: Off"), `timedatectl` (Linux: "NTP service: inactive").

## 6. Firewall and radios (last, at the computer)

These cut networking, including any remote session you are using. Finish everything else first.

**Built-in firewall.** macOS: System Settings > Network > Firewall on, then Options: block all incoming connections and enable stealth mode. Terminal:

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

Linux with ufw (loopback traffic stays allowed):

```bash
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw enable
```

**Default-deny packet filter (macOS).** The application firewall only screens incoming connections. A packet-filter rule blocks traffic in both directions even if a radio is switched back on. Save this as `/etc/pf.ark.conf`:

```text
# Allow traffic inside this computer only; drop everything else.
set skip on lo0
block drop all
```

Load and enable it with `sudo pfctl -f /etc/pf.ark.conf` and `sudo pfctl -e`. To undo: `sudo pfctl -d`, then `sudo pfctl -f /etc/pf.conf`. A rule loaded this way lasts until the next restart; repeat the two commands after each restart, or start them from a LaunchDaemon. Operating-system updates can reset packet-filter settings, so check again after any update.

**Outbound firewall.** [LuLu](https://objective-see.org/products/lulu.html) (macOS) or [OpenSnitch](https://github.com/evilsocket/opensnitch) (Linux) shows any program that tries to connect, which is useful as a second layer.

**Radios.** Turn off Wi-Fi and Bluetooth (macOS: menu bar or System Settings; Terminal: `networksetup -listallhardwareports` to find the Wi-Fi device, then `networksetup -setairportpower <device> off`. Linux: `rfkill block all`). Remove saved Wi-Fi networks. Prefer a wired keyboard and mouse so Bluetooth can stay off. On computers with a replaceable wireless card (common in PCs with an M.2 slot), removing the card is the strongest option. Store the machine in a shielded (Faraday) bag when not in use.

**Accessories.** macOS Lockdown Mode (System Settings > Privacy & Security > Lockdown Mode; requires a restart) asks for approval before a new wired accessory can connect to a locked Mac and limits other attack surfaces. On Linux, [USBGuard](https://usbguard.github.io/) blocks USB devices you have not allowed.

Check:

```bash
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate   # macOS: enabled
/usr/libexec/ApplicationFirewall/socketfilterfw --getblockall      # macOS: block all enabled
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode   # macOS: stealth mode on
sudo systemsetup -getremotelogin     # macOS: "Remote Login: Off"
sudo pfctl -s info | head -1         # macOS: "Status: Enabled"
networksetup -getairportpower <device>   # macOS: "Off"
sudo ufw status verbose              # Linux: active; deny (incoming), deny (outgoing)
rfkill list                          # Linux: "Soft blocked: yes" for each radio
```

## 7. Tamper detection and malware scanning

**ClamAV.** Scan anything new before opening it, using the signatures saved in your archive if they are not installed system-wide:

```bash
clamscan -r -i /path/to/incoming
clamscan --database="$ARK_ROOT/software/clamav-db" -r -i /path/to/incoming
```

**AIDE.** Build a baseline of the places where unwanted software would hide, right after you finish setup, and compare against it on every trusted startup. A minimal configuration to adapt (older AIDE versions call `database_in` simply `database`; see `man aide.conf`):

```text
database_in=file:/path/to/aide/aide.db.gz
database_out=file:/path/to/aide/aide.db.new.gz
/Applications R
/Library/LaunchDaemons R
/Library/LaunchAgents R
/Users/YOU/Library/LaunchAgents R
/usr/local R
/opt/homebrew R
```

On Linux, watch locations such as `/etc`, `/usr/bin`, `/usr/sbin`, `/usr/local`, `/etc/systemd`, and `~/.config/autostart` instead. Create the baseline with `aide --init --config=aide.conf`, rename `aide.db.new.gz` to `aide.db.gz`, and keep a copy on read-only media. Then run `aide --check --config=aide.conf`. Investigate any change you did not make before trusting the machine; after a deliberate change, build a new baseline.

**YARA.** With saved rules such as signature-base, `yara -r <rules-file> /path/to/incoming` searches files for known malicious patterns. Some rule sets need extra variables; read their instructions while online.

## 8. Bringing files in

Every file format with a complex parser can carry an exploit: PDFs, office documents, images, audio, and video. Plain text is the safest format by a wide margin.

- [ ] Prefer one-way media: a memory card with its write-protect switch on, a write-once optical disc, or, for small text files, a screen-to-camera QR-code transfer tool you installed and tested before going offline. USB drives are the weakest option, because a USB device can pretend to be a keyboard.
- [ ] Where possible, receive files on a separate, disposable "quarantine" computer first. Scan them there, convert them to simpler formats, and only then carry the result to the offline machine.
- [ ] Convert risky documents with [Dangerzone](https://dangerzone.rocks/), which rebuilds them as plain-image PDFs. Remove metadata with [mat2](https://0xacab.org/jvoisin/mat2) or [ExifTool](https://exiftool.org/) (`exiftool -all= file`). Re-encode media with FFmpeg on the quarantine computer.
- [ ] Never run programs, installers, or scripts from downloaded archives, including the GitHub archive, which is reading material. Keep office macros disabled.
- [ ] When a local AI model reads untrusted text (web archives, incoming documents), give it no shell, file-writing, or network tools, and treat what it retrieves as information, not instructions.

## 9. Physical care

- [ ] Buy storage devices and cables new, from a shop, and use them only with this kit. Do not plug in found or gifted USB devices.
- [ ] Put tamper-evident seals over unused ports or case screws and photograph them, so you can tell whether they were disturbed.
- [ ] Keep a long-term copy on media suited to storage, such as a hard drive or archival optical disc. Solid-state drives left unpowered for long periods can lose data. Re-verify stored copies periodically (`restic check --read-data`, or the `.sha256` files the download scripts keep) and replace failing media.
- [ ] Keep the disk recovery key, firmware password, and backup password on paper, stored apart from the machine.

## 10. Final test

Run the read-only checks above, restart, and run them again. Then follow the offline acceptance test in the [build checklist](build-checklist.ai.md): a full day of normal use with networking off. Re-run these checks after any operating-system update, new application, or hardware change.

## Windows notes

Equivalent steps on Windows 10 and 11: turn on BitLocker or Device Encryption and save the recovery key on paper; enable Secure Boot and a firmware password; in Windows Security > Firewall & network protection, turn the firewall on for every profile and block all incoming connections; turn off Remote Desktop (Settings > System > Remote Desktop) and Remote Assistance (System Properties > Remote); turn off network discovery and file sharing; set diagnostic data to the minimum; use airplane mode and remove saved Wi-Fi networks. `netstat -ano | findstr LISTENING` lists listening ports. Windows Update can only be paused for a limited time, so plan around it once the machine is offline.
