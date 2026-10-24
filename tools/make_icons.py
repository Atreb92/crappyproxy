#!/usr/bin/env python3
"""Resizes tools/icon-source.png into the app icon, Settings icon and Control Center glyph (needs Pillow).
Run from the project root."""
from PIL import Image, ImageChops

src = Image.open("tools/icon-source.png").convert("RGB")  # opaque, full bleed: iOS applies the rounded mask
BG = src.getpixel((0, 0))

for name, size in {"app/Resources/AppIcon60x60@2x.png": 120, "app/Resources/AppIcon60x60@3x.png": 180,
                   "module/Resources/SettingsIcon@2x.png": 58, "module/Resources/SettingsIcon@3x.png": 87}.items():
    src.resize((size, size), Image.LANCZOS).save(name)


def glyph(w, h):
    """White-on-transparent version of the artwork for the Control Center tile (iOS tints it).
    Everything that differs from the background becomes opaque white; the shape keeps its anti-aliased edge."""
    big = src.resize((1024, 1024), Image.LANCZOS)
    r, g, b = ImageChops.difference(big, Image.new("RGB", big.size, BG)).split()
    mask = ImageChops.lighter(ImageChops.lighter(r, g), b).point(lambda v: min(255, v * 255 // 120))
    mask = mask.crop(mask.getbbox())
    scale = min(w * .78 / mask.width, h * .78 / mask.height)
    mask = mask.resize((max(1, round(mask.width * scale)), max(1, round(mask.height * scale))), Image.LANCZOS)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    white = Image.new("RGBA", mask.size, (255, 255, 255, 255))
    white.putalpha(mask)
    out.paste(white, ((w - mask.width) // 2, (h - mask.height) // 2), white)
    return out


for name, size in {"module/Resources/Icon@2x.png": (70, 96), "module/Resources/Icon@3x.png": (105, 144)}.items():
    glyph(*size).save(name)
