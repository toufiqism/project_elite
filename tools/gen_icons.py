"""Generate Project Elite icon assets.

Design: dark navy background + gold ascending double chevron (self-improvement / elite ascent).
Outputs to assets/icon/.
"""
from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)

SIZE = 1024
BG = (11, 15, 20, 255)        # #0B0F14
GOLD = (231, 199, 123, 255)   # #E7C77B
WHITE = (255, 255, 255, 255)


def draw_chevrons(draw: ImageDraw.ImageDraw, color, size=SIZE, scale=1.0):
    """Two stacked upward chevrons centered in a `size`x`size` canvas."""
    cx = size / 2
    cy = size / 2
    # Chevron geometry as a fraction of size, then scaled.
    w = 0.52 * size * scale          # chevron width
    h = 0.18 * size * scale          # chevron height (each)
    t = 0.085 * size * scale         # stroke thickness
    gap = 0.06 * size * scale        # vertical gap between two chevrons

    def chev(center_y):
        left = cx - w / 2
        right = cx + w / 2
        top = center_y - h / 2
        bottom = center_y + h / 2
        # Outer triangle
        outer = [(left, bottom), (cx, top), (right, bottom)]
        # Inner triangle (offset down by t for stroke effect)
        inner = [(left + t, bottom + t), (cx, top + t), (right - t, bottom + t)]
        draw.polygon(outer, fill=color)
        # Cut inner by drawing bg over it
        draw.polygon(inner, fill=(0, 0, 0, 0))

    # Upper chevron (apex higher)
    chev(cy - (h / 2 + gap / 2))
    # Lower chevron
    chev(cy + (h / 2 + gap / 2))


def make_filled(color, size=SIZE, scale=1.0):
    """Generate chevrons via mask so cutout uses transparency correctly."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = size / 2
    cy = size / 2
    w = 0.52 * size * scale
    h = 0.18 * size * scale
    t = 0.09 * size * scale
    gap = 0.05 * size * scale

    def chev_mask(mask_draw, center_y):
        left = cx - w / 2
        right = cx + w / 2
        top = center_y - h / 2
        bottom = center_y + h / 2
        outer = [(left, bottom), (cx, top), (right, bottom)]
        inner_top_offset = t * 1.2
        inner = [
            (left + t, bottom),
            (cx, top + inner_top_offset),
            (right - t, bottom),
        ]
        mask_draw.polygon(outer, fill=255)
        mask_draw.polygon(inner, fill=0)

    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    upper_cy = cy - (h / 2 + gap / 2)
    lower_cy = cy + (h / 2 + gap / 2)
    chev_mask(md, upper_cy)
    chev_mask(md, lower_cy)

    fill = Image.new("RGBA", (size, size), color)
    img.paste(fill, (0, 0), mask)
    return img


# 1. Legacy launcher icon: full art on dark bg.
legacy = Image.new("RGBA", (SIZE, SIZE), BG)
chev = make_filled(GOLD, SIZE, scale=1.0)
legacy.alpha_composite(chev)
legacy.save(OUT / "icon.png", "PNG")

# 2. Adaptive foreground: chevrons centered with 33% padding (safe zone).
# Total 108dp; safe zone is inner 66dp -> scale art to ~0.62 of canvas.
fg = make_filled(GOLD, SIZE, scale=0.62)
fg.save(OUT / "icon_foreground.png", "PNG")

# 3. Monochrome (Android 13 themed icons): white silhouette, same padding.
mono = make_filled(WHITE, SIZE, scale=0.62)
mono.save(OUT / "icon_monochrome.png", "PNG")

# 4. Notification icon: white silhouette, smaller canvas.
notif = make_filled(WHITE, 96, scale=0.85)
notif.save(OUT / "notification_icon.png", "PNG")

print("wrote:")
for p in OUT.iterdir():
    print(" ", p.name, p.stat().st_size, "bytes")
