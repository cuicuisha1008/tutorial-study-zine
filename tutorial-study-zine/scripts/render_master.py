#!/usr/bin/env python3
"""Render the locked AI 干中学 SVG master with three safe text substitutions."""

from __future__ import annotations

import argparse
import html
from pathlib import Path


DEFAULT_SERIES = "AI 干中学系列"
DEFAULT_TITLE = "手把手教你用 AI 做爆火的美食手账"


def visual_units(text: str) -> int:
    """Approximate header width: CJK/full-width glyphs count as two Latin units."""
    return sum(2 if ord(char) > 255 else 1 for char in text)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render the deterministic tutorial-zine master SVG.")
    parser.add_argument("--series-label", default=DEFAULT_SERIES)
    parser.add_argument("--issue-title", default=DEFAULT_TITLE)
    parser.add_argument("--page-number", default="01")
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    combined = f"{args.series_label}  ——  {args.issue_title}"
    if visual_units(combined) > 76:
        raise SystemExit("Header is too long for the locked master. Shorten it; never compress the type.")

    page = str(args.page_number).strip()
    if not page.isdigit() or not 1 <= len(page) <= 2:
        raise SystemExit("Page number must be one or two digits.")
    page = page.zfill(2)

    root = Path(__file__).resolve().parents[1]
    template = (root / "assets" / "master-frame.svg").read_text(encoding="utf-8")
    rendered = (
        template.replace("{{SERIES_LABEL}}", html.escape(args.series_label.strip()))
        .replace("{{ISSUE_TITLE}}", html.escape(args.issue_title.strip()))
        .replace("{{PAGE_NUMBER}}", page)
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    print(args.output.resolve())


if __name__ == "__main__":
    main()
