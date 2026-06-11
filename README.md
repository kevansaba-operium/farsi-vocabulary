# farsi-vocabulary

An offline Flutter app to learn Farsi vocabulary from your lesson PDFs — flashcards, quizzes, spaced repetition, and phonetic highlighting.

## Project objective

I'm trying to build a Flutter app I will be able to run on my Google Pixel phone or any phone for that matter to help me learn Farsi vocabulary.

My focus is mostly on:

- learning farsi vocabulary (nouns, verbs, expressions, idioms, etc.) and its english translation
- focusing on having proper pronunciations
  - in farsi, the "r", "kh", "gh" sounds are difficult for me and i'd love some visual to help spot them in words when they appear
  - the closed a or open a sound need to be easily to tell apart
- having images to help illustrate certain words to help me memorize them
- building small sentences to help me use these words in proper context

The learning material shall come mostly from my `/farsi_lessons` folder in the project root.
The app can be in English for now with no authentication and no cloud data storage — everything stored locally.

---

## How the app is built

### Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter (Material 3), Dart 3.3+ |
| State | [Riverpod](https://riverpod.dev) |
| Routing | [go_router](https://pub.dev/packages/go_router) |
| Local storage | [Hive](https://pub.dev/packages/hive) (SRS progress, user corrections) |
| Vocabulary data | Bundled JSON asset (`app/assets/data/vocabulary.json`) |

### Project layout

```
farsi-vocabulary/
├── app/                    # Flutter app
│   ├── lib/
│   │   ├── screens/        # Home, Browse, Flashcards, Quiz, SRS, Search, Settings
│   │   ├── providers/      # Vocabulary, SRS, corrections, settings
│   │   ├── models/         # VocabEntry, CardState, Correction
│   │   ├── widgets/        # PhoneticText, EntryCard, EditEntrySheet
│   │   └── utils/          # Phonetic highlighting (kh, gh, r, â, sh)
│   └── assets/data/        # vocabulary.json (generated — do not edit by hand)
├── content/
│   └── extracted/          # Per-lesson JSON extracted from PDFs
├── farsi_lessons/          # Source PDFs (gitignored — your private lesson files)
└── tools/                  # Python extraction & build pipeline
    ├── extract.py          # Parse typed PDFs → content/extracted/
    ├── vision_extract.py     # Helper for handwritten PDF workflow
    ├── build_dataset.py    # Merge extracted JSON → app vocabulary.json
    └── registry.json       # Tracks which PDFs have been processed
```

### Data pipeline

Lesson PDFs flow through a Python pipeline before the app can use them.

#### Incremental processing (`tools/registry.json`)

Each PDF is tracked so **only new or changed files are parsed**. You do not need to re-run extraction on the whole folder.

For every file in `farsi_lessons/`, `tools/registry.json` stores:

| Field | Meaning |
|-------|---------|
| `sha256` | Content hash — unchanged file → skipped |
| `status` | `needs_vision` (handwritten, JSON to fill) · `drafted` (typed, auto-parsed) · `reviewed` (transcription done) |
| `type` | `typed` or `handwritten` |
| `lastProcessed` | Last time this PDF was run through the pipeline |
| `entryCount` | Number of vocabulary entries in its extracted JSON |

When you run `extract.py`, unchanged files print `[skip] … (unchanged, status=…)` and are left alone. New PDFs or edited PDFs (different hash) print `[process] …`.

#### Steps

1. **Add PDFs** to `farsi_lessons/` (e.g. `Lesson_97_2026-06-10.pdf`).
2. **Extract** vocabulary (new/changed files only):
   ```bash
   pip install -r tools/requirements.txt
   python3 tools/extract.py
   ```
   Typed PDFs are parsed automatically into `content/extracted/<slug>.json`. Handwritten PDFs are rendered to PNGs in `content/pages/` and flagged for manual review.
3. **Review handwritten lessons** (if any): fill in `content/extracted/<slug>.json`, then:
   ```bash
   python3 tools/vision_extract.py mark-done <slug>
   ```
4. **Build the app dataset**:
   ```bash
   python3 tools/build_dataset.py
   ```
   This merges extracted entries into `app/assets/data/vocabulary.json`. Use `--include-needs-review` to include entries still flagged for review.

Re-run steps 2 and 4 whenever you add or update lesson PDFs.

**Useful flags:**

```bash
python3 tools/extract.py --file Lesson_97_2026-06-10.pdf   # one file only
python3 tools/extract.py --force                           # ignore registry, reprocess all
python3 tools/vision_extract.py list                       # handwritten PDFs still pending
```

### Phonetic highlighting

Transliteration and Farsi script are color-coded to make tricky sounds visible at a glance:

| Sound | Color | Example |
|-------|-------|---------|
| **kh** (خ) | Teal | guttural kh |
| **gh** (غ/ق) | Purple | voiced uvular |
| **r** (ر) | Orange | rolled r |
| **â / aa** (آ) | Blue | long open "a" |
| **sh** (ش) | Green | sh sound |

---

## How to use the app

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.3+)
- A connected device or emulator (Android, iOS, macOS, etc.)

### Run locally

```bash
cd app
flutter pub get
flutter run
```

To install on a physical Android phone (e.g. Google Pixel):

```bash
cd app
flutter run -d <device-id>    # flutter devices to list targets
# or build a release APK:
flutter build apk --release
```

### App features

**Home** — Word of the day, vocabulary stats, quick links to study modes, and recent lessons.

**Browse** — All lessons grouped by date. Tap a lesson to see its vocabulary entries, then open any word for full detail (Farsi, transliteration, English, examples, notes).

**Flashcards** — Flip through cards (all words or filtered to one lesson). Tap to reveal the translation.

**Quiz** — Multiple-choice questions to test recall.

**Review (SRS)** — Spaced repetition review. Rate each card after you flip it; the app schedules the next review based on your performance. Due cards show up on the home screen.

**Search** — Find words by Farsi, transliteration, or English.

**Settings** — Toggle transliteration direction (LTR / RTL).

**Edit / correct** — Tap the pencil icon on any entry to fix typos or improve translations. Corrections are saved locally on your device and override the bundled data.

### Typical workflow

1. After a Farsi lesson, drop the PDF into `farsi_lessons/`.
2. Run the extraction and build pipeline (see [Data pipeline](#data-pipeline)).
3. Hot-restart or rebuild the Flutter app to pick up the new `vocabulary.json`.
4. Browse the new lesson, then study with flashcards or add cards to your SRS queue via review.

Everything works offline — no account, no cloud sync.
