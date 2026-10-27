# Usage: python3 tools/extract_park.py . contact_sheet.png   (needs Pillow, numpy, scipy)
# Cuts the Park Bednarskiego sprites out of assets/lvl4/parkBednarskiego/{blocks,items}.png into
# assets/game/lvl4/park/<name>.png. Alpha is made binary at 128; sprites are picked by a point (blocks: sheet pixels,
# items: the sheet seen 2000 px wide).
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
proj, sheet_path = sys.argv[1:3]
SHEETS = {
    "blocks": {
        "long_a": (220, 110), "long_b": (565, 110), "float_a": (825, 120), "float_b": (1015, 120), "float_c": (1265, 120),
        "float_s": (1495, 115), "float_d": (1665, 115), "slope_a": (200, 300), "slope_b": (600, 300), "slope_c": (935, 310),
        "stairs_a": (1165, 320), "stairs_b": (1375, 320), "block_a": (1550, 300), "block_s": (1695, 315), "arch_bridge": (255, 490),
        "arch_s": (640, 490), "fence_block": (945, 490), "wood_fence_block": (1265, 495), "bench_block": (1590, 495),
        "corner": (150, 660), "t_block": (360, 660), "pillar_a": (500, 660), "ledge_a": (670, 640), "pillar_b": (860, 660),
        "pillar_c": (960, 660), "pillar_d": (1065, 660), "wedge_a": (1200, 650), "wedge_b": (1365, 650), "pillar_e": (1525, 660),
        "lamp": (1663, 780), "tiny_a": (75, 805), "tiny_b": (180, 805), "tiny_c": (285, 810), "tiny_d": (390, 810), "tiny_e": (480, 810),
        "tiny_f": (595, 810), "wood_bridge": (880, 805), "wood_bridge_b": (1360, 805),
    },
    "items": {
        "villa_mira": (190, 230), "villa_julia": (560, 230), "house_brick": (890, 270), "stairs_gate": (1210, 300),
        "playground_tower": (1555, 250), "playhouse": (1780, 290), "rocker": (1950, 315), "tree_a": (100, 470), "lamp_a": (230, 445),
        "lamp_b": (325, 445), "lamp_c": (400, 445), "lamp_d": (480, 445), "bench_a": (620, 445), "bench_b": (775, 448), "bin": (885, 445),
        "fence_wood": (1010, 425), "fence_iron": (1010, 490), "gate_pillars": (1190, 455), "gate_iron": (1345, 455),
        "stone_mound": (1500, 460), "pillar_stone": (1620, 455), "ruin": (1740, 460), "boulder": (1855, 455), "bollard": (1955, 455),
        "tree_b": (260, 585), "tree_pink": (435, 585), "spruce_a": (595, 575), "spruce_b": (695, 580), "bush_a": (820, 605),
        "bush_b": (955, 605), "bush_flower": (1090, 605), "bush_c": (1290, 560), "bush_d": (1410, 600), "bush_e": (1530, 600),
        "bush_yellow": (1630, 600), "bush_f": (1740, 600), "logs": (1880, 605),
    },
}
out = f"{proj}/assets/game/lvl4/park"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1800, 2000), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for sheet_name, points in SHEETS.items():
    src = np.array(Image.open(f"{proj}/assets/lvl4/parkBednarskiego/{sheet_name}.png").convert("RGBA"))
    K = 1.0 if sheet_name == "blocks" else src.shape[1] / 2000
    lab, n = ndimage.label(src[..., 3] >= 128)
    for name, (px, py) in points.items():
        cx, cy = int(px * K), int(py * K)
        win = lab[max(0, cy - 10):cy + 11, max(0, cx - 10):cx + 11]
        ids, counts = np.unique(win[win > 0], return_counts=True)
        assert len(ids), name
        lid = ids[counts.argmax()]
        ys, xs = np.nonzero(lab == lid)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        p = src[y0:y1, x0:x1].copy()
        p[..., 3] = np.where(lab[y0:y1, x0:x1] == lid, 255, 0)
        im = Image.fromarray(p); im.save(f"{out}/{name}.png"); sizes[name] = im.size
        t = im if im.size[0] <= 450 else im.resize((450, int(im.size[1] * 450 / im.size[0])))
        if x + t.size[0] > 1800: x = 0; y += rowh + 14; rowh = 0
        sheet.alpha_composite(t, (x, y + 12)); d.text((x, y), name, fill=(255, 255, 0))
        x += t.size[0] + 8; rowh = max(rowh, t.size[1] + 12)
# walkable surface (logical px below the sprite top): first row from which the middle half stays solid for 12 rows
# (skips railings, benches and grass tufts standing on the block)
surf = {}
for name in sizes:
    a = np.array(Image.open(f"{out}/{name}.png"))[..., 3] > 0; w = a.shape[1]
    solid = a[:, w // 4: 3 * w // 4].mean(1) > 0.97
    rows = [r for r in range(len(solid) - 12) if solid[r:r + 12].all()]
    surf[name] = round(rows[0] / 3, 1) if rows else 0
json.dump({"sizes": sizes, "surface": surf}, open(f"{out}/../park_sizes.json", "w"), indent=0)
sheet.save(sheet_path)
print(len(sizes), "sprites")
