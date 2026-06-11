#!/usr/bin/env python3
"""
build_dataset.py – Merge all extracted/reviewed vocabulary JSON files into
app/assets/data/vocabulary.json.

Usage:
    python3 tools/build_dataset.py [--include-needs-review]

By default only entries where needsReview=false are included.
Pass --include-needs-review to include everything (useful during development).

Output JSON structure:
{
  "meta": {
    "generatedAt": "...",
    "totalEntries": N,
    "totalLessons": N,
    "sources": [...]
  },
  "entries": [ ... ],
  "lessons": [
    { "id": "lesson_03", "label": "Lesson 3", "date": "2024-07-14", "entryIds": [...] }
  ]
}
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).parent.parent
EXTRACTED_DIR = ROOT / "content" / "extracted"
REGISTRY_PATH = Path(__file__).parent / "registry.json"
OUT_DIR = ROOT / "app" / "assets" / "data"
OUT_PATH = OUT_DIR / "vocabulary.json"


def load_registry() -> dict:
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    return {}


def slug_for(filename: str) -> str:
    stem = Path(filename).stem
    return re.sub(r"[^a-zA-Z0-9]", "_", stem).lower()


def lesson_sort_key(source: dict) -> tuple:
    """Sort key: lessons first by number, then notes by date."""
    lesson_num = source.get("lesson")
    date = source.get("date") or "9999-99-99"
    fname = source.get("file", "")
    is_note = fname.lower().startswith("note_")
    # Lessons with explicit numbers come first, then X-lessons, then notes
    if lesson_num is not None:
        return (0, lesson_num, date)
    elif "lesson" in fname.lower():
        return (1, 999, date)
    else:
        return (2, 0, date)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--include-needs-review",
        action="store_true",
        help="Include entries marked needsReview=true",
    )
    args = parser.parse_args()

    registry = load_registry()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Load all extracted JSON files
    all_entries: list[dict] = []
    sources_included: list[str] = []

    json_files = sorted(EXTRACTED_DIR.glob("*.json"))
    for json_path in json_files:
        try:
            data = json.loads(json_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  Warning: could not read {json_path.name}: {e}")
            continue

        entries = data.get("entries", [])
        if not entries:
            continue

        source_file = data.get("source", {}).get("file", json_path.name)

        for entry in entries:
            if not args.include_needs_review and entry.get("needsReview", True):
                continue
            # Ensure required fields
            entry.setdefault("id", f"{json_path.stem}-????")
            entry.setdefault("farsi", "")
            entry.setdefault("transliteration", "")
            entry.setdefault("english", "")
            entry.setdefault("partOfSpeech", None)
            entry.setdefault("notes", "")
            # Sanitize: ensure all examples are dicts, not strings
            raw_examples = entry.get("examples", [])
            fixed_examples = []
            for ex in raw_examples:
                if isinstance(ex, str):
                    fixed_examples.append({"farsi": "", "transliteration": "", "english": ex})
                elif isinstance(ex, dict):
                    fixed_examples.append(ex)
            entry["examples"] = fixed_examples
            entry.setdefault("imagePath", None)
            entry.setdefault("tags", [])
            all_entries.append(entry)

        sources_included.append(source_file)

    # De-duplicate: if same farsi + english appears in multiple sources,
    # keep the one with more information (longer notes/examples),
    # but record all source files in a 'sources' list.
    seen: dict[str, dict] = {}
    dedup_entries: list[dict] = []

    for entry in all_entries:
        key = (
            entry.get("farsi", "").strip(),
            entry.get("english", "").strip().lower(),
        )
        if not key[0] and not key[1]:
            dedup_entries.append(entry)
            continue

        if key in seen:
            existing = seen[key]
            # Merge: prefer richer entry
            if len(entry.get("notes", "")) > len(existing.get("notes", "")):
                existing["notes"] = entry["notes"]
            existing["examples"].extend(
                e for e in entry.get("examples", []) if e not in existing["examples"]
            )
            # Track additional sources
            existing_sources = existing.setdefault("allSources", [existing.get("source", {})])
            if entry.get("source") and entry["source"] not in existing_sources:
                existing_sources.append(entry["source"])
        else:
            entry_copy = dict(entry)
            seen[key] = entry_copy
            dedup_entries.append(entry_copy)

    # Build lesson index
    lesson_map: dict[str, dict] = {}
    for entry in dedup_entries:
        src = entry.get("source", {})
        fname = src.get("file", "")
        slug = slug_for(fname) if fname else "unknown"
        lesson_num = src.get("lesson")
        date = src.get("date", "")

        if slug not in lesson_map:
            if lesson_num:
                label = f"Lesson {lesson_num}"
            elif fname.lower().startswith("note_") and date:
                label = f"Notes {date}"
            else:
                label = slug.replace("_", " ").title()

            lesson_map[slug] = {
                "id": slug,
                "label": label,
                "date": date,
                "file": fname,
                "entryIds": [],
                "_sort_key": lesson_sort_key(src),
            }
        lesson_map[slug]["entryIds"].append(entry["id"])

    lessons = sorted(lesson_map.values(), key=lambda x: x["_sort_key"])
    for lesson in lessons:
        del lesson["_sort_key"]

    dataset = {
        "meta": {
            "generatedAt": datetime.utcnow().isoformat() + "Z",
            "totalEntries": len(dedup_entries),
            "totalLessons": len(lessons),
            "sources": sources_included,
        },
        "entries": dedup_entries,
        "lessons": lessons,
    }

    OUT_PATH.write_text(
        json.dumps(dataset, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Count review stats
    n_review = sum(1 for e in dedup_entries if e.get("needsReview"))
    print(f"Wrote {len(dedup_entries)} entries ({n_review} need review) across {len(lessons)} lessons")
    print(f"Output: {OUT_PATH}")


if __name__ == "__main__":
    main()
