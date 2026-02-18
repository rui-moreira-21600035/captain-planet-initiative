#!/usr/bin/env python3
import json
import re
from pathlib import Path

# Usage example:
#   $ python3 tools/generate_eco_sort_catalog.py

PKG_ROOT = Path("packages/eco_sort_game")
WASTE_ROOT = PKG_ROOT / "assets/images/waste_items"
CONTAINERS_DIR = PKG_ROOT / "assets/images/containers"
OUT_PATH = PKG_ROOT / "assets/data/eco_sort/catalog_v1.json"

BINS = ["blue", "green", "yellow", "brown"]
ALLOWED_EXT = {".png", ".jpg", ".jpeg", ".webp"}

BIN_LABELS_PT = {
    "blue": "Papel",
    "green": "Vidro",
    "yellow": "Plástico/Metal",
    "brown": "Orgânico",
}

def slugify(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s

def label_from_filename(stem: str) -> str:
    return stem.replace("_", " ").replace("-", " ").strip().title()

def find_container_asset(bin_name: str) -> Path:
    for ext in [".png", ".jpg", ".jpeg", ".webp"]:
        p = CONTAINERS_DIR / f"{bin_name}{ext}"
        if p.exists():
            return p
    raise SystemExit(
        f"[ERRO] Não encontrei sprite do contentor para '{bin_name}'. "
        f"Esperado: {CONTAINERS_DIR}/{bin_name}.(png|jpg|jpeg|webp)"
    )

def main():
    if not WASTE_ROOT.exists():
        raise SystemExit(f"[ERRO] Pasta não encontrada: {WASTE_ROOT}")
    if not CONTAINERS_DIR.exists():
        raise SystemExit(f"[ERRO] Pasta não encontrada: {CONTAINERS_DIR}")

    # --- bins ---
    bins = []
    for bin_name in BINS:
        asset_file = find_container_asset(bin_name)
        bins.append({
            "id": bin_name,
            "label": BIN_LABELS_PT.get(bin_name, bin_name.title()),
            "asset": asset_file.relative_to(PKG_ROOT).as_posix(),
        })

    # --- items ---
    items = []
    seen_ids = set()

    for bin_name in BINS:
        bin_dir = WASTE_ROOT / bin_name
        if not bin_dir.exists():
            print(f"[AVISO] Pasta ausente (ignorada): {bin_dir}")
            continue

        files = sorted([p for p in bin_dir.rglob("*") if p.is_file() and p.suffix.lower() in ALLOWED_EXT])
        if not files:
            print(f"[AVISO] Sem imagens em: {bin_dir}")
            continue

        for f in files:
            stem = f.stem
            item_id = f"{bin_name}_{slugify(stem)}"
            if item_id in seen_ids:
                raise SystemExit(f"[ERRO] ID duplicado: {item_id} (ficheiro: {f})")
            seen_ids.add(item_id)

            items.append({
                "id": item_id,
                "asset": f.relative_to(PKG_ROOT).as_posix(),
                "bin": bin_name,
                "label": label_from_filename(stem),
            })

    if not items:
        raise SystemExit("[ERRO] Não encontrei waste items válidos.")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    catalog = {
        "version": 1,
        "bins": bins,
        "items": sorted(items, key=lambda e: (e["bin"], e["id"])),
    }

    with OUT_PATH.open("w", encoding="utf-8") as fp:
        json.dump(catalog, fp, ensure_ascii=False, indent=2)

    print(f"[OK] Gerado: {OUT_PATH} ({len(items)} items, {len(bins)} bins)")

if __name__ == "__main__":
    main()