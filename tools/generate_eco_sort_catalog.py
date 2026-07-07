#!/usr/bin/env python3
import json
import re
from translate import Translator
from pathlib import Path

# Usage example:
#   $ python3 tools/generate_eco_sort_catalog.py

REPO_ROOT = Path(__file__).resolve().parents[1]

PKG_ROOT = REPO_ROOT / "packages" / "eco_sort_game"

IMAGES_DIR = PKG_ROOT / "assets" / "images"

WASTE_DIRS = {
    "blue": PKG_ROOT / IMAGES_DIR / "waste_items/blue",
    "green": PKG_ROOT / IMAGES_DIR / "waste_items/green",
    "yellow": PKG_ROOT / IMAGES_DIR / "waste_items/yellow",
    "brown": PKG_ROOT / IMAGES_DIR / "waste_items/brown"
}

CONTAINERS_DIR = PKG_ROOT / IMAGES_DIR / "containers"
OUT_PATH = PKG_ROOT / "assets/data/eco_sort/catalog_v1.json"

BINS = ["blue", "green", "yellow", "brown"]
ALLOWED_EXT = {".png", ".jpg", ".jpeg", ".webp"}

BIN_LABELS_PT = {
    "blue": "Papel",
    "green": "Vidro",
    "yellow": "Plástico/Metal",
    "brown": "Orgânico",
}

BIN_LABELS_EN = {
    "blue": "Paper",
    "green": "Glass",
    "yellow": "Plastic/Metal",
    "brown": "Organic",
}

# Add future waste item additions pt labels here, to avoid generating them from the filename
WASTE_LABELS_PT = {
    "cardboard_box": "Caixa de Cartão",
    "old_newspaper": "Jornal Antigo",
    "broken_bottle": "Garrafa Partida",
    "raspberry_jam_jar": "Frasco de Compota de Framboesa",
    "wine_bottle": "Garrafa de Vinho",
    "milk_packet": "Pacote de Leite",
    "orange_juice_packet": "Pacote de Sumo de Laranja",
    "soda_can": "Lata de Refrigerante",
    "water_bottle": "Garrafa de Água",
    "yogurt_can": "Embalagem de Iogurte",
    "apple": "Maçã",
    "banana_peel": "Casca de Banana",
    "fish_bones": "Espinhas de Peixe",
    "pizza_slice": "Fatia de Pizza",
}

def slugify(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s

def label_from_filename_en(label: str) -> str:
    return label.replace("_", " ").replace("-", " ").strip().title()

def label_from_filename_pt(label: str) -> str:
    if label in WASTE_LABELS_PT:
        return WASTE_LABELS_PT[label]
    translator = Translator(to_lang="pt-pt", from_lang="en")
    return translator.translate(label.replace("_", " ").replace("-", " ").strip().title())

def find_container_asset(bin_name: str) -> Path:
    for ext in [".png", ".jpg", ".jpeg", ".webp"]:
        p = CONTAINERS_DIR / f"{bin_name}{ext}"
        if p.exists():
            return p
    raise SystemExit(
        f"[ERROR] Container sprite not found for '{bin_name}'. "
        f"Expected: {CONTAINERS_DIR}/{bin_name}.(png|jpg|jpeg|webp)"
    )

def main():
    for bin_name, waste_dir in WASTE_DIRS.items():
        if not waste_dir.exists():
            raise SystemExit(f"[ERROR] Folder not found: {waste_dir}")
    if not CONTAINERS_DIR.exists():
        raise SystemExit(f"[ERROR] Folder not found: {CONTAINERS_DIR}")

    # --- bins ---
    bins = []
    for bin_name in BINS:
        asset_file = find_container_asset(bin_name)
        bins.append({
            "id": bin_name,
            "label_en": BIN_LABELS_EN.get(bin_name, bin_name.title()),
            "label_pt": BIN_LABELS_PT.get(bin_name, bin_name.title()),
            "asset": asset_file.relative_to(IMAGES_DIR).as_posix(),
        })

    # --- items ---
    items = []
    seen_ids = set()

    for bin_name in BINS:
        bin_dir = WASTE_DIRS.get(bin_name)
        if not bin_dir.exists():
            print(f"[WARNING] Folder not found (ignored): {bin_dir}")
            continue

        files = sorted([p for p in bin_dir.rglob("*") if p.is_file() and p.suffix.lower() in ALLOWED_EXT])
        if not files:
            print(f"[WARNING] No images found in: {bin_dir}")
            continue

        for f in files:
            stem = f.stem
            item_id = f"{bin_name}_{slugify(stem)}"
            if item_id in seen_ids:
                raise SystemExit(f"[ERROR] Duplicate ID: {item_id} (file: {f})")
            seen_ids.add(item_id)

            items.append({
                "id": item_id,
                "asset": f.relative_to(IMAGES_DIR).as_posix(),
                "bin": bin_name,
                "label_en": label_from_filename_en(stem),
                "label_pt": label_from_filename_pt(stem),
            })

    if not items:
        raise SystemExit("[ERROR] No valid waste items found.")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    catalog = {
        "version": 1,
        "bins": bins,
        "items": sorted(items, key=lambda e: (e["bin"], e["id"])),
    }

    with OUT_PATH.open("w", encoding="utf-8") as fp:
        json.dump(catalog, fp, ensure_ascii=False, indent=2)

    print(f"[OK] Generated: {OUT_PATH} ({len(items)} items, {len(bins)} bins)")

if __name__ == "__main__":
    main()