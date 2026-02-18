#!/usr/bin/env python3
import os
import shutil
from pathlib import Path
from PIL import Image

ALPHA_THRESHOLD = 1  # >1 para ser mais agressivo
PADDING = 16         # px
MAX_SIDE_WASTE = 512
MAX_SIDE_BINS  = 512

def alpha_bbox(im: Image.Image):
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    alpha = im.getchannel("A")
    bbox = alpha.point(lambda a: 255 if a > ALPHA_THRESHOLD else 0).getbbox()
    return bbox  # (left, upper, right, lower) or None

def pad_bbox(bbox, w, h, pad):
    l, u, r, b = bbox
    l = max(0, l - pad)
    u = max(0, u - pad)
    r = min(w, r + pad)
    b = min(h, b + pad)
    return (l, u, r, b)

def resize_contain(im: Image.Image, max_side: int):
    w, h = im.size
    m = max(w, h)
    if m <= max_side:
        return im
    scale = max_side / m
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    return im.resize((new_w, new_h), Image.Resampling.LANCZOS)

def process_png(src: Path, dst: Path, max_side: int, make_backup: bool):
    im = Image.open(src)
    w, h = im.size

    bbox = alpha_bbox(im)
    if bbox:
        bbox = pad_bbox(bbox, w, h, PADDING)
        im = im.crop(bbox)

    im = resize_contain(im, max_side)

    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, format="PNG", optimize=True)

    if make_backup:
        backup = src.with_suffix(src.suffix + ".bak")
        if not backup.exists():
            shutil.copy2(src, backup)

def main():
    repo_root = Path(".").resolve()

    # ajusta estes paths à tua estrutura real
    waste_dir = repo_root / "packages" / "eco_sort_game" / "assets" / "images" / "waste_items"
    bins_dir  = repo_root / "packages" / "eco_sort_game" / "assets" / "images" / "containers"

    if not waste_dir.exists() or not bins_dir.exists():
        raise SystemExit(f"Pastas não encontradas. Verifica:\n- {waste_dir}\n- {bins_dir}")

    # remove lixo macOS
    for junk in repo_root.rglob(".DS_Store"):
        junk.unlink()
    for junk in repo_root.rglob("__MACOSX"):
        shutil.rmtree(junk, ignore_errors=True)

    # process waste items
    for src in waste_dir.rglob("*.png"):
        process_png(src, src, MAX_SIDE_WASTE, make_backup=True)

    # process bins
    for src in bins_dir.rglob("*.png"):
        process_png(src, src, MAX_SIDE_BINS, make_backup=True)

    print("OK: assets higienizados (trim + padding + resize + optimize). Backups: *.png.bak")

if __name__ == "__main__":
    main()