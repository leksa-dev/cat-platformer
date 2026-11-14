"""Cuts the extra Fort 31 assets (crusher slabs, spikes, window, wall, ruin, slab, winch, blocks) out of
assets/lvl4/fort31/trapdoors/sheet.png (dark vignette background) into assets/game/lvl4/fort/.
Each sprite is boxed by hand; inside its box the background is everything connected to the box edge that is not enclosed by the
sprite's near-black outline, so soft glows around the sprites drop out."""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "assets/lvl4/fort31/trapdoors/sheet.png"
OUT = "assets/game/lvl4/fort/"
# name: (x0, y0, x1, y1) in the 1536x1024 sheet
BOXES = {
    "crusher_big": (50, 0, 970, 570),
    "crusher_up": (1095, 0, 1430, 190),
    "crusher_mid": (1095, 195, 1430, 415),
    "crusher_slam": (1025, 425, 1490, 605),
    "window_arch": (35, 620, 222, 875),
    "wall_fort31": (252, 625, 822, 865),
    "ruin_fort31": (842, 650, 1075, 865),
    "slab_fort31": (1092, 765, 1350, 865),
    "winch": (1320, 650, 1515, 845),
    "spikes_long": (38, 915, 515, 1022),
    "spikes_short": (550, 920, 780, 1022),
    "tile_fort31": (845, 885, 992, 1015),
    "tile_crack": (1005, 885, 1155, 1015),
    "tile_brick": (1168, 885, 1318, 1015),
    "tile_ivy": (1330, 885, 1482, 1015),
}


def largest(mask):
    lab, n = ndimage.label(mask)
    if n == 0:
        return mask
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    return lab == (1 + int(np.argmax(sizes)))


def mask_enclosed(lum):
    """Method A: whatever the near-black outline encloses (crushers, spikes, winch: bright sprites with a closed dark outline)."""
    free = lum >= 34
    lab, n = ndimage.label(free)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])).tolist()) - {0}
    body = (lab > 0) & ~np.isin(lab, list(edge))
    body = ndimage.binary_closing(body, iterations=2)
    return largest(ndimage.binary_dilation(body, iterations=4))


def mask_flood(lum, thr=62):
    """Method B: everything that is not dark stuff connected to the box edge (walls, ruin, slab, tiles)."""
    lab, n = ndimage.label(lum < thr)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])).tolist()) - {0}
    body = ndimage.binary_opening(~np.isin(lab, list(edge)), iterations=2)
    return largest(ndimage.binary_dilation(largest(body), iterations=3))


METHOD = {"crusher_big": "A", "crusher_up": "A", "crusher_mid": "A", "crusher_slam": "A", "winch": "A", "spikes_long": "A", "spikes_short": "A"}


def cut(im, box, name):
    crop = im.crop(box).convert("RGBA")
    a = np.array(crop)
    lum = a[:, :, :3].astype(float) @ [0.3, 0.59, 0.11]
    sprite = mask_enclosed(lum) if METHOD.get(name) == "A" else mask_flood(lum)
    sprite = ndimage.binary_fill_holes(sprite)
    if name == "window_arch":   # the glow behind it is bright: keep only the arch shape (half ellipse on a rectangle)
        h, w = sprite.shape
        yy, xx = np.mgrid[0:h, 0:w]
        r = w / 2.0
        arch = ((xx - r) ** 2 + (yy - r) ** 2 <= r * r) | (yy >= r)
        sprite &= arch
    a[:, :, 3] = np.where(sprite, 255, 0)
    out = Image.fromarray(a)
    bbox = out.getbbox()
    out.crop(bbox).save(OUT + name + ".png")
    return out.crop(bbox).size


im = Image.open(SRC)
for name, box in BOXES.items():
    print(name, cut(im, box, name))
