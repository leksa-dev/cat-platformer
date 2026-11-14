"""Backdrops for the Fort's parts 2 and 3, cut from the Fort's own backdrop (no new art): strips left and right of the brick
fort itself, flipped and tinted differently, cross-faded. Same size as the original (2172x944, drawn at 0.4712 = 1024 px wide)."""
from PIL import Image, ImageEnhance, ImageOps

SRC = "assets/game/lvl4/fort/bg.png"
FADE = 120
A, B, C = (120, 0, 700, 944), (1790, 0, 2060, 944), (700, 0, 960, 944)   # left trees, right trees, a bit of lawn


def piece(im, box, flip, bright, tint):
    p = im.crop(box)
    if flip:
        p = ImageOps.mirror(p)
    p = ImageEnhance.Brightness(p).enhance(bright)
    r, g, b, a = p.split()
    r, g, b = (ch.point(lambda v, k=k: min(255, int(v * k))) for ch, k in zip((r, g, b), tint))
    return Image.merge("RGBA", (r, g, b, a))


def compose(pieces, out):
    im = Image.open(SRC).convert("RGBA")
    row = Image.new("RGBA", im.size, (0, 0, 0, 0))
    x = 0
    for i, (box, flip, bright, tint) in enumerate(pieces):
        if x >= im.width:
            break
        p = piece(im, box, flip, bright, tint)
        if i:
            mask = Image.new("L", p.size, 255)
            mask.paste(Image.linear_gradient("L").rotate(90).resize((FADE, p.height)), (0, 0))
            row.paste(p, (x - FADE, 0), mask)
        else:
            row.paste(p, (0, 0))
        x += p.width - (FADE if i else 0)
    row.save(out)


PART2 = [(A, False, 1.0, (1, 1, 1)), (B, True, 1.0, (1, 1, 1)), (C, False, 0.98, (0.98, 1.02, 1)), (A, True, 0.96, (1, 1.04, 0.98)),
         (B, False, 1.0, (1.02, 1, 0.98)), (C, True, 1.0, (1, 1, 1)), (A, False, 0.98, (1.02, 1, 0.98))]
PART3 = [(B, False, 0.97, (1.03, 1, 0.97)), (A, True, 0.95, (1, 1.03, 1)), (C, True, 1.0, (1, 1, 1.03)), (B, True, 0.98, (1, 1.02, 0.98)),
         (A, False, 1.0, (1, 1, 1)), (C, False, 0.97, (1.02, 1.02, 1)), (B, False, 0.96, (1, 1, 1.03))]
compose(PART2 * 2, "assets/game/lvl4/fort/bg_part2.png")
compose(PART3 * 2, "assets/game/lvl4/fort/bg_part3.png")
