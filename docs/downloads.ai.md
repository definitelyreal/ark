<!-- ai-suggestion:unverified | date:2026-10-21 -->
# Ark download catalog

What to download for an offline kit, where each item comes from, roughly how big it is, and how to check that what you received is what the publisher released. The same items are listed, ready to run, in the [download script queues](../scripts/queues/); the [script guide](download-scripts.ai.md) explains how to run them. You can also download everything by hand from the sources below.

Sizes and edition dates were checked on 2026-10-21. Publishers release new editions regularly, so treat sizes as approximate. Each library, book, and model has its own license; this catalog points to them and grants no rights of its own.

## Tiers

Items are grouped so you can start small and add more. The scripts download only the **core** tier unless you ask for more with `ARK_TIERS="core optional"` or `ARK_TIERS="core optional giant"`.

| Tier | What it adds | Approximate size |
|---|---|---:|
| Core | Practical and medical references, English Wikipedia (text), a dictionary, public-domain manuals, a small local AI model set, speech-to-text models, malware signatures | 90 GB |
| Optional | Textbooks, more question-and-answer archives, Project Gutenberg subject collections, larger AI models, voices, OCR, image generation, fonts, source code | 215 GB more |
| Giant | Wikipedia with images, large language models as GGUF files, an archive of popular GitHub repositories | 345 GB more, plus the GitHub archive |

Leave room on top of this: the scripts stop before free space drops below `ARK_MIN_FREE_GB` (20 GB by default), and the build plan suggests keeping about 20% of a working drive free.

## How each kind of item is verified

A checksum proves the file you have is the file the server offered. It does not prove the server is honest. For anything you will rely on heavily, compare against a checksum or signature from a second place, such as a different mirror, the project's own release page, or a signed checksum list.

| Source | What the publisher provides | What the scripts do | How to check by hand |
|---|---|---|---|
| Kiwix libraries (`.zim`) | A `.sha256` file beside every ZIM, and a `.meta4` metalink with per-piece hashes | Download from several mirrors, checking pieces as they arrive, then compare the whole file with the published SHA-256 | `shasum -a 256 -c name.zim.sha256` (macOS) or `sha256sum -c name.zim.sha256` (Linux) |
| OpenStreetMap extracts (Geofabrik) | An `.md5` file beside each extract | Compare with the published MD5 | `md5 -q file.osm.pbf` or `md5sum file.osm.pbf` |
| Ollama models | Every layer is named by its SHA-256 digest | Ollama checks each layer while pulling; the helper then re-hashes every layer file against its name | `shasum -a 256 blobs/sha256-<digest>` prints the digest in the file name |
| Hugging Face files | The Hub lists a SHA-256 for every large file and a git hash for every small file | Pin the repository to one commit, download, then re-hash every file against the Hub's list | Compare `shasum -a 256 file` with the SHA-256 shown on the file's page |
| Git repositories | Every object is named by its hash | Git computes each hash as it receives the data; the lane records the HEAD commit and runs `git fsck` | Compare `git rev-parse HEAD` with the commit shown on the project's page |
| ClamAV signatures | Digitally signed database files | `sigtool --info` must report "Verification OK" for every file | `sigtool --info=daily.cvd` |
| Public-domain PDFs | Usually nothing | Record a SHA-256 when downloaded and confirm the file is a PDF | Open it and spot-check pages; sanitize before use (see the [hardening checklist](hardening.ai.md)) |
| Operating-system images | macOS: SHA-256 values listed on [ipsw.me](https://ipsw.me/), independent of Apple's download server. Linux: a signed `SHA256SUMS` file | Compare with the value you enter in the queue | Follow your distribution's guide, for example [Debian](https://www.debian.org/CD/verify) or [Ubuntu](https://ubuntu.com/tutorials/how-to-verify-ubuntu) |

The scripts keep a `.sha256` or `.md5` file next to each verified download, so you can re-check the archive later without a network connection.

## Core

### Reference libraries (Kiwix)

Read these in the [Kiwix](https://kiwix.org/en/) app, or serve them all at once with `kiwix-serve` from [kiwix-tools](https://github.com/kiwix/kiwix-tools). Each file comes from `https://download.kiwix.org/zim/<category>/`; the scripts pick the newest edition.

| Library | Edition checked | Size (GB) |
|---|---|---:|
| English Wikipedia, text only (`wikipedia_en_all_nopic`) | 2026-06 | 52.69 |
| Wiktionary, text only (`wiktionary_en_all_nopic`) | 2026-08 | 9.16 |
| iFixit repair guides (`ifixit_en_all`) | 2025-12 | 3.57 |
| Ready.gov preparedness guidance (`www.ready.gov_en`) | 2024-12 | 2.43 |
| WikiProjectMed medical encyclopedia (`mdwiki_en_all_maxi`) | 2025-11 | 2.30 |
| Home improvement Q&A (`diy.stackexchange.com_en_all`) | 2026-10 | 2.09 |
| LibreTexts medicine (`libretexts.org_en_med`) | 2025-01 | 1.19 |
| Wikivoyage travel guide (`wikivoyage_en_all_maxi`) | 2026-09 | 1.07 |
| Gardening Q&A (`gardening.stackexchange.com_en_all`) | 2026-10 | 0.93 |
| Energypedia renewable energy (`energypedia_en_all_maxi`) | 2026-06 | 0.80 |
| Post-disaster resources (`zimgit-post-disaster_en`) | 2024-05 | 0.64 |
| Appropedia appropriate technology (`appropedia_en_all_maxi`) | 2026-02 | 0.58 |
| WikEM emergency medicine (`wikem_en_all_maxi`) | 2026-07 | 0.37 |
| Outdoors Q&A (`outdoors.stackexchange.com_en_all`) | 2026-10 | 0.14 |
| Food preparation (`zimgit-food-preparation_en`) | 2025-04 | 0.10 |
| Medical reference collection (`zimgit-medicine_en`) | 2024-08 | 0.07 |
| Knots (`zimgit-knots_en`) | 2024-08 | 0.03 |
| Water collection and treatment (`zimgit-water_en`) | 2024-08 | 0.02 |
| **Total** | | **78.2** |

### Public-domain and freely published PDFs

No publisher checksums exist for these, so the scripts record a SHA-256 when each arrives. Most are US government works; the rest are published free by their authors.

| Title | Source | Size (MB) |
|---|---|---:|
| Emergency War Surgery, 5th US revision | [archive.org](https://archive.org/download/ews5man-mil/ews5man.pdf) | 30.4 |
| US Navy Seabee Combat Handbook, vol. 1 | [archive.org](https://archive.org/download/milmanual-seabee-combat-handbook-volume-1/seabee_combat_handbook_volume_1.pdf) | 26.5 |
| US Army ST 31-91B Special Forces Medical Handbook | [archive.org](https://archive.org/download/milmanual-st-31-91b--us-army-special-forces-medical-handbook/st_31-91b-_us_army_special_forces_medical_handbook.pdf) | 21.0 |
| US Army FM 3-05.70 Survival | [archive.org](https://archive.org/download/fm-3-05.70-survival-2002/FM%203-05.70%20Survival%20%202002.pdf) | 21.0 |
| US Army FM 31-70 Basic Cold Weather Manual | [archive.org](https://archive.org/download/milmanual-fm-31-70-basic-cold-weather-survival-manual/fm_31-70_basic_cold_weather_survival_manual.pdf) | 18.3 |
| US Army FM 5-426 Carpentry | [archive.org](https://archive.org/download/FM5-426/FM5-426.pdf) | 4.6 |
| WHO and ICRC Basic Emergency Care | [who.int](https://hlh.who.int/docs/librariesprovider4/hlh-documents/who-icrc-basic-emergency-care.pdf) | 4.3 |
| US Army FM 21-10 Field Hygiene and Sanitation | [archive.org](https://archive.org/download/FM21-10_2000/FM21-10_2000.pdf) | 2.9 |
| US Army FM 4-25.11 First Aid | [archive.org](https://archive.org/download/FM4-25.11/FM4-25.11.pdf) | 2.5 |
| Peace Corps wells construction manual | [govinfo.gov](https://www.govinfo.gov/content/pkg/GOVPUB-PE1-PURL-gpo174254/pdf/GOVPUB-PE1-PURL-gpo174254.pdf) | 1.5 |
| US EPA emergency disinfection of drinking water | [epa.gov](https://www.epa.gov/sites/default/files/2017-09/documents/emergency_disinfection_of_drinking_water_sept2017.pdf) | 0.8 |
| USDA Complete Guide to Home Canning, introduction | [nchfp.uga.edu](https://nchfp.uga.edu/papers/guide/INTRO_HomeCanrev0715.pdf) | 0.5 |

Worth adding by hand from the publishers, who offer free digital editions: the [Hesperian](https://hesperian.org/) health guides (including *Where There Is No Doctor* and *Where There Is No Dentist*), and the WHO [Guidelines for drinking-water quality](https://www.who.int/publications/i/item/9789240045064). Prefer the publisher's own copy over a re-upload, and record the edition.

### Local AI (Ollama)

Models from the [Ollama library](https://ollama.com/library), run with [Ollama](https://ollama.com/). Sizes are what the registry served in 2026; a newer build of the same name can differ slightly.

| Model | Use | Size (GB) |
|---|---|---:|
| `qwen3-vl:8b` | Reads images as well as text | 6.14 |
| `qwen3:4b` | Small, fast general model | 2.50 |
| `nomic-embed-text` | Text embeddings for local search | 0.27 |

### Speech to text (Hugging Face)

Model files for [whisper.cpp](https://github.com/ggml-org/whisper.cpp), from [ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp) (MIT license).

| File | Use | Size (GB) |
|---|---|---:|
| `ggml-large-v3-turbo.bin` | Multilingual transcription, good speed | 1.62 |
| `ggml-base.en.bin` | Small English model for slower machines | 0.15 |

### Malware signatures

The [ClamAV](https://www.clamav.net/) signature database, about 0.4 GB, fetched with `freshclam` into the archive so you can scan incoming files offline. Refresh it once more just before you take the machine offline; signatures are frozen from then on.

## Optional

### More reference libraries and books (Kiwix)

| Library | Edition checked | Size (GB) |
|---|---|---:|
| Project Gutenberg: science (`gutenberg_en_lcc-q`) | 2026-03 | 17.72 |
| Project Gutenberg: technology (`gutenberg_en_lcc-t`) | 2026-03 | 13.15 |
| US Army publications site archive (`armypubs_en_all`) | 2024-12 | 8.23 |
| Project Gutenberg: agriculture (`gutenberg_en_lcc-s`) | 2026-03 | 4.53 |
| LibreTexts humanities (`libretexts.org_en_human`) | 2026-07 | 4.43 |
| Computer Q&A (`superuser.com_en_all`) | 2026-10 | 4.01 |
| Wikisource public-domain texts, text only (`wikisource_en_all_nopic`) | 2026-09 | 3.91 |
| Wikibooks open textbooks, text only (`wikibooks_en_all_nopic`) | 2026-04 | 3.51 |
| Ubuntu Q&A (`askubuntu.com_en_all`) | 2026-06 | 2.77 |
| LibreTexts biology (`libretexts.org_en_bio`) | 2025-01 | 2.24 |
| LibreTexts chemistry (`libretexts.org_en_chem`) | 2025-01 | 2.18 |
| LibreTexts social sciences (`libretexts.org_en_socialsci`) | 2025-01 | 2.05 |
| Project Gutenberg: medicine (`gutenberg_en_lcc-r`) | 2026-03 | 2.02 |
| Wikiversity, text only (`wikiversity_en_all_nopic`) | 2026-08 | 1.63 |
| TruePrepper preparedness site archive (`trueprepper.com_en_all`) | 2026-05 | 1.42 |
| LibreTexts geosciences (`libretexts.org_en_geo`) | 2026-01 | 1.19 |
| LibreTexts business (`libretexts.org_en_biz`) | 2026-01 | 0.84 |
| LibreTexts mathematics (`libretexts.org_en_math`) | 2026-01 | 0.83 |
| LibreTexts engineering (`libretexts.org_en_eng`) | 2025-01 | 0.68 |
| LibreTexts physics (`libretexts.org_en_phys`) | 2026-01 | 0.56 |
| LibreTexts workforce and trades (`libretexts.org_en_workforce`) | 2026-01 | 0.51 |
| Information security Q&A (`security.stackexchange.com_en_all`) | 2026-10 | 0.44 |
| The World Factbook (`theworldfactbook_en_all`) | 2026-02 | 0.41 |
| LibreTexts statistics (`libretexts.org_en_stats`) | 2026-01 | 0.22 |
| **Total** | | **79.5** |

One optional PDF is also in the queue: the ARRL ARES Field Resources Manual (amateur radio emergency service, 0.9 MB). Regional field guides, such as edible-plant and foraging guides from forestry and agriculture agencies, are worth adding for your own area; add a row to `files.tsv` for each.

### Larger local AI models (Ollama)

| Model | Use | Size (GB) |
|---|---|---:|
| `qwen3.6:35b-a3b` | Mixture-of-experts general model | 23.94 |
| `qwen3-coder:30b` | Coding | 18.56 |
| `gemma4:26b` | General model from a second publisher | 17.99 |
| `qwen3.6:27b` | General and reasoning model | 17.42 |
| `gpt-oss:20b` | General model; needs about 16 GB of memory | 13.79 |
| `bge-m3` | Multilingual embeddings | 1.16 |
| `qwen3-embedding:0.6b` | Embeddings | 0.64 |
| **Total** | | **93.5** |

A model needs roughly its file size in free memory, plus working room. Test each one on your own computer while still online.

### Speech, voices, OCR, embeddings, and image generation (Hugging Face)

Licenses are as each repository declares them; read the model card before relying on one.

| Item | Repository | License | Size (GB) |
|---|---|---|---:|
| Whisper large-v3 for whisper.cpp | [ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp) | MIT | 3.10 |
| Distil-Whisper large-v3 for whisper.cpp | [distil-whisper/distil-large-v3-ggml](https://huggingface.co/distil-whisper/distil-large-v3-ggml) | MIT | 1.52 |
| faster-whisper large-v3 | [Systran/faster-whisper-large-v3](https://huggingface.co/Systran/faster-whisper-large-v3) | MIT | 3.09 |
| faster-whisper large-v3-turbo | [mobiuslabsgmbh/faster-whisper-large-v3-turbo](https://huggingface.co/mobiuslabsgmbh/faster-whisper-large-v3-turbo) | MIT | 1.62 |
| faster-whisper distil large-v3 | [Systran/faster-distil-whisper-large-v3](https://huggingface.co/Systran/faster-distil-whisper-large-v3) | MIT | 1.52 |
| faster-whisper medium.en | [Systran/faster-whisper-medium.en](https://huggingface.co/Systran/faster-whisper-medium.en) | MIT | 1.53 |
| faster-whisper small | [Systran/faster-whisper-small](https://huggingface.co/Systran/faster-whisper-small) | MIT | 0.49 |
| Parakeet TDT 0.6B v3 for Apple Silicon | [mlx-community/parakeet-tdt-0.6b-v3](https://huggingface.co/mlx-community/parakeet-tdt-0.6b-v3) | CC BY 4.0 | 2.51 |
| Parakeet TDT 0.6B v3 as ONNX | [istupakov/parakeet-tdt-0.6b-v3-onnx](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx) | CC BY 4.0 | 3.22 |
| Kokoro text to speech | [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) | Apache 2.0 | 0.36 |
| Kokoro for Apple Silicon (MLX) | [prince-canuma/Kokoro-82M](https://huggingface.co/prince-canuma/Kokoro-82M) | Apache 2.0 | 0.39 |
| One Piper voice (US English, "lessac", medium) | [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices) | MIT repository; each voice has its own model card | 0.06 |
| Surya OCR | [datalab-to/surya-ocr-2-gguf](https://huggingface.co/datalab-to/surya-ocr-2-gguf) | OpenRAIL (has use restrictions) | 1.50 |
| all-MiniLM-L6-v2 sentence embeddings | [sentence-transformers/all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) | Apache 2.0 | 0.09 |
| FLUX.1 schnell, 4-bit GGUF | [city96/FLUX.1-schnell-gguf](https://huggingface.co/city96/FLUX.1-schnell-gguf) | Apache 2.0 | 6.78 |
| T5 text encoder for FLUX, 8-bit GGUF | [city96/t5-v1_1-xxl-encoder-gguf](https://huggingface.co/city96/t5-v1_1-xxl-encoder-gguf) | Apache 2.0 | 5.06 |
| CLIP-L text encoder for FLUX | [comfyanonymous/flux_text_encoders](https://huggingface.co/comfyanonymous/flux_text_encoders) | Apache 2.0 | 0.25 |
| Stable Diffusion XL base 1.0 | [stabilityai/stable-diffusion-xl-base-1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) | CreativeML Open RAIL++-M | 6.94 |
| **Total** | | | **40.0** |

FLUX also needs its image decoder (`ae.safetensors`), published in [black-forest-labs/FLUX.1-schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell). That repository asks you to sign in and accept its terms, so the scripts skip it; download it yourself with your own account if you want FLUX.

### Fonts, icons, scanning rules, and source code (git)

| Repository | Use | Size |
|---|---|---:|
| [google/fonts](https://github.com/google/fonts) | Open-licensed font collection | about 3 GB |
| [FortAwesome/Font-Awesome](https://github.com/FortAwesome/Font-Awesome) | Free icon set | about 0.1 GB |
| [lucide-icons/lucide](https://github.com/lucide-icons/lucide) | Icon set | under 0.1 GB |
| [Neo23x0/signature-base](https://github.com/Neo23x0/signature-base) | YARA rules for scanning files | small |
| [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp) | Source to rebuild whisper.cpp offline | small |
| [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) | Source to rebuild llama.cpp offline | small |

Source code alone is not enough to rebuild a program: also keep the compiler, build tools, and libraries it needs, and test a build offline.

### Not in the queues, but worth considering

| Item | Where | Notes |
|---|---|---|
| OpenStreetMap data for your region | [Geofabrik](https://download.geofabrik.de/) | Continents run to tens of GB; a country or state is often under a few GB. An `.md5` is published beside each file. A commented example is in `files.tsv`. |
| Phone maps | [Organic Maps](https://organicmaps.app/) or [OsmAnd](https://osmand.net/) | Download regions inside the app while online, then test search and routing in airplane mode. |
| US topographic maps | [The National Map downloader](https://apps.nationalmap.gov/downloader/) | Public-domain GeoPDFs; open in a PDF reader or QGIS. |
| Learning content | [Kolibri](https://learningequality.org/kolibri/) | Import only the channels and subjects you need, inside Kolibri, while online. |
| Translation packages | [Argos Translate package index](https://www.argosopentech.com/argospm/index/) | Download each language pair you need and test both directions. |
| Dictionaries | [FreeDict](https://freedict.org/) with [GoldenDict-ng](https://xiaoyifang.github.io/goldendict-ng/) | Bilingual dictionaries for offline lookup. |
| Pre-industrial how-to library | [Survivor Library](https://www.survivorlibrary.com/) | Very large (over 200 GB); select the categories you want. |
| Application installers | Each project's own site, or `brew fetch` into the archive | See "Save installers" in the [software catalog](software.ai.md). |

## Giant

| Item | Source | License | Size (GB) |
|---|---|---|---:|
| English Wikipedia with images (`wikipedia_en_all_maxi`, edition 2026-08) | [Kiwix](https://download.kiwix.org/zim/wikipedia/) | CC BY-SA (Wikipedia) | 127.42 |
| GPT-OSS 120B, Q4_K_M GGUF | [unsloth/gpt-oss-120b-GGUF](https://huggingface.co/unsloth/gpt-oss-120b-GGUF) | Apache 2.0 | 62.77 |
| Qwen3-Coder-Next, UD-Q4_K_XL GGUF | [unsloth/Qwen3-Coder-Next-GGUF](https://huggingface.co/unsloth/Qwen3-Coder-Next-GGUF) | Apache 2.0 | 49.61 |
| Llama 3.3 70B Instruct, Q4_K_M GGUF | [unsloth/Llama-3.3-70B-Instruct-GGUF](https://huggingface.co/unsloth/Llama-3.3-70B-Instruct-GGUF) | Llama 3.3 Community License | 42.52 |
| Qwen3.6 35B-A3B, UD-Q4_K_XL GGUF with vision | [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) | Apache 2.0 | 23.26 |
| Gemma 4 31B instruct, UD-Q4_K_XL GGUF with vision | [unsloth/gemma-4-31b-it-GGUF](https://huggingface.co/unsloth/gemma-4-31b-it-GGUF) | Apache 2.0 | 20.02 |
| Qwen3.8 27B, UD-Q4_K_XL GGUF with vision | [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF) | Apache 2.0 | 18.49 |
| **Total** | | | **344.1** |

The GGUF files run in [llama.cpp](https://github.com/ggml-org/llama.cpp) or [LM Studio](https://lmstudio.ai/) on machines with enough memory; most need 32 GB or more, and the largest need far more or a GPU.

**GitHub archive.** `ARK_GITHUB_TOP=1000` clones the newest commit of the most-starred GitHub repositories, as reading material. Expect well over 100 GB for 1,000 repositories; the lane checks free space before each one and stops at your limit. Never run code from this archive.

**Full-precision frontier models** are not in the queues. Examples are [moonshotai/Kimi-K3](https://huggingface.co/moonshotai/Kimi-K3) (about 1,561 GB) and [deepseek-ai/DeepSeek-V4-Pro-0813](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro-0813) (about 893 GB). They need a dedicated multi-terabyte drive and far more memory than a laptop has; add a row to `huggingface.tsv` only if you have both.

## Record what you keep

Copy each finished item into your private inventory (start from the [inventory template](../examples/inventory.csv)): source URL, edition or commit, license, download date, bytes, and checksum. The scripts' state log (`catalog/downloads/state.tsv` on your archive) holds most of this already.
