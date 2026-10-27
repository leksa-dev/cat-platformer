# Usage: python3 tools/extract_fort.py . contact_sheet.png   (needs Pillow, numpy, scipy)
# Cuts the Fort 31 sprites out of assets/lvl4/fort31/bloki.png into assets/game/lvl4/fort/<name>.png. Alpha is made
# binary at 128 (drops the red halo); sprites are picked by a point on the sheet (as seen at 2000 px wide).
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
proj, sheet_path = sys.argv[1:3]
src = np.array(Image.open(f"{proj}/assets/lvl4/fort31/bloki.png").convert("RGBA"))
mask = src[..., 3] >= 128
lab, n = ndimage.label(mask)
K = src.shape[1] / 2000
P = {
    "grass_a": (60, 75), "grass_b": (155, 75), "grass_c": (255, 75), "grass_d": (360, 75), "grass_e": (60, 160), "grass_f": (155, 160),
    "grass_strip": (500, 65), "grass_long": (720, 65), "grass_s": (905, 60), "grass_bush_long": (570, 165), "grass_block": (770, 165),
    "brick_s1": (880, 160), "brick_s2": (985, 165), "wall_ramp": (1095, 130), "battlement": (1325, 80), "grass_cube": (1540, 65),
    "rail_wood": (1675, 68), "rail_iron": (1845, 68), "lamp_pole": (1960, 100), "brick_chunk": (1197, 175), "brick_win_a": (1305, 215),
    "brick_win_b": (1425, 215), "brick_s3": (1550, 160), "crate": (1645, 160), "rocks": (1750, 148), "tree_big": (1880, 240),
    "wall_a": (60, 340), "wall_b": (180, 340), "wall_narrow": (288, 340), "wall_c": (370, 340), "wall_window": (485, 300),
    "wall_gate": (600, 300), "wall_door": (790, 300), "wall_d": (888, 340), "wall_e": (980, 330), "wall_f": (1095, 340), "wall_plain": (1197, 370),
    "wall_slope_b": (1320, 380), "wall_slope_c": (1480, 390), "bush": (1565, 280), "tree_s1": (1647, 260), "tree_s2": (1730, 270),
    "bush_s": (1805, 330), "ruin_a": (1625, 410), "ruin_b": (1765, 410), "ruin_c": (1915, 420), "stairs_a": (100, 570), "stairs_b": (250, 560),
    "stairs_c": (450, 590), "ledge_grass": (710, 515), "ledge_stone": (710, 598), "arch_a": (930, 560), "arch_b": (1160, 560),
    "arch_part": (1420, 590), "pillar_f": (1525, 570), "ruin_d": (1655, 570), "ruin_e": (1810, 580), "ruin_f": (1930, 570),
}
out = f"{proj}/assets/game/lvl4/fort"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1700, 1700), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for name, (px, py) in P.items():
    cx, cy = int(px * K), int(py * K)
    win = lab[max(0, cy - 8):cy + 9, max(0, cx - 8):cx + 9]
    ids, counts = np.unique(win[win > 0], return_counts=True)
    assert len(ids), name
    lid = ids[counts.argmax()]
    ys, xs = np.nonzero(lab == lid)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    px_ = src[y0:y1, x0:x1].copy()
    px_[..., 3] = np.where(lab[y0:y1, x0:x1] == lid, 255, 0)
    im = Image.fromarray(px_); im.save(f"{out}/{name}.png"); sizes[name] = im.size
    if x + im.size[0] > 1700: x = 0; y += rowh + 14; rowh = 0
    sheet.alpha_composite(im, (x, y + 12)); d.text((x, y), name, fill=(255, 255, 0))
    x += im.size[0] + 8; rowh = max(rowh, im.size[1] + 12)
# seamless brick fill for solid wall bodies: the middle of the plain wall
plain = Image.open(f"{out}/wall_plain.png"); w, h = plain.size
plain.crop((w // 6, h // 4, w - w // 6, h // 4 + 96)).save(f"{out}/brick_fill.png")
json.dump(sizes, open(f"{out}/../fort_sizes.json", "w"), indent=0)
sheet.save(sheet_path)
print(len(sizes), "sprites")
