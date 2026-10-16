<!-- ai-suggestion:unverified | date:2026-10-15 -->
# Ark software catalog

Choose one working tool per essential job before adding alternatives. These are projects to evaluate, not a promise that every version works on every platform. Use the publisher's instructions, obtain a compatible release, and complete the offline checks in the [build checklist](build-checklist.ai.md).

## Core tools

| Job | Projects or formats | What to save and test |
|---|---|---|
| Encyclopedia and reference library | [Kiwix](https://kiwix.org/en/) and ZIM collections | Reader, selected collections, licenses, diagrams, and local search |
| PDFs and ebooks | System PDF reader; [Calibre](https://calibre-ebook.com/) | Books, embedded images, fonts where needed, working reader |
| Office documents | [LibreOffice](https://www.libreoffice.org/) | Installer, dictionaries, fonts, representative document round trips |
| Notes | Plain text or Markdown in a local editor | Files and attachments in ordinary folders |
| Media playback | [VLC](https://www.videolan.org/vlc/) | Installer and sample media in the formats you use |
| Maps | [Organic Maps](https://organicmaps.app/); [QGIS](https://qgis.org/) for desktop GIS | Regions plus the actual viewer and, if needed, routing data |
| File collection | [rclone](https://rclone.org/) or official service exports | Only chosen sources; read access where supported; credentials kept privately |
| Versioned backup | [restic](https://restic.readthedocs.io/en/stable/) | Program for each recovery platform stored beside the encrypted repository, checksums, separate recovery instructions, tested restore |
| Video and audio conversion | [FFmpeg](https://ffmpeg.org/); [HandBrake](https://handbrake.fr/) | Working build and representative input/output files |
| Document conversion | [Pandoc](https://pandoc.org/) or LibreOffice | Any required PDF engine, templates, fonts, and a tested output |
| Image conversion and OCR | [ImageMagick](https://imagemagick.org/); [Tesseract](https://tesseract-ocr.github.io/) | Image support and selected OCR language data |

## Optional modules

| Module | Starting points | Additional preparation |
|---|---|---|
| Local language model | [llama.cpp](https://github.com/ggml-org/llama.cpp) | Compatible weights, model license, memory test, offline inference |
| Speech transcription | [whisper.cpp](https://github.com/ggml-org/whisper.cpp) | Model files and a short local recording for a test |
| Translation | [Argos Translate](https://www.argosopentech.com/) | Selected language packages and a test in each direction |
| Text-to-speech | A locally installed speech engine | Voice files and a spoken-output test |
| Image editing and illustration | [GIMP](https://www.gimp.org/), [Krita](https://krita.org/), [Inkscape](https://inkscape.org/) | Fonts, brushes, profiles, and sample exports |
| Photography | [darktable](https://www.darktable.org/) | Camera-format support, profiles, original files and exports |
| Audio editing | [Audacity](https://www.audacityteam.org/) | Plugins and a test recording/export |
| 3D and animation | [Blender](https://www.blender.org/) | Assets, add-ons, and a project that renders locally |
| CAD and fabrication | [FreeCAD](https://www.freecad.org/), [OpenSCAD](https://openscad.org/), [PrusaSlicer](https://www.prusa3d.com/page/prusaslicer_424/) | Libraries, machine profiles, and an export matched to your equipment |
| Electronics | [KiCad](https://www.kicad.org/), [ngspice](https://ngspice.sourceforge.io/), [Arduino IDE](https://www.arduino.cc/en/software/) | Parts libraries, board packages, drivers, compiler tools, and examples |
| Radio | [fldigi](https://www.w1hkj.org/), [WSJT-X](https://wsjt.sourceforge.io/wsjtx.html), [CHIRP](https://chirpmyradio.com/) | Supported radio, cables, drivers, and local operating requirements |
| Local mesh communication | [Meshtastic](https://meshtastic.org/) | Compatible hardware, firmware, and a tested local link |
| Astronomy | [Stellarium](https://stellarium.org/) | Needed catalogs and offline startup |
| Education | [Kolibri](https://learningequality.org/kolibri/), [Anki](https://apps.ankiweb.net/), [Scratch](https://scratch.mit.edu/download) | Selected learning content, decks, media, and projects |
| Dictionaries and units | Local dictionary files; [GNU Units](https://www.gnu.org/software/units/) | Languages and reference data |
| Entertainment | Locally playable media and games with an offline distribution | Required files, licenses, and startup without an account refresh |
| Development | Language runtimes, compiler toolchains, selected source repositories | Exact versions, source licenses, dependencies, build instructions, and documentation |

Local image generation and larger models can be added if resources permit. They are secondary to a complete reference library, readable documents, and recoverable backups.

## Download and conversion rules

Keep a private inventory using [the template](../examples/inventory.csv). Save the source URL, exact version, license, download date, bytes, and checksum. Do not fill it with guessed sizes or mark a tool tested before using it offline.

Archive selected dependencies rather than an arbitrary collection of repositories. A source checkout alone may lack build tools or packages needed to run it.

For proprietary creative projects, save original files and linked media, export an interchange format supported by both applications, and make a viewable reference render. Compare the imported project against that render; titles, effects, transitions, and plugins may not transfer. Keep both the editable source and the accessible result.

Only redistribute downloaded material when its license permits. The public Ark repository contains the plan and source links; your library stays in your private archive.
