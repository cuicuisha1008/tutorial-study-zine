#!/usr/bin/env python3
"""Deterministically replace two raster regions in the food-journal PAGE 01 cover."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter


CANVAS = (1086, 1448)


def connected_black_to_alpha(image: Image.Image, threshold: int = 40) -> Image.Image:
    """Remove only near-black pixels connected to the crop boundary."""
    rgba = image.convert("RGBA")
    rgb = np.asarray(rgba.convert("RGB"))
    brightness = rgb.max(axis=2)
    # 0 = possible background, 255 = protected foreground.
    flood = Image.fromarray(np.where(brightness <= threshold, 0, 255).astype(np.uint8), "L").copy()
    for seed in ((0, 0), (flood.width - 1, 0), (0, flood.height - 1), (flood.width - 1, flood.height - 1)):
        ImageDraw.floodfill(flood, seed, 128, thresh=0)
    background = np.asarray(flood) == 128
    alpha = np.full(brightness.shape, 255, dtype=np.uint8)
    alpha[background] = 0
    soft_alpha = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(0.55))
    rgba.putalpha(soft_alpha)
    return rgba


def rounded_card(card: Image.Image, width: int, angle: float) -> Image.Image:
    height = round(width * card.height / card.width)
    card = card.convert("RGBA").resize((width, height), Image.Resampling.LANCZOS)
    mask = Image.new("L", card.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius=18, fill=255)
    card.putalpha(mask)
    return card.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)


def colored_overlay(base: Image.Image, box: tuple[int, int, int, int], kind: str) -> Image.Image:
    """Extract bow or tape pixels from the untouched base for re-layering."""
    patch = base.crop(box).convert("RGBA")
    a = np.asarray(patch.convert("RGB"))
    red, green, blue = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    if kind == "bow":
        # The bow is magenta-red (blue channel at least as strong as green),
        # unlike the warm brown card texture beneath it.
        keep = (
            (red > 145)
            & (red.astype(int) - green.astype(int) > 38)
            & (red.astype(int) - blue.astype(int) > 22)
            & (blue.astype(int) >= green.astype(int) - 3)
        )
    elif kind == "tape":
        keep = (red > 145) & (red.astype(int) - blue.astype(int) > 22) & (green > 70) & (green < 205)
    else:
        raise ValueError(kind)
    mask = Image.fromarray((keep * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
    patch.putalpha(mask)
    return patch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--card", type=Path, required=True)
    parser.add_argument("--notebook", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    base = Image.open(args.base).convert("RGBA")
    if base.size != CANVAS:
        raise SystemExit(f"Base must be {CANVAS[0]}x{CANVAS[1]}, got {base.size}")

    # Preserve the two small decorations that visually sit above the post card.
    bow_box = (924, 105, 1056, 220)
    tape_box = (944, 748, 1058, 835)
    bow = colored_overlay(base, bow_box, "bow")
    tape = colored_overlay(base, tape_box, "tape")

    # Direct pixel placement of the complete supplied post screenshot.
    card = rounded_card(Image.open(args.card), width=378, angle=0.0)
    base.alpha_composite(card, (629, 138))

    # Direct pixel placement of the supplied notebook; crop only unused black field.
    notebook_src = Image.open(args.notebook).convert("RGBA").crop((0, 320, 1086, 1205))
    notebook_rgba = connected_black_to_alpha(notebook_src)
    alpha_box = notebook_rgba.getchannel("A").getbbox()
    if alpha_box is None:
        raise SystemExit("Notebook foreground could not be detected")
    notebook_rgba = notebook_rgba.crop(alpha_box)
    target_width = 680
    target_height = round(target_width * notebook_rgba.height / notebook_rgba.width)
    notebook_rgba = notebook_rgba.resize((target_width, target_height), Image.Resampling.LANCZOS)
    base.alpha_composite(notebook_rgba, (20, 823))

    # Restore original decorations on top; all non-replaced regions stay untouched.
    base.alpha_composite(bow, bow_box[:2])
    base.alpha_composite(tape, tape_box[:2])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    base.convert("RGB").save(args.output, format="PNG", optimize=True)
    print(args.output.resolve())


if __name__ == "__main__":
    main()
