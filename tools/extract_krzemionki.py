# Usage: python3 tools/extract_krzemionki.py . contact_sheet.png   (needs Pillow, numpy, scipy)
# Cuts the stadium sprites out of assets/lvl4/krzemionki/{bloki,items,items2}.png into assets/game/lvl4/stadion/<name>.png.
# Alpha is made binary at 128; sprites are picked by a point in the sheet's own pixels.
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
proj, sheet_path = sys.argv[1:3]
SHEETS = {
    "bloki": {
        "grass_dirt": (60, 90), "grass_stone": (60, 190), "grass_stone_long": (435, 190), "grass_stone_s": (870, 190), "bush_round": (480, 90),
        "bush_s": (785, 85), "bush_b": (980, 240), "stands_a": (165, 300), "stands_b": (190, 405), "stands_end": (40, 300),
        "stone_arch": (60, 490), "ledge_a": (330, 515), "ledge_b": (525, 515), "stairs_rail_a": (1070, 380), "stairs_rail_b": (915, 480),
        "stairs_plain": (950, 365), "floodlight_a": (1180, 180), "floodlight_b": (1290, 180), "floodlight_c": (1385, 180),
        "floodlight_d": (1475, 180), "fence_rail": (1265, 330), "panel_yellow": (1460, 340), "fence_mesh": (1340, 440), "flag": (1455, 560),
        "goal": (1395, 670), "bench": (1360, 940), "bin": (1240, 950), "bins": (1160, 950), "railing_yellow": (1020, 945),
        "hedge": (1160, 875), "hedge_b": (1295, 875), "bush_c": (1410, 875), "bush_d": (1470, 945), "board": (1475, 870),
        "dugout": (1395, 780), "planter": (1010, 885), "ledge_c": (110, 885), "ruin_a": (700, 885), "ruin_b": (870, 885),
    },
    "items2": {
        "kiosk": (520, 330), "umbrella": (1540, 430), "picnic_table": (1200, 470), "menu": (1210, 180), "welcome": (1520, 170),
        "table_round": (1430, 650), "chair": (1030, 650), "flowers_red": (150, 820), "flowers_white": (365, 820), "pot": (495, 820),
        "basket": (610, 820), "bin_wood": (1545, 800), "ashtray": (1690, 800), "fence_green": (1220, 800),
    },
    "items": {"table_set": (1600, 380), "table_set_b": (1580, 590), "crates": (1505, 790), "kiosk_b": (100, 560)},
}
out = f"{proj}/assets/game/lvl4/stadion"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1800, 1800), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for sheet_name, points in SHEETS.items():
    src = np.array(Image.open(f"{proj}/assets/lvl4/krzemionki/{sheet_name}.png").convert("RGBA"))
    lab, n = ndimage.label(src[..., 3] >= 128)
    for name, (cx, cy) in points.items():
        win = lab[max(0, cy - 10):cy + 11, max(0, cx - 10):cx + 11]
        ids, counts = np.unique(win[win > 0], return_counts=True)
        assert len(ids), name
        lid = ids[counts.argmax()]
        ys, xs = np.nonzero(lab == lid)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        px = src[y0:y1, x0:x1].copy()
        px[..., 3] = np.where(lab[y0:y1, x0:x1] == lid, 255, 0)
        im = Image.fromarray(px); im.save(f"{out}/{name}.png"); sizes[name] = im.size
        t = im if im.size[0] <= 500 else im.resize((500, int(im.size[1] * 500 / im.size[0])))
        if x + t.size[0] > 1800: x = 0; y += rowh + 14; rowh = 0
        sheet.alpha_composite(t, (x, y + 12)); d.text((x, y), name, fill=(255, 255, 0))
        x += t.size[0] + 8; rowh = max(rowh, t.size[1] + 12)
json.dump(sizes, open(f"{out}/../stadion_sizes.json", "w"), indent=0)
sheet.save(sheet_path)
print(len(sizes), "sprites")
