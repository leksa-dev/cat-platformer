"""Backdrops for the two new Kopiec parts, cut from the existing sunset panorama (no new art): a narrow strip of it, mirrored side
by side (mirrored joints are seamless), and extended downward by mirroring its bottom rows, so the descent still has trees behind it.
  bg_las.png      - left strip: autumn trees at the edge, the skyline far away  (part 2, the descent among the trees)
  bg_rownina.png  - the strip right of the mound (only the opaque part; the panorama fades out after x=1808): houses, lawns and trees at the horizon               (part 3, the flat stretch)"""
from PIL import Image, ImageOps

SRC = "assets/game/lvl4/kopiec/bg.png"
W, H_OUT = 2048, 1000


def build(strip, out):
    im = Image.open(SRC).convert("RGBA")
    a = im.crop(strip)
    row = Image.new("RGBA", (W, im.height))
    x, flip = 0, False
    while x < W:
        row.paste(ImageOps.mirror(a) if flip else a, (x, 0))
        x += a.width
        flip = not flip
    ext = ImageOps.flip(row.crop((0, im.height - (H_OUT - im.height), W, im.height)))
    full = Image.new("RGBA", (W, H_OUT))
    full.paste(row, (0, 0))
    full.paste(ext, (0, im.height))
    full.save(out)


build((0, 0, 380, 768), "assets/game/lvl4/kopiec/bg_las.png")
build((1540, 0, 1800, 768), "assets/game/lvl4/kopiec/bg_rownina.png")
