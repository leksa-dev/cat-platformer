"""Backdrops for the two new Kopiec parts, cut from the existing sunset panorama (no new art). Short strips of it (flipped, tinted a
little differently each time) are laid side by side and cross-faded, so no single piece repeats visibly; the picture is extended
downward by mirroring its bottom rows. Only the opaque part of the panorama is used (it fades out after x=1808) and never the mound.
  bg_las.png      - part 2, the descent among the trees: warm autumn light, the sun once at the start
  bg_rownina.png  - part 3, the flat stretch: the same panorama toward dusk (cooler, a bit darker)"""
from PIL import Image, ImageEnhance, ImageOps

SRC = "assets/game/lvl4/kopiec/bg.png"
W, H_OUT, FADE = 2048, 1000, 100


def piece(im, box, flip, bright, tint):
    p = im.crop(box)
    if flip:
        p = ImageOps.mirror(p)
    p = ImageEnhance.Brightness(p).enhance(bright)
    if tint != (1, 1, 1):
        r, g, b, a = p.split()
        r = r.point(lambda v: min(255, int(v * tint[0])))
        g = g.point(lambda v: min(255, int(v * tint[1])))
        b = b.point(lambda v: min(255, int(v * tint[2])))
        p = Image.merge("RGBA", (r, g, b, a))
    return p


def compose(pieces, out):
    im = Image.open(SRC).convert("RGBA")
    row = Image.new("RGBA", (W, im.height), (0, 0, 0, 255))
    x = 0
    for i, (box, flip, bright, tint) in enumerate(pieces):
        p = piece(im, box, flip, bright, tint)
        if x >= W:
            break
        if i > 0:  # cross-fade into what is already there
            mask = Image.new("L", p.size, 255)
            mask.paste(Image.linear_gradient("L").rotate(90).resize((FADE, p.height)), (0, 0))  # 0 -> 255 across the overlap
            row.paste(p, (x - FADE, 0), mask)
        else:
            row.paste(p, (0, 0))
        x += p.width - (FADE if i > 0 else 0)
    ext = ImageOps.flip(row.crop((0, im.height - (H_OUT - im.height), W, im.height)))
    full = Image.new("RGBA", (W, H_OUT))
    full.paste(row, (0, 0))
    full.paste(ext, (0, im.height))
    full.save(out)


SUN = (0, 0, 700, 768)  # the one strip with the sun in it
A, B, C = (0, 0, 380, 768), (1540, 0, 1800, 768), (580, 0, 760, 768)  # sun-free strips: left trees, right houses, a bit of lawn
WARM = [(SUN, False, 1.0, (1, 1, 1)), (B, False, 1.0, (1, 1, 1)), (A, True, 0.96, (1.04, 1.0, 0.96)), (C, False, 1.02, (1, 1, 1.04)),
        (B, True, 0.97, (1.03, 1.0, 0.97)), (A, False, 0.94, (1.05, 0.98, 0.95)), (C, True, 1.0, (1.02, 1, 0.98))]
DUSK = [(B, False, 0.9, (0.92, 0.9, 1.1)), (A, True, 0.88, (0.94, 0.9, 1.08)), (C, False, 0.9, (0.95, 0.92, 1.08)), (B, True, 0.9, (0.93, 0.9, 1.1)),
        (A, False, 0.86, (0.92, 0.9, 1.1)), (C, True, 0.88, (0.94, 0.92, 1.1))]
compose(WARM * 2, "assets/game/lvl4/kopiec/bg_las.png")
compose(DUSK * 3, "assets/game/lvl4/kopiec/bg_rownina.png")
