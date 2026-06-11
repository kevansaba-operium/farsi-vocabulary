#!/usr/bin/env python3
"""
vision_extract.py – CLI helper for the agent-vision extraction workflow.

Commands:
    list          Show all PDFs that need vision extraction.
    mark-done SLUG  Mark a slug as 'reviewed' in the registry after you've
                    filled in content/extracted/<slug>.json.
    mark-reviewed SLUG  Alias for mark-done.

Usage:
    python3 tools/vision_extract.py list
    python3 tools/vision_extract.py mark-done lesson_03_2024_07_14

Workflow for each handwritten PDF:
  1. Open the rendered PNGs in content/pages/<slug>/
  2. Edit content/extracted/<slug>.json – fill in the entries array.
     Use the schema:
       {
         "id": "<slug>-NNNN",
         "farsi": "فارسی",
         "transliteration": "translit",
         "english": "meaning",
         "partOfSpeech": "noun|verb|adjective|expression|...",
         "notes": "",
         "examples": [],
         "imagePath": null,
         "tags": [],
         "source": { "file": "...", "lesson": N, "date": "YYYY-MM-DD", "page": P },
         "needsReview": false
       }
  3. Run: python3 tools/vision_extract.py mark-done <slug>
  4. Run: python3 tools/build_dataset.py  to regenerate the app's vocabulary.json
"""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).parent.parent
REGISTRY_PATH = Path(__file__).parent / "registry.json"
EXTRACTED_DIR = ROOT / "content" / "extracted"
PAGES_DIR = ROOT / "content" / "pages"


def load_registry() -> dict:
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    return {}


def save_registry(reg: dict) -> None:
    REGISTRY_PATH.write_text(
        json.dumps(reg, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def slug_to_filename(slug: str) -> str | None:
    reg = load_registry()
    for fname, rec in reg.items():
        clean = fname.lower().replace("-", "_").replace(".", "_").rstrip("_")
        stem = Path(fname).stem.lower().replace("-", "_")
        if stem == slug or clean.startswith(slug):
            return fname
    return None


def cmd_list():
    reg = load_registry()
    needs = [(f, r) for f, r in reg.items() if r.get("status") == "needs_vision"]
    if not needs:
        print("No PDFs pending vision extraction.")
        return
    print(f"{'File':<50} {'Pages':>5} {'Status'}")
    print("-" * 65)
    for fname, rec in sorted(needs):
        from pathlib import Path as P
        slug = P(fname).stem.lower().replace("-", "_")
        pages = rec.get("pageCount", "?")
        has_json = (EXTRACTED_DIR / f"{slug}.json").exists()
        has_pages = (PAGES_DIR / slug).exists()
        status = ""
        if not has_pages:
            status += "[pages missing - run extract.py] "
        if has_json:
            try:
                d = json.loads((EXTRACTED_DIR / f"{slug}.json").read_text())
                n = len(d.get("entries", []))
                status += f"[json exists, {n} entries]"
            except Exception:
                status += "[json exists but invalid]"
        else:
            status += "[no json yet]"
        print(f"{fname:<50} {str(pages):>5}  {status}")


def cmd_mark_done(slug: str):
    slug = slug.strip()
    reg = load_registry()

    # Find matching filename
    fname = None
    for f in reg:
        stem = Path(f).stem.lower().replace("-", "_")
        if stem == slug:
            fname = f
            break

    if not fname:
        print(f"Error: no registry entry found for slug '{slug}'")
        print("Available handwritten files:")
        for f in reg:
            if reg[f].get("status") in ("needs_vision", "drafted"):
                print(f"  {Path(f).stem.lower().replace('-', '_')}")
        sys.exit(1)

    # Validate the JSON file exists and has entries
    json_path = EXTRACTED_DIR / f"{slug}.json"
    if not json_path.exists():
        print(f"Error: {json_path} does not exist. Fill it in first.")
        sys.exit(1)

    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"Error: {json_path} is not valid JSON: {e}")
        sys.exit(1)

    entries = data.get("entries", [])
    if not entries:
        print(f"Warning: {json_path} has 0 entries. Marking as reviewed anyway.")

    reg[fname]["status"] = "reviewed"
    reg[fname]["entryCount"] = len(entries)
    reg[fname]["lastProcessed"] = datetime.utcnow().isoformat() + "Z"
    save_registry(reg)
    print(f"Marked '{fname}' as reviewed ({len(entries)} entries).")
    print("Run 'python3 tools/build_dataset.py' to update the app dataset.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1].lower()
    if cmd == "list":
        cmd_list()
    elif cmd in ("mark-done", "mark-reviewed"):
        if len(sys.argv) < 3:
            print(f"Usage: {sys.argv[0]} {cmd} <slug>")
            sys.exit(1)
        cmd_mark_done(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}")
        print("Commands: list, mark-done <slug>")
        sys.exit(1)


if __name__ == "__main__":
    main()
