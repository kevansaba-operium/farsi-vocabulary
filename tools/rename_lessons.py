#!/usr/bin/env python3
"""
rename_lessons.py – Unify all farsi_lessons/ filenames to Lesson_NN_YYYY-MM-DD.pdf.

Rules:
  - Lesson_01 through Lesson_24 are kept exactly as-is.
  - Every other file (Note_*, Lesson_X_*, Lesson_25_*) is sorted chronologically
    and assigned sequential numbers starting at 25.
  - True sha256 duplicates are identified; only the first occurrence is kept (and
    renamed), the duplicate gets a _DUPLICATE suffix so you can delete it manually.
  - All corresponding artefacts are updated:
      content/pages/<old_slug>/   → content/pages/<new_slug>/
      content/extracted/<old_slug>.json → content/extracted/<new_slug>.json
            (source.file field inside is patched too)
      tools/registry.json keys are re-keyed.

Usage:
    python3 tools/rename_lessons.py [--dry-run]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).parent.parent
LESSONS_DIR = ROOT / "farsi_lessons"
CONTENT_DIR = ROOT / "content"
EXTRACTED_DIR = CONTENT_DIR / "extracted"
PAGES_DIR = CONTENT_DIR / "pages"
REGISTRY_PATH = Path(__file__).parent / "registry.json"


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def slug_for(filename: str) -> str:
    stem = Path(filename).stem
    return re.sub(r"[^a-zA-Z0-9]", "_", stem).lower()


def extract_date(filename: str) -> str:
    """Pull the first YYYY-MM-DD from a filename, else '9999-99-99'."""
    m = re.search(r"(\d{4}-\d{2}-\d{2})", filename)
    return m.group(1) if m else "9999-99-99"


ALREADY_NUMBERED = re.compile(r"^Lesson_(\d{2})_\d{4}-\d{2}-\d{2}\.pdf$")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Print mapping only, do not rename.")
    args = parser.parse_args()
    dry = args.dry_run

    registry = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))

    all_pdfs = sorted(LESSONS_DIR.glob("*.pdf"))

    # Split: keep numbered vs. to-renumber
    to_renumber = []
    seen_hashes: dict[str, str] = {}  # sha256 → first filename

    for p in all_pdfs:
        if ALREADY_NUMBERED.match(p.name):
            # Already correct; track hash to detect duplicates
            h = sha256_of(p)
            seen_hashes[h] = p.name
            continue
        to_renumber.append(p)

    # Also track hashes of already-numbered files
    for p in all_pdfs:
        if ALREADY_NUMBERED.match(p.name):
            h = sha256_of(p)
            if h not in seen_hashes:
                seen_hashes[h] = p.name

    # Sort to-renumber by date, then name
    to_renumber.sort(key=lambda p: (extract_date(p.name), p.name))

    # Assign numbers starting at 25
    counter = 25
    mapping: list[tuple[Path, Path]] = []  # (old, new)
    duplicates: list[Path] = []

    for p in to_renumber:
        h = sha256_of(p)
        date = extract_date(p.name)
        if h in seen_hashes:
            # True duplicate
            duplicates.append(p)
            new_name = f"Lesson_DUPLICATE_{date}_{p.stem}.pdf"
            new_path = LESSONS_DIR / new_name
            print(f"  [DUPLICATE] {p.name} → {new_name} (same content as {seen_hashes[h]})")
            mapping.append((p, new_path))
        else:
            seen_hashes[h] = p.name
            new_name = f"Lesson_{counter:02d}_{date}.pdf"
            new_path = LESSONS_DIR / new_name
            print(f"  [RENAME]    {p.name} → {new_name}")
            mapping.append((p, new_path))
            counter += 1

    print(f"\n{len(mapping)} files to rename, {len(duplicates)} duplicates\n")

    if dry:
        print("Dry run – no changes made.")
        return

    # --- Perform renames ---

    # First pass: rename PDFs in farsi_lessons/ that won't collide with each other
    # Use two-step to avoid naming collisions (e.g. Note_X → Lesson_25 which already exists)
    tmp_paths: list[tuple[Path, Path]] = []  # (tmp, new)
    for old, new in mapping:
        tmp = old.with_name(f"__tmp__{old.name}")
        old.rename(tmp)
        tmp_paths.append((tmp, new))

    for tmp, new in tmp_paths:
        tmp.rename(new)

    # --- Update content artefacts ---

    for old, new in mapping:
        old_slug = slug_for(old.name)
        new_slug = slug_for(new.name)

        # Rename pages directory
        old_pages = PAGES_DIR / old_slug
        new_pages = PAGES_DIR / new_slug
        if old_pages.exists():
            if new_pages.exists():
                shutil.rmtree(new_pages)
            old_pages.rename(new_pages)
            print(f"  pages: {old_slug}/ → {new_slug}/")

        # Rename + patch extracted JSON
        old_json = EXTRACTED_DIR / f"{old_slug}.json"
        new_json = EXTRACTED_DIR / f"{new_slug}.json"
        if old_json.exists():
            try:
                data = json.loads(old_json.read_text(encoding="utf-8"))
                # Patch source.file and inside entries
                if "source" in data:
                    data["source"]["file"] = new.name
                for entry in data.get("entries", []):
                    src = entry.get("source", {})
                    if isinstance(src, dict):
                        src["file"] = new.name
                old_json.write_text(
                    json.dumps(data, ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
            except Exception as e:
                print(f"  Warning: could not patch {old_json}: {e}")
            old_json.rename(new_json)
            print(f"  extracted: {old_slug}.json → {new_slug}.json")

        # Re-key registry
        if old.name in registry:
            rec = registry.pop(old.name)
            registry[new.name] = rec
            print(f"  registry: {old.name} → {new.name}")

    # Save registry
    REGISTRY_PATH.write_text(
        json.dumps(registry, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    print("\nDone. Run 'python3 tools/extract.py' to refresh classifications.")


if __name__ == "__main__":
    main()
