# Usage: python3 tools/extract_bernatka.py . contact_sheet.png   (needs Pillow, numpy, scipy)
# Cuts the Bernatka footbridge sprites out of assets/lvl4/kladkaBernatka/{blocks,items}.png into
# assets/game/lvl4/bernatka/<name>.png. Alpha is made binary at 128; sprites are picked by a point (sheet seen 2000 px wide).
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
proj, sheet_path = sys.argv[1:3]
SHEETS = {
    "blocks": {
        "ledge_s": (75, 85), "ledge_m": (240, 85), "ledge_l": (470, 85), "ledge_xl": (775, 85), "pier_a": (1010, 85), "pier_b": (1140, 85),
        "pier_c": (1275, 85), "slope_a": (1460, 85), "slope_b": (1670, 85), "slope_c": (1880, 85),
        "quay_a": (145, 225), "quay_b": (390, 225), "quay_arch": (680, 225), "quay_c": (955, 225), "quay_arch_l": (1245, 225),
        "quay_d": (1505, 225), "quay_e": (1630, 225), "quay_arch_s": (1785, 225), "quay_f": (1930, 225),
        "railing_l": (205, 475), "railing_m": (505, 475), "railing_s": (655, 475), "lamp": (740, 470), "railing_post": (840, 475),
        "planter_a": (990, 485), "planter_b": (1160, 485), "bench": (1375, 480), "bin": (1570, 480), "chain_posts": (1790, 480),
        "ivy": (165, 595), "bush_a": (395, 600), "bush_b": (580, 600), "stone_s1": (800, 605), "stone_m": (925, 605), "stone_s2": (1050, 605),
        "rock": (1150, 605), "stone_cap": (1245, 605), "ledge_grass_s": (1340, 605), "ledge_grass_m": (1500, 605), "slope_s": (1665, 605),
        "ledge_grass_l": (1860, 605),
    },
    "items": {
        "duck": (1915, 255), "gull": (1760, 250), "pigeon": (1590, 250), "pretzel": (435, 240), "bagel": (85, 240),
        "boat_white": (240, 380), "boat_wood": (645, 380), "speedboat": (930, 395), "buoy": (1110, 380), "lifebuoy": (1640, 380),
        "lamp_a": (65, 545), "lamp_b": (190, 545), "lamp_double": (340, 545), "lamp_wall": (485, 545), "flower_hang": (625, 545),
        "planter": (795, 565), "bin": (955, 565), "bench": (1145, 575), "bike": (1410, 560), "scooter": (1690, 590),
        "padlock_gold": (1825, 555), "padlock_heart": (1920, 555),
    },
}
out = f"{proj}/assets/game/lvl4/bernatka"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1800, 1600), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for sheet_name, points in SHEETS.items():
    src = np.array(Image.open(f"{proj}/assets/lvl4/kladkaBernatka/{sheet_name}.png").convert("RGBA"))
    K = src.shape[1] / 2000
    lab, n = ndimage.label(src[..., 3] >= 128)
    for name, (px, py) in points.items():
        cx, cy = int(px * K), int(py * K)
        win = lab[max(0, cy - 12):cy + 13, max(0, cx - 12):cx + 13]
        ids, counts = np.unique(win[win > 0], return_counts=True)
        if len(ids):
            lid = ids[counts.argmax()]
        else:   # the point fell in a gap inside the sprite: take the nearest blob (within 40 px)
            ys, xs = np.nonzero(lab > 0); i = np.argmin((xs - cx) ** 2 + (ys - cy) ** 2)
            assert (xs[i] - cx) ** 2 + (ys[i] - cy) ** 2 < 1600, name
            lid = lab[ys[i], xs[i]]
        ys, xs = np.nonzero(lab == lid)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        p = src[y0:y1, x0:x1].copy()
        p[..., 3] = np.where(lab[y0:y1, x0:x1] == lid, 255, 0)
        im = Image.fromarray(p); im.save(f"{out}/{name}.png"); sizes[name] = im.size
        t = im if im.size[0] <= 450 else im.resize((450, int(im.size[1] * 450 / im.size[0])))
        if x + t.size[0] > 1800: x = 0; y += rowh + 14; rowh = 0
        sheet.alpha_composite(t, (x, y + 12)); d.text((x, y), name, fill=(255, 255, 0))
        x += t.size[0] + 8; rowh = max(rowh, t.size[1] + 12)
surf = {}
for name in sizes:
    a = np.array(Image.open(f"{out}/{name}.png"))[..., 3] > 0; w = a.shape[1]
    solid = a[:, w // 4: 3 * w // 4].mean(1) > 0.97
    rows = [r for r in range(len(solid) - 12) if solid[r:r + 12].all()]
    surf[name] = round(rows[0] / 3, 1) if rows else 0
json.dump({"sizes": sizes, "surface": surf}, open(f"{out}/../bernatka_sizes.json", "w"), indent=0)
sheet.save(sheet_path)
print(len(sizes), "sprites")
