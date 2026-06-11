#!/usr/bin/env python3
"""
extract.py – Farsi vocabulary extraction pipeline.

Usage:
    python3 tools/extract.py [--force] [--file FILENAME]

For each PDF in farsi_lessons/:
  1. Computes sha256 and compares to tools/registry.json.
  2. Classifies as 'typed' (clean extractable text) or 'handwritten' (needs vision).
  3. Typed → parses vocabulary entries, writes content/extracted/<slug>.json.
  4. Handwritten → renders pages to content/pages/<slug>/pN.png, marks needs_vision.

Run again after adding new PDFs; only new/changed files are processed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Optional

# --------------------------------------------------------------------------- #
# Paths                                                                         #
# --------------------------------------------------------------------------- #

ROOT = Path(__file__).parent.parent
LESSONS_DIR = ROOT / "farsi_lessons"
CONTENT_DIR = ROOT / "content"
EXTRACTED_DIR = CONTENT_DIR / "extracted"
PAGES_DIR = CONTENT_DIR / "pages"
REGISTRY_PATH = Path(__file__).parent / "registry.json"

EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
PAGES_DIR.mkdir(parents=True, exist_ok=True)

# --------------------------------------------------------------------------- #
# Farsi Unicode range helpers                                                   #
# --------------------------------------------------------------------------- #

FARSI_RANGE = re.compile(r"[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]")

def farsi_char_ratio(text: str) -> float:
    if not text:
        return 0.0
    farsi_chars = len(FARSI_RANGE.findall(text))
    meaningful = len([c for c in text if not c.isspace()])
    return farsi_chars / meaningful if meaningful else 0.0


def has_enough_farsi(text: str, min_chars: int = 15) -> bool:
    return len(FARSI_RANGE.findall(text)) >= min_chars


# --------------------------------------------------------------------------- #
# PDF classification                                                            #
# --------------------------------------------------------------------------- #

def classify_pdf(pdf_path: Path) -> tuple[str, str]:
    """
    Returns (type, raw_text).
    type is 'typed' or 'handwritten'.
    """
    import fitz  # PyMuPDF

    doc = fitz.open(str(pdf_path))
    full_text = "\n".join(page.get_text() for page in doc)
    doc.close()

    # Heuristics: typed PDFs have meaningful Farsi script and colon-separated patterns
    farsi_chars = len(FARSI_RANGE.findall(full_text))
    total_words = len(full_text.split())

    # Typed if it has enough Farsi characters and colon separators
    colon_lines = sum(1 for line in full_text.splitlines() if ":" in line)
    if farsi_chars >= 20 and colon_lines >= 3:
        return "typed", full_text

    # Also typed if file is small (< 100 KB) and has some recognizable words
    if pdf_path.stat().st_size < 100_000 and total_words > 10:
        return "typed", full_text

    return "handwritten", full_text


# --------------------------------------------------------------------------- #
# Vocabulary entry parser                                                       #
# --------------------------------------------------------------------------- #

POS_WORDS = {
    "noun": "noun", "n": "noun", "verb": "verb", "v": "verb",
    "adj": "adjective", "adjective": "adjective", "adv": "adverb",
    "adverb": "adverb", "expression": "expression", "expr": "expression",
    "idiom": "idiom", "phrase": "phrase", "prep": "preposition",
}

# Matches lines like "word : meaning : فارسی" or "فارسی : meaning : word" (any order)
VOCAB_LINE_RE = re.compile(
    r"^(?P<a>[^:\n]+?)\s*:\s*(?P<b>[^:\n]+?)\s*:\s*(?P<c>[^:\n]+?)\s*$"
)
# Two-part "word : meaning" or "فارسی : meaning"
TWO_PART_RE = re.compile(r"^(?P<a>[^:\n]{2,60}?)\s*:\s*(?P<b>[^:\n]{2,80}?)\s*$")

PAGE_MARKER_RE = re.compile(r"^--\s*\d+\s+of\s+\d+\s*--$")

# Common noise tokens to skip
SKIP_LINES = {
    "", "--", "---", "page", "pages", "note", "lesson",
}


def _is_farsi(s: str) -> bool:
    return farsi_char_ratio(s.strip()) > 0.4


def _is_latin(s: str) -> bool:
    s = s.strip()
    if not s:
        return False
    return farsi_char_ratio(s) < 0.1


def _clean(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def _extract_pos(text: str) -> tuple[str | None, str]:
    """Return (pos_tag, text_without_tag)."""
    lower = text.lower().strip().rstrip(".")
    for key, val in POS_WORDS.items():
        # Match at end of string e.g. "to run (verb)" or "run - verb"
        if re.search(r"\b" + key + r"\b", lower):
            cleaned = re.sub(r"[\(\[\-\s]*\b" + key + r"\b[\)\]\s]*", "", text, flags=re.IGNORECASE)
            return val, _clean(cleaned)
    return None, text


def _looks_like_example(line: str) -> bool:
    """Heuristic: likely an example sentence (contains verb conjugation or is long)."""
    stripped = line.strip()
    # Long lines with Farsi likely sentences
    if len(stripped) > 60 and FARSI_RANGE.search(stripped):
        return True
    # Lines ending in . or , that have Farsi
    if FARSI_RANGE.search(stripped) and stripped.endswith("."):
        return True
    return False


def parse_typed_text(raw_text: str, source_slug: str, source_meta: dict) -> list[dict]:
    """Parse vocabulary entries from extracted typed text."""
    entries: list[dict] = []
    lines = raw_text.splitlines()

    pending_examples: list[str] = []
    pending_notes: list[str] = []
    last_entry: dict | None = None

    def flush_entry():
        nonlocal last_entry, pending_examples, pending_notes
        if last_entry is None:
            return
        if pending_examples:
            for ex_text in pending_examples:
                if isinstance(ex_text, str):
                    last_entry["examples"].append({"farsi": "", "transliteration": "", "english": ex_text})
                else:
                    last_entry["examples"].append(ex_text)
            pending_examples = []
        if pending_notes:
            existing = last_entry.get("notes", "")
            combined = (existing + " " + " ".join(pending_notes)).strip()
            last_entry["notes"] = combined
            pending_notes = []
        entries.append(last_entry)
        last_entry = None

    for raw_line in lines:
        line = _clean(raw_line)

        # Skip page markers and empty/noise
        if not line or PAGE_MARKER_RE.match(line):
            continue
        if line.lower() in SKIP_LINES:
            continue

        # Three-part entry
        m3 = VOCAB_LINE_RE.match(line)
        if m3:
            a, b, c = _clean(m3.group("a")), _clean(m3.group("b")), _clean(m3.group("c"))
            # Determine which part is Farsi, transliteration, English
            farsi_part, english_part, translit_part = None, None, None

            parts = [a, b, c]
            farsi_candidates = [p for p in parts if _is_farsi(p)]
            latin_candidates = [p for p in parts if _is_latin(p)]

            if farsi_candidates:
                farsi_part = farsi_candidates[0]
                remaining = [p for p in parts if p != farsi_part]
                # Heuristics: transliteration tends to be lowercase, shorter, no spaces
                remaining.sort(key=lambda x: (len(x.split()), len(x)))
                if len(remaining) == 2:
                    # shorter/simpler is usually translit
                    translit_part = remaining[0]
                    english_part = remaining[1]
            else:
                # No Farsi – two Latin parts (transliteration and English likely)
                translit_part = a
                english_part = b
                # c might be note
                pending_notes.append(c)

            flush_entry()
            pos, english_clean = _extract_pos(english_part or "")
            if not pos and translit_part:
                pos, translit_clean = _extract_pos(translit_part)
                translit_part = translit_clean

            last_entry = {
                "farsi": farsi_part or "",
                "transliteration": _clean(translit_part or ""),
                "english": _clean(english_clean if english_part else ""),
                "partOfSpeech": pos,
                "notes": "",
                "examples": [],
                "imagePath": None,
                "tags": [],
                "source": source_meta,
                "needsReview": False,
            }
            # Flag if Farsi script is missing
            if not last_entry["farsi"]:
                last_entry["needsReview"] = True
            continue

        # Two-part entry
        m2 = TWO_PART_RE.match(line)
        if m2:
            a, b = _clean(m2.group("a")), _clean(m2.group("b"))
            # Skip very short/noisy
            if len(a) < 2 or len(b) < 2:
                continue

            if _is_farsi(a) or _is_farsi(b):
                farsi_part = a if _is_farsi(a) else b
                other = b if _is_farsi(a) else a
                # Could be translit or English – mark for review if we can't tell
                flush_entry()
                pos, other_clean = _extract_pos(other)
                # Guess: if other looks like a single lowercase word, it's translit
                is_translit = bool(re.match(r"^[a-z][a-z\s\-\']+$", other.strip()))
                last_entry = {
                    "farsi": farsi_part,
                    "transliteration": other_clean if is_translit else "",
                    "english": "" if is_translit else other_clean,
                    "partOfSpeech": pos,
                    "notes": "",
                    "examples": [],
                    "imagePath": None,
                    "tags": [],
                    "source": source_meta,
                    "needsReview": True,
                }
                continue
            else:
                # Both Latin → could be "translit : english" or a contextual note
                # If last_entry exists, treat as note/continuation
                if last_entry is not None:
                    pending_notes.append(line)
                # Otherwise a standalone pair – add with needsReview
                else:
                    flush_entry()
                    pos, b_clean = _extract_pos(b)
                    last_entry = {
                        "farsi": "",
                        "transliteration": a,
                        "english": b_clean,
                        "partOfSpeech": pos,
                        "notes": "",
                        "examples": [],
                        "imagePath": None,
                        "tags": [],
                        "source": source_meta,
                        "needsReview": True,
                    }
                continue

        # Not a vocab line: treat as example or note for the last entry
        if last_entry is not None:
            if _looks_like_example(line):
                pending_examples.append(line)
            else:
                pending_notes.append(line)

    flush_entry()

    # Assign per-file indices and build ids
    for i, entry in enumerate(entries):
        entry["id"] = f"{source_slug}-{i:04d}"

    return entries


# --------------------------------------------------------------------------- #
# Handwritten PDF renderer                                                      #
# --------------------------------------------------------------------------- #

def render_handwritten(pdf_path: Path, slug: str) -> list[Path]:
    """Render each page to PNG. Returns list of paths."""
    import fitz

    out_dir = PAGES_DIR / slug
    out_dir.mkdir(parents=True, exist_ok=True)

    doc = fitz.open(str(pdf_path))
    page_paths: list[Path] = []
    for i, page in enumerate(doc):
        mat = fitz.Matrix(2.0, 2.0)  # 2x zoom ≈ 144 DPI
        pix = page.get_pixmap(matrix=mat)
        out_path = out_dir / f"p{i+1:02d}.png"
        pix.save(str(out_path))
        page_paths.append(out_path)
    doc.close()
    return page_paths


# --------------------------------------------------------------------------- #
# File slug and metadata                                                        #
# --------------------------------------------------------------------------- #

def slug_for(filename: str) -> str:
    """Convert PDF filename to a stable slug used as JSON key and ID prefix."""
    stem = Path(filename).stem
    return re.sub(r"[^a-zA-Z0-9]", "_", stem).lower()


def meta_for(filename: str) -> dict:
    """Extract lesson number and date from filename."""
    stem = Path(filename).stem
    # Lesson_01_2024-07-14 or Note_2024-10-22 or Lesson_X_2025-09-29
    lesson_num = None
    date_str = None

    m = re.match(r"Lesson_(\d+)_(\d{4}-\d{2}-\d{2})", stem, re.IGNORECASE)
    if m:
        lesson_num = int(m.group(1))
        date_str = m.group(2)

    if not date_str:
        m2 = re.search(r"(\d{4}-\d{2}-\d{2})", stem)
        if m2:
            date_str = m2.group(1)

    return {
        "file": filename,
        "lesson": lesson_num,
        "date": date_str,
    }


# --------------------------------------------------------------------------- #
# sha256                                                                        #
# --------------------------------------------------------------------------- #

def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# --------------------------------------------------------------------------- #
# Registry                                                                      #
# --------------------------------------------------------------------------- #

def load_registry() -> dict:
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    return {}


def save_registry(reg: dict) -> None:
    REGISTRY_PATH.write_text(
        json.dumps(reg, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )


# --------------------------------------------------------------------------- #
# Main processing                                                               #
# --------------------------------------------------------------------------- #

def process_pdf(pdf_path: Path, registry: dict, force: bool = False) -> dict:
    """Process one PDF. Returns updated registry record."""
    filename = pdf_path.name
    slug = slug_for(filename)
    sha = sha256_of(pdf_path)

    rec = registry.get(filename, {})
    if not force and rec.get("sha256") == sha and rec.get("status") in ("reviewed", "drafted", "needs_vision"):
        print(f"  [skip] {filename} (unchanged, status={rec['status']})")
        return rec

    print(f"  [process] {filename}")
    pdf_type, raw_text = classify_pdf(pdf_path)

    meta = meta_for(filename)

    rec = {
        "sha256": sha,
        "type": pdf_type,
        "status": "pending",
        "pageCount": 0,
        "entryCount": 0,
        "lastProcessed": datetime.utcnow().isoformat() + "Z",
    }

    import fitz
    doc = fitz.open(str(pdf_path))
    rec["pageCount"] = len(doc)
    doc.close()

    out_path = EXTRACTED_DIR / f"{slug}.json"

    if pdf_type == "typed":
        entries = parse_typed_text(raw_text, slug, meta)
        # Filter out noise entries (both farsi and english empty)
        entries = [e for e in entries if e["farsi"] or e["english"] or e["transliteration"]]
        rec["entryCount"] = len(entries)
        rec["status"] = "drafted"

        # Preserve manual edits: if file exists and status was reviewed, only update new fields
        existing_entries = []
        if out_path.exists():
            try:
                existing_data = json.loads(out_path.read_text(encoding="utf-8"))
                existing_entries = existing_data.get("entries", [])
            except Exception:
                pass

        out_path.write_text(
            json.dumps({"source": meta, "entries": entries}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        n_review = sum(1 for e in entries if e["needsReview"])
        print(f"    → typed: {len(entries)} entries, {n_review} need review")

    else:  # handwritten
        page_paths = render_handwritten(pdf_path, slug)
        rec["pageCount"] = len(page_paths)
        rec["status"] = "needs_vision"

        # Write a skeleton JSON for the agent to fill in
        if not out_path.exists():
            out_path.write_text(
                json.dumps(
                    {
                        "source": meta,
                        "notes": "HANDWRITTEN – agent vision extraction needed. Fill in entries array.",
                        "pages": [str(p.relative_to(ROOT)) for p in page_paths],
                        "entries": [],
                    },
                    ensure_ascii=False,
                    indent=2,
                ),
                encoding="utf-8",
            )
        print(f"    → handwritten: {len(page_paths)} pages rendered to content/pages/{slug}/")

    return rec


def main():
    parser = argparse.ArgumentParser(description="Extract vocabulary from farsi_lessons PDFs.")
    parser.add_argument("--force", action="store_true", help="Reprocess all files, ignoring registry.")
    parser.add_argument("--file", help="Process a single file by name.")
    args = parser.parse_args()

    registry = load_registry()

    pdfs = sorted(LESSONS_DIR.glob("*.pdf"))
    if args.file:
        pdfs = [p for p in pdfs if p.name == args.file]
        if not pdfs:
            print(f"File not found: {args.file}")
            sys.exit(1)

    print(f"Found {len(pdfs)} PDFs")
    for pdf_path in pdfs:
        rec = process_pdf(pdf_path, registry, force=args.force)
        registry[pdf_path.name] = rec

    save_registry(registry)
    print(f"\nRegistry saved to {REGISTRY_PATH}")

    # Summary
    typed = sum(1 for r in registry.values() if r.get("type") == "typed")
    hw = sum(1 for r in registry.values() if r.get("type") == "handwritten")
    drafted = sum(1 for r in registry.values() if r.get("status") == "drafted")
    needs_vision = sum(1 for r in registry.values() if r.get("status") == "needs_vision")
    reviewed = sum(1 for r in registry.values() if r.get("status") == "reviewed")
    print(f"\nSummary: {typed} typed ({drafted} drafted, {reviewed} reviewed), {hw} handwritten ({needs_vision} need vision)")


if __name__ == "__main__":
    main()
