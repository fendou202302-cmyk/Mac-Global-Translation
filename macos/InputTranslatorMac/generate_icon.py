#!/usr/bin/env python3
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ICON_SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]


def font(size, bold=True):
    candidates = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def rounded(draw, xy, radius, fill):
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def text_center(draw, box, text, fill, font_obj):
    left, top, right, bottom = box
    bbox = draw.textbbox((0, 0), text, font=font_obj)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    x = left + ((right - left) - width) / 2 - bbox[0]
    y = top + ((bottom - top) - height) / 2 - bbox[1]
    draw.text((x, y), text, fill=fill, font=font_obj)


def make_icon(size, scale=4):
    canvas = size * scale
    image = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    def s(value):
        return int(round(value * scale))

    # Soft round brand shape instead of a square app tile.
    center = canvas / 2
    outer_radius = s(size * 0.43)
    shadow = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        (center - outer_radius, center - outer_radius + s(size * 0.035), center + outer_radius, center + outer_radius + s(size * 0.035)),
        fill=(0, 72, 135, 52),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(s(size * 0.035)))
    image.alpha_composite(shadow)

    circle_mask = Image.new("L", (canvas, canvas), 0)
    mask_draw = ImageDraw.Draw(circle_mask)
    mask_draw.ellipse(
        (center - outer_radius, center - outer_radius, center + outer_radius, center + outer_radius),
        fill=255,
    )

    gradient = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    gradient_pixels = gradient.load()
    top_left = (84, 121, 255, 255)
    bottom_right = (0, 184, 193, 255)
    accent = (125, 88, 255, 255)
    for y in range(canvas):
        for x in range(canvas):
            nx = x / max(1, canvas - 1)
            ny = y / max(1, canvas - 1)
            t = min(1, max(0, (nx + ny) / 1.55))
            color = tuple(int(top_left[i] * (1 - t) + bottom_right[i] * t) for i in range(4))
            # subtle violet lift near the top-left so it feels less generic
            glow = max(0, 1 - (((nx - 0.33) ** 2 + (ny - 0.25) ** 2) ** 0.5) * 3.2)
            color = tuple(min(255, int(color[i] * (1 - glow * 0.28) + accent[i] * glow * 0.28)) for i in range(4))
            gradient_pixels[x, y] = color
    image.alpha_composite(Image.composite(gradient, Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0)), circle_mask))

    draw = ImageDraw.Draw(image)
    # Decorative orbit stroke gives the mark a little movement and craft.
    draw.arc(
        (s(size * 0.13), s(size * 0.12), s(size * 0.87), s(size * 0.86)),
        start=205,
        end=330,
        fill=(255, 255, 255, 78),
        width=max(1, s(size * 0.018)),
    )
    draw.ellipse(
        (s(size * 0.69), s(size * 0.18), s(size * 0.75), s(size * 0.24)),
        fill=(255, 255, 255, 128),
    )

    # Two soft translation cards, intentionally pill-like and offset.
    back = (s(size * 0.23), s(size * 0.29), s(size * 0.66), s(size * 0.60))
    front = (s(size * 0.35), s(size * 0.41), s(size * 0.79), s(size * 0.72))
    rounded(draw, back, s(size * 0.155), (235, 247, 255, 236))
    rounded(draw, front, s(size * 0.165), (255, 255, 255, 255))

    tail = [
        (s(size * 0.55), s(size * 0.70)),
        (s(size * 0.62), s(size * 0.84)),
        (s(size * 0.66), s(size * 0.70)),
    ]
    draw.polygon(tail, fill=(255, 255, 255, 255))

    text_center(draw, back, "A", (43, 82, 224, 255), font(s(size * 0.24)))
    text_center(draw, front, "译", (0, 128, 169, 255), font(s(size * 0.25)))

    return image.resize((size, size), Image.Resampling.LANCZOS)


def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit("Usage: generate_icon.py <AppIcon.iconset> [AppIcon.icns]")

    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)

    master = make_icon(1024, scale=1)
    for name, size in ICON_SIZES:
        icon = master if size == 1024 else master.resize((size, size), Image.Resampling.LANCZOS)
        icon.save(out_dir / name)

    if len(sys.argv) == 3:
        write_icns(out_dir, Path(sys.argv[2]))


def write_icns(iconset_dir, icns_path):
    chunks = [
        ("icp4", iconset_dir / "icon_16x16.png"),
        ("icp5", iconset_dir / "icon_32x32.png"),
        ("icp6", iconset_dir / "icon_32x32@2x.png"),
        ("ic07", iconset_dir / "icon_128x128.png"),
        ("ic08", iconset_dir / "icon_128x128@2x.png"),
        ("ic09", iconset_dir / "icon_256x256@2x.png"),
        ("ic10", iconset_dir / "icon_512x512@2x.png"),
    ]
    payload = bytearray()

    for chunk_type, path in chunks:
        data = path.read_bytes()
        payload.extend(chunk_type.encode("ascii"))
        payload.extend((len(data) + 8).to_bytes(4, "big"))
        payload.extend(data)

    icns_path.parent.mkdir(parents=True, exist_ok=True)
    with icns_path.open("wb") as file:
        file.write(b"icns")
        file.write((len(payload) + 8).to_bytes(4, "big"))
        file.write(payload)


if __name__ == "__main__":
    main()
