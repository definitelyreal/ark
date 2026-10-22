<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Ark software catalog

Choose one working tool per essential job before adding alternatives. These are projects to evaluate, not a promise that every version works on every platform. Use the publisher's instructions, obtain a compatible release from the official source linked here, and complete the offline checks in the [build checklist](build-checklist.ai.md).

**Install and launch each application once while you are still online.** Many programs fetch plugins, language data, models, or license activation on first run, and cannot do it later. An application that has never been opened offline has not been tested.

Prefer free and open-source tools, or perpetual licenses with a documented offline story, over subscriptions and cloud-first services. On Apple Silicon, check that a directly downloaded app is not an Intel-only build (`file /Applications/App.app/Contents/MacOS/*` or `lipo -info`).

## Core tools

| Job | Projects or formats | What to save and test |
|---|---|---|
| Encyclopedia and reference library | [Kiwix](https://kiwix.org/en/) and ZIM collections; [kiwix-tools](https://github.com/kiwix/kiwix-tools) for `kiwix-serve` | Reader, selected collections, licenses, diagrams, and local search. `kiwix-serve` serves every ZIM as one local website |
| PDFs and ebooks | System PDF reader; [Calibre](https://calibre-ebook.com/); [Skim](https://skim-app.sourceforge.io/) on macOS | Books, embedded images, fonts where needed, working reader |
| Office documents | [LibreOffice](https://www.libreoffice.org/); [ONLYOFFICE](https://www.onlyoffice.com/) for closer Microsoft-format fidelity | Installer, dictionaries, fonts, representative document round trips |
| Notes | Plain text or Markdown in a local editor; [Obsidian](https://obsidian.md/) or [Joplin](https://joplinapp.org/) | Files and attachments in ordinary folders; plugins installed while online; cloud sync off |
| Research library | [Zotero](https://www.zotero.org/) | Library folder, attached PDFs, citation styles; cloud sync off |
| Passwords and one-time codes | [KeePassXC](https://keepassxc.org/) | The vault file, its built-in one-time-code support, and a master password stored separately |
| Media playback | [VLC](https://www.videolan.org/vlc/); [IINA](https://iina.io/) on macOS | Installer and sample media in the formats you use |
| Maps | [Organic Maps](https://organicmaps.app/) or [OsmAnd](https://osmand.net/) on a phone; [QGIS](https://qgis.org/) or [Marble](https://marble.kde.org/) on a computer | Regions plus the actual viewer and, if needed, routing data |
| Archives | [The Unarchiver](https://theunarchiver.com/) or [Keka](https://www.keka.io/) on macOS; [7-Zip](https://www.7-zip.org/) | Formats you expect to receive |
| File collection | [rclone](https://rclone.org/) or official service exports | Only chosen sources; read access where supported; credentials kept privately |
| Versioned backup | [restic](https://restic.readthedocs.io/en/stable/); [BorgBackup](https://www.borgbackup.org/) | Program for each recovery platform stored beside the encrypted repository, checksums, separate recovery instructions, tested restore |
| File and volume encryption | [age](https://github.com/FiloSottile/age); [Cryptomator](https://cryptomator.org/); [VeraCrypt](https://www.veracrypt.fr/) | A test container opened and closed offline; passwords stored separately |
| Video and audio conversion | [FFmpeg](https://ffmpeg.org/); [HandBrake](https://handbrake.fr/); [SoX](https://sourceforge.net/projects/sox/) | Working build and representative input/output files |
| Document conversion | [Pandoc](https://pandoc.org/), LibreOffice (`soffice --headless --convert-to`), or Calibre (`ebook-convert`) | Any required PDF engine, templates, fonts, and a tested output |
| Image conversion and OCR | [ImageMagick](https://imagemagick.org/); [Tesseract](https://tesseract-ocr.github.io/) with language data; [OCRmyPDF](https://ocrmypdf.readthedocs.io/) | Image support, selected OCR languages, and a scanned page made searchable |
| Structured data | [jq](https://jqlang.org/), [yq](https://github.com/mikefarah/yq), [XMLStarlet](https://xmlstar.sourceforge.net/), [csvkit](https://csvkit.readthedocs.io/) | Sample JSON, YAML, XML, and CSV processed offline |
| Downloads | curl; [aria2](https://aria2.github.io/); the Hugging Face [`hf` tool](https://huggingface.co/docs/huggingface_hub/guides/cli); on macOS, [Homebrew](https://brew.sh/) | Used by the [download scripts](download-scripts.ai.md); not needed once you are offline |

## Security and integrity

These support the [hardening checklist](hardening.ai.md). Install them while online and run each once.

| Job | Projects | What to save and test |
|---|---|---|
| Malware scanning | [ClamAV](https://www.clamav.net/) | Signature database refreshed just before going offline; note its date. Scan a folder offline |
| Pattern scanning | [YARA](https://virustotal.github.io/yara/) with rules such as [signature-base](https://github.com/Neo23x0/signature-base) | Rules saved locally; one test scan |
| Tamper detection | [AIDE](https://aide.github.io/) | A configuration, a baseline built at sealing time, and a check run afterwards |
| Signatures and checksums | [minisign](https://jedisct1.github.io/minisign/); [GnuPG](https://gnupg.org/); `shasum` or `sha256sum` | Public keys of projects you trust, obtained while online from a second source |
| Cleaning documents | [qpdf](https://qpdf.sourceforge.io/); [mat2](https://0xacab.org/jvoisin/mat2); [ExifTool](https://exiftool.org/) | A PDF rebuilt and its metadata removed; an image stripped of location data |
| Converting risky documents to safe PDFs | [Dangerzone](https://dangerzone.rocks/) | Confirm it works with networking off before relying on it |
| Outbound firewall | [LuLu](https://objective-see.org/products/lulu.html) on macOS; [OpenSnitch](https://github.com/evilsocket/opensnitch) on Linux | Rules that block everything you have not approved |
| USB device control | [USBGuard](https://usbguard.github.io/) on Linux; Lockdown Mode accessory approval on macOS | A new device is blocked until approved |
| Data recovery | [TestDisk and PhotoRec](https://www.cgsecurity.org/); [GNU ddrescue](https://www.gnu.org/software/ddrescue/) | Run on a spare card or drive so you know the steps |

## Optional modules

| Module | Starting points | Additional preparation |
|---|---|---|
| Local language model | [Ollama](https://ollama.com/); [llama.cpp](https://github.com/ggml-org/llama.cpp); [LM Studio](https://lmstudio.ai/) (free, closed source) | Compatible weights, model license, memory test, offline inference. Models are listed in the [download catalog](downloads.ai.md) |
| Speech transcription | [whisper.cpp](https://github.com/ggml-org/whisper.cpp); faster-whisper; [parakeet-mlx](https://github.com/senstella/parakeet-mlx) on Apple Silicon | Model files and a short local recording for a test |
| Translation | [Argos Translate](https://www.argosopentech.com/) | Selected language packages and a test in each direction |
| Text-to-speech | [Piper](https://github.com/OHF-Voice/piper1-gpl); [Kokoro](https://huggingface.co/hexgrad/Kokoro-82M); the system's built-in voices | Voice files and a spoken-output test |
| Local image generation and upscaling | [Draw Things](https://drawthings.ai/) on Apple devices; [Upscayl](https://upscayl.org/) | Models downloaded inside the app while online; one image generated offline |
| Image editing and illustration | [GIMP](https://www.gimp.org/), [Krita](https://krita.org/), [Inkscape](https://inkscape.org/) | Fonts, brushes, profiles, and sample exports |
| Photography | [darktable](https://www.darktable.org/), [RawTherapee](https://www.rawtherapee.com/) | Camera-format support, profiles, original files and exports |
| Audio editing and music | [Audacity](https://www.audacityteam.org/); [LMMS](https://lmms.io/); [Ardour](https://ardour.org/) | Plugins, sound libraries, and a test recording/export |
| Video editing | [DaVinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve) (free edition; the download asks for a registration form) | Archived installer; a project imported from interchange and rendered offline |
| Editorial interchange and subtitles | [OpenTimelineIO](https://opentimeline.io/); [Subtitle Edit](https://www.nikse.dk/subtitleedit); [Aegisub](https://aegisub.org/) | A real timeline converted and reopened; a subtitle file edited |
| Fonts | [FontForge](https://fontforge.org/); font collections from the [download catalog](downloads.ai.md) | Fonts installed and visible in your applications |
| 3D and animation | [Blender](https://www.blender.org/) | Assets, add-ons, and a project that renders locally |
| CAD and fabrication | [FreeCAD](https://www.freecad.org/), [OpenSCAD](https://openscad.org/), [PrusaSlicer](https://www.prusa3d.com/page/prusaslicer_424/) | Libraries, machine profiles, and an export matched to your equipment |
| Electronics | [KiCad](https://www.kicad.org/), [ngspice](https://ngspice.sourceforge.io/), [Arduino IDE](https://www.arduino.cc/en/software/) | Parts libraries, board packages, drivers, compiler tools, and examples |
| Radio | [fldigi](https://www.w1hkj.org/), [WSJT-X](https://wsjt.sourceforge.io/wsjtx.html), [CHIRP](https://chirpmyradio.com/), [Pat](https://getpat.io/) (Winlink, including peer-to-peer without the internet) | Supported radio, cables, drivers, and local operating requirements. WSJT-X needs an accurate clock |
| Software-defined radio receive | [Gqrx](https://www.gqrx.dk/), [SDR++](https://www.sdrpp.org/), [CubicSDR](https://github.com/cjcliffe/CubicSDR) | A supported receiver dongle and a test reception |
| Antenna modeling | [xnec2c](https://www.xnec2c.org/) | Example models that open offline |
| Local mesh communication | [Meshtastic](https://meshtastic.org/) | Compatible hardware, firmware flashed while online, region settings, and a tested local link |
| Astronomy and celestial navigation | [Stellarium](https://stellarium.org/); [Cartes du Ciel](https://www.ap-i.net/skychart/); [Skyfield](https://rhodesmill.org/skyfield/) | Extra star catalogs and the ephemeris file Skyfield needs, saved while online |
| Tides and weather files | [XTide](https://flaterco.com/xtide/); [XyGrib](https://opengribs.org/) | Harmonics data for XTide; weather files downloaded while online, since forecasts age quickly |
| Bird identification | [Merlin Bird ID](https://merlin.allaboutbirds.org/) | Regional packs downloaded in the app. Do not rely on apps for identifying edible plants or mushrooms; use printed field guides |
| Dictionaries and units | [GoldenDict-ng](https://xiaoyifang.github.io/goldendict-ng/) with [FreeDict](https://freedict.org/) dictionaries; [GNU Units](https://www.gnu.org/software/units/) | Languages and reference data |
| Education | [Kolibri](https://learningequality.org/kolibri/), [Anki](https://apps.ankiweb.net/), [Scratch](https://scratch.mit.edu/download), [Tux Paint](https://tuxpaint.org/), [Klavaro](https://klavaro.sourceforge.io/) | Selected learning content, decks, media, and projects |
| Local media library | [Jellyfin](https://jellyfin.org/) | Metadata fetched while online; playback tested offline |
| Entertainment and games | Locally playable media; DRM-free offline installers such as those from [GOG](https://www.gog.com/); [RetroArch](https://www.retroarch.com/); open-source games such as [0 A.D.](https://play0ad.com/), [OpenTTD](https://www.openttd.org/), [Battle for Wesnoth](https://www.wesnoth.org/), [Freeciv](https://www.freeciv.org/), [Luanti](https://www.luanti.org/), and [Cataclysm: DDA](https://cataclysmdda.org/) | Required files, licenses, and startup without an account refresh |
| Desktop routing | [Valhalla](https://github.com/valhalla/valhalla) or [GraphHopper](https://www.graphhopper.com/) built against your map data | A route calculated offline |
| Development | Language runtimes, compiler toolchains, selected source repositories | Exact versions, source licenses, dependencies, build instructions, and documentation |

Local image generation and larger models can be added if resources permit. They are secondary to a complete reference library, readable documents, and recoverable backups.

## Activation and account traps

Some software stops working, or cannot be installed, without a periodic connection. Check the publisher's current offline policy, and keep a tested alternative for anything essential.

| Kind of software | Risk offline | Alternative |
|---|---|---|
| Subscription creative suites | Periodic license checks; can stop opening projects | DaVinci Resolve, GIMP, Krita, Inkscape, Audacity; export open interchange while the license is active |
| Subscription office suites | Can become read-only after a period offline | LibreOffice, ONLYOFFICE, or a perpetual license |
| Game stores that require sign-in | Offline mode can expire | DRM-free offline installers and open-source games |
| Commercial antivirus with license checks | Stops updating or running | ClamAV and YARA |
| Subscription reference and medical apps | Content needs a live account | Static PDFs and Kiwix libraries such as WikEM |
| Plugins licensed through online accounts or dongle services | Periodic reconnection | Perpetual licenses with offline activation, or open alternatives |
| Cloud-first notes, documents, and media servers | Offline caches are not durable | Ordinary local files |
| Desktop AI apps advertised as local | Some still make network requests | Watch them with an outbound firewall before trusting them |
| Printers and slicers with cloud features | May depend on a vendor service | PrusaSlicer, with G-code moved by memory card |
| App store-only apps | Need an account sign-in to download | Install while online; keep what can be archived |

## Save installers for an offline reinstall

Keep the original installer files (`.dmg`, `.pkg`, `.exe`, `.deb`, `.rpm`, `.AppImage`) with the publisher's checksum or signature, and record the version. On macOS with Homebrew, `brew fetch` downloads packages into a folder you choose and checks each one against the SHA-256 recorded in Homebrew's package definition:

```bash
export HOMEBREW_CACHE="$ARK_ROOT/software/homebrew-cache"
brew fetch --cask libreoffice vlc kiwix keepassxc calibre
brew fetch --deps restic ffmpeg pandoc tesseract
```

On Debian or Ubuntu, `apt-get download <package>` saves `.deb` files to the current folder; on Fedora, `dnf download --resolve <package>` includes dependencies. Test an offline reinstall from what you saved before relying on it.

To check a macOS application's signature after installing: `codesign --verify --deep --strict /Applications/App.app` should print nothing, and `spctl --assess --type execute -vv /Applications/App.app` should report it as accepted and notarized. Linux distribution packages are checked against the distribution's signing keys by the package manager.

## Download and conversion rules

Keep a private inventory using [the template](../examples/inventory.csv). Save the source URL, exact version, license, download date, bytes, and checksum. Do not fill it with guessed sizes or mark a tool tested before using it offline.

Archive selected dependencies rather than an arbitrary collection of repositories. A source checkout alone may lack build tools or packages needed to run it.

For proprietary creative projects, save original files and linked media, export an interchange format supported by both applications, and make a viewable reference render. Compare the imported project against that render; titles, effects, transitions, and plugins may not transfer. Keep both the editable source and the accessible result. For example, editing timelines can often be exported as Final Cut Pro XML, AAF, or EDL for another editor to import; motion-graphics compositions usually have no interchange format, so render the ones you need to a high-quality intermediate such as ProRes or DNxHR. Fonts from a subscription service stop working when it lapses, so keep licensed font files or rebuild titles in open fonts.

Only redistribute downloaded material when its license permits. The public Ark repository contains the plan and source links; your library stays in your private archive.
