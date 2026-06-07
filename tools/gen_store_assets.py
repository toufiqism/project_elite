"""Generate Play Store listing assets:
  - Feature graphic (1024x500)
  - 512x512 Play icon
Saves to docs/store_listing/.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "docs" / "store_listing"
OUT.mkdir(parents=True, exist_ok=True)

BG = (11, 15, 20, 255)
GOLD = (231, 199, 123, 255)
TEXT = (230, 234, 242, 255)
MUTED = (124, 135, 148, 255)


def _font(size, bold=False):
    """Try a few common Windows fonts; fall back to Pillow default."""
    candidates = (
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    )
    for c in candidates:
        if Path(c).exists():
            return ImageFont.truetype(c, size)
    return ImageFont.load_default()


def chevron_mask(size_w, size_h, scale=1.0):
    """Two-chevron silhouette mask sized for the given canvas, returned as L mode."""
    mask = Image.new("L", (size_w, size_h), 0)
    md = ImageDraw.Draw(mask)
    side = min(size_w, size_h) * scale
    cx = size_w / 2
    cy = size_h / 2
    w = 0.52 * side
    h = 0.18 * side
    t = 0.09 * side
    gap = 0.05 * side

    def chev(center_y):
        left = cx - w / 2
        right = cx + w / 2
        top = center_y - h / 2
        bottom = center_y + h / 2
        outer = [(left, bottom), (cx, top), (right, bottom)]
        inner = [(left + t, bottom), (cx, top + t * 1.2), (right - t, bottom)]
        md.polygon(outer, fill=255)
        md.polygon(inner, fill=0)

    chev(cy - (h / 2 + gap / 2))
    chev(cy + (h / 2 + gap / 2))
    return mask


# ── Feature graphic (1024x500) ────────────────────────────────────────────────
fg = Image.new("RGBA", (1024, 500), BG)

# Chevron emblem on the left, around 380x380 region
emblem = Image.new("RGBA", (380, 380), (0, 0, 0, 0))
mask = chevron_mask(380, 380, scale=1.0)
fill = Image.new("RGBA", (380, 380), GOLD)
emblem.paste(fill, (0, 0), mask)
fg.alpha_composite(emblem, (60, 60))

# Subtle accent line down the right of the emblem
line = Image.new("RGBA", (2, 300), (231, 199, 123, 80))
fg.alpha_composite(line, (470, 100))

# Wordmark + tagline
draw = ImageDraw.Draw(fg)
title_font = _font(78, bold=True)
sub_font = _font(28, bold=False)
draw.text((510, 170), "PROJECT", font=title_font, fill=TEXT)
draw.text((510, 250), "ELITE", font=title_font, fill=GOLD)
draw.text((512, 350), "Discipline. Built daily.", font=sub_font, fill=MUTED)

fg.convert("RGB").save(OUT / "feature_graphic_1024x500.png", "PNG")

# ── 512x512 Play icon (downscale from launcher icon) ─────────────────────────
launcher_src = Path(__file__).resolve().parent.parent / "assets" / "icon" / "icon.png"
if launcher_src.exists():
    icon_full = Image.open(launcher_src).convert("RGBA").resize((512, 512), Image.LANCZOS)
    icon_full.convert("RGB").save(OUT / "play_icon_512.png", "PNG")

print("wrote:")
for p in OUT.iterdir():
    if p.is_file():
        print(" ", p.name, p.stat().st_size, "bytes")
