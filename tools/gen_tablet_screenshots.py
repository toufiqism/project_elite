"""Compose tablet-sized Play Store screenshots from existing phone shots.

Centers the 720x1600 phone screenshot on a dark canvas at 7" and 10"
tablet dimensions. App-matching #0B0F14 background.
"""
from pathlib import Path
from PIL import Image

SRC_DIR = Path(__file__).resolve().parent.parent / "docs" / "store_listing" / "screenshots"
PHONE_FILES = [
    "01_dashboard.png",
    "02_study.png",
    "03_habits.png",
    "04_prayer.png",
    "05_fitness.png",
]
BG = (0x0B, 0x0F, 0x14)

TARGETS = {
    "tablet_7":  (1200, 1920),
    "tablet_10": (1600, 2560),
}
SCALE = 0.90

def compose(phone_path: Path, out_path: Path, canvas_size: tuple[int, int]) -> None:
    canvas_w, canvas_h = canvas_size
    canvas = Image.new("RGB", canvas_size, BG)

    phone = Image.open(phone_path).convert("RGB")
    pw, ph = phone.size

    target_h = int(canvas_h * SCALE)
    target_w = int(target_h * pw / ph)
    if target_w > int(canvas_w * SCALE):
        target_w = int(canvas_w * SCALE)
        target_h = int(target_w * ph / pw)

    resized = phone.resize((target_w, target_h), Image.LANCZOS)
    x = (canvas_w - target_w) // 2
    y = (canvas_h - target_h) // 2
    canvas.paste(resized, (x, y))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, "PNG", optimize=True)
    print(f"wrote {out_path.relative_to(SRC_DIR.parent.parent)} ({canvas_w}x{canvas_h})")

def main() -> None:
    for folder, size in TARGETS.items():
        for name in PHONE_FILES:
            src = SRC_DIR / name
            dst = SRC_DIR / folder / name
            compose(src, dst, size)

if __name__ == "__main__":
    main()
