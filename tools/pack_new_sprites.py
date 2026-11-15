"""Packs the frames cut by tools/extract_chatgpt_sheet.py (strips <prefix>_row<k>.png) into game sheets.

    python3 tools/pack_new_sprites.py <dir with the cut strips>

- cat: crouch (3), sneak (8), double-jump spin (6) appended to assets/game/cat.png (128x70 cells, feet on the bottom line,
  scaled to the existing cat: its standing frame is ~40 px tall in the sheet)
- assets/game/box_hide.png: the hiding box - cat climbing in (4), eyes open, eyes shut, empty (7 frames)
- assets/game/enemies/duck.png: idle on water 4, swim 6, walk 6, peck 4, hurt 3, death 4 (27 frames)
- assets/game/enemies/beaver.png: idle 6, run 6, bite 9, charge 8, tail slam 9, hurt 7, death 6 (51 frames)
Every frame faces right. Prints each sheet's cell size and frame count.
"""
import sys

import numpy as np
from PIL import Image

D = sys.argv[1]


def frames(prefix, row):
    strip = Image.open(f"{D}/{prefix}_row{row}.png")
    a = np.array(strip)
    # cells are equal width; find them from the alpha gaps instead of guessing the count
    cols = a[:, :, 3].any(axis=0)
    out, start = [], None
    for x, v in enumerate(list(cols) + [False]):
        if v and start is None:
            start = x
        elif not v and start is not None:
            if x - start > 6:
                out.append((start, x))
            start = None
    # merge pieces closer than 3 px (dust puffs next to the body)
    merged = []
    for s, e in out:
        if merged and s - merged[-1][1] < 4:
            merged[-1] = (merged[-1][0], e)
        else:
            merged.append((s, e))
    res = []
    for s, e in merged:
        f = strip.crop((s, 0, e, strip.height))
        res.append(f.crop(f.getbbox()))
    return res


def scaled(img, k):
    w, h = max(1, round(img.width * k)), max(1, round(img.height * k))
    out = img.resize((w, h), Image.LANCZOS)
    a = np.array(out)
    a[:, :, 3] = np.where(a[:, :, 3] > 110, 255, 0)   # crisp edges again
    return Image.fromarray(a)


def pack(fs, cell=None, center_x=None):
    cw = cell[0] if cell else max(f.width for f in fs) + 2
    ch = cell[1] if cell else max(f.height for f in fs) + 2
    sheet = Image.new("RGBA", (cw * len(fs), ch), (0, 0, 0, 0))
    for i, f in enumerate(fs):
        cx = center_x if center_x is not None else cw // 2
        x = i * cw + max(0, min(cw - f.width, cx - f.width // 2))
        sheet.paste(f, (x, ch - 1 - f.height), f)
    return sheet, (cw, ch)


# --- cat: standing frame of the new art is ~153 px tall, the game's ~40 px
K_CAT = 40 / 153
new = [scaled(f, K_CAT) for r in (0, 1, 2) for f in frames("cat", r)]
cat = Image.open("assets/game/cat.png")
cat = cat.crop((0, 0, 127 * 128, 70))   # the original 127 frames: running this again replaces the appended ones
extra, _ = pack(new, (128, 70), center_x=62)
out = Image.new("RGBA", (cat.width + extra.width, 70), (0, 0, 0, 0))
out.paste(cat, (0, 0))
out.paste(extra, (cat.width, 0))
out.save("assets/game/cat.png")
print("cat.png:", out.width // 128, "frames (new from", cat.width // 128, ")", [len(frames("cat", r)) for r in (0, 1, 2)])

# --- hiding box
box = [scaled(f, K_CAT) for r in (3, 4) for f in frames("cat", r)]
eyes = np.array(box[-2])
lum = eyes[:, :, :3].astype(int)
green = (lum[:, :, 1] > lum[:, :, 0] + 30) & (lum[:, :, 1] > lum[:, :, 2] + 10)
grown = green.copy()
for dy in (-1, 0, 1):
    for dx in (-1, 0, 1):
        grown |= np.roll(np.roll(green, dy, 0), dx, 1)
empty = eyes.copy()
empty[grown & (eyes[:, :, 3] > 0), :3] = (18, 14, 12)
box.append(Image.fromarray(empty))
sheet, cell = pack(box)
sheet.save("assets/game/box_hide.png")
print("box_hide.png:", len(box), "frames, cell", cell)

# --- duck (~100 px tall -> ~45 in the sheet, ~15 px in the game)
duck = [scaled(f, 0.45) for r in range(6) for f in frames("duck", r)]
sheet, cell = pack(duck)
sheet.save("assets/game/enemies/duck.png")
print("duck.png:", len(duck), "frames, cell", cell, [len(frames("duck", r)) for r in range(6)])

# --- beaver boss (~110 px tall -> ~90 in the sheet, ~30 px in the game)
bv = [scaled(f, 0.8) for r in range(7) for f in frames("beaver", r)]
sheet, cell = pack(bv)
sheet.save("assets/game/enemies/beaver.png")
print("beaver.png:", len(bv), "frames, cell", cell, [len(frames("beaver", r)) for r in range(7)])
