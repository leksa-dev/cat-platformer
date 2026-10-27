# Usage: python3 tools/kladka_alpha.py assets/lvl4/kladkaParkowa/bloki.png /tmp/kp_rgba.png /tmp/kp_boxes.png
#        python3 tools/extract_kladka.py . /tmp/kp_rgba.png contact_sheet.png
# Cuts the footbridge/road sprites (checkerboard already removed) into assets/game/lvl4/kladka/<name>.png.
# Sprites are picked by a point on the sheet (as seen at 2000 px wide), so re-labelling doesn't break the names.
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
proj, rgba_path, sheet_path = sys.argv[1:4]
src = np.array(Image.open(rgba_path))
lab = np.load(rgba_path + ".lab.npy")
K = src.shape[1] / 2000
P = {
    "bridge_start": (300, 100), "bridge_sign": (660, 100), "deck_booth": (850, 95), "bridge_pillar": (1030, 95), "deck_lamp": (1230, 95),
    "bridge_lamp_pillar": (1445, 95), "bridge_stairs": (1780, 140), "bridge_short": (1340, 210),
    "pillar_a": (65, 300), "pillar_b": (170, 300), "pillar_s1": (255, 310), "pillar_s2": (320, 300), "mural": (550, 300), "mural_b": (800, 300),
    "mural_s": (910, 310), "slope": (1060, 280),
    "grass_a": (65, 415), "grass_b": (180, 420), "grass_slope": (295, 450), "grass_c": (405, 475), "grass_d": (520, 475),
    "rail_a": (370, 378), "road": (700, 378), "rail_s": (405, 422), "rail_b": (640, 445), "rail_c": (820, 440),
    "gantry": (780, 505), "lamp_double": (1040, 470), "lamp_a": (1008, 520), "lamp_b": (1130, 490), "lamp_c": (1077, 530),
    "portal": (1212, 450), "catenary": (1488, 450), "mast_a": (1650, 500), "mast_b": (1720, 480), "mast_c": (1840, 500), "mast_d": (1930, 460),
    "signal": (1773, 530), "tree_a": (75, 560), "tree_b": (210, 560), "tree_c": (345, 590), "tree_d": (460, 590), "tree_e": (575, 590),
    "bush_a": (690, 610), "bush_b": (790, 610), "bush_c": (875, 610), "grass_tall": (1930, 605), "tuft_a": (965, 625), "tuft_b": (1050, 630),
    "tuft_c": (1295, 625), "cabinet_a": (1595, 625), "cabinet_b": (1680, 632), "fence": (1810, 630), "post": (1640, 625),
}
out = f"{proj}/assets/game/lvl4/kladka"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1700, 1500), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for name, (px, py) in P.items():
    cx, cy = int(px * K), int(py * K)
    win = lab[max(0, cy - 8):cy + 9, max(0, cx - 8):cx + 9]
    ids, counts = np.unique(win[win > 0], return_counts=True)
    assert len(ids), name
    lid = ids[counts.argmax()]
    ys, xs = np.nonzero(lab == lid)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    px_ = src[y0:y1, x0:x1].copy()
    px_[..., 3] = np.where(lab[y0:y1, x0:x1] == lid, px_[..., 3], 0)
    im = Image.fromarray(px_); im.save(f"{out}/{name}.png"); sizes[name] = im.size
    t = im if im.size[0] <= 600 else im.resize((600, int(im.size[1] * 600 / im.size[0])))
    if x + t.size[0] > 1700: x = 0; y += rowh + 14; rowh = 0
    sheet.alpha_composite(t, (x, y + 12)); d.text((x, y), name, fill=(255, 255, 0))
    x += t.size[0] + 8; rowh = max(rowh, t.size[1] + 12)
json.dump(sizes, open(f"{out}/../kladka_sizes.json", "w"), indent=0)
sheet.save(sheet_path)
print(len(sizes), "sprites")
