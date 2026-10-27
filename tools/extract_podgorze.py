# Usage: python3 tools/extract_podgorze.py . contact_sheet.png   (needs Pillow, numpy, scipy)
# Cuts the level 5 sprites (Rynek Podgórski, bulwary wiślane) out of assets/lvl4/{rynekPodgorski,bulwaryWislane}/items.png
# into assets/game/lvl5/<name>.png. Alpha is made binary at 128; sprites are picked by a point in the sheet's own pixels.
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
proj, sheet_path = sys.argv[1:3]
SHEETS = {
    "rynekPodgorski/items.png": {
        "church": (230, 400), "church_stairs": (290, 800), "tenement_a": (565, 440), "tenement_b": (780, 440), "tenement_c": (1000, 440),
        "tree_a": (525, 200), "tree_b": (700, 180), "tree_c": (880, 170), "tree_d": (1180, 200), "tree_e": (1470, 200), "spruce": (1680, 220),
        "planter_tree_a": (1255, 470), "planter_tree_b": (1390, 470), "cypress": (1530, 390), "lamp": (1165, 600), "signpost": (1250, 640),
        "ad_column": (1460, 620), "hedge_a": (580, 595), "hedge_pink": (850, 590), "hedge_b": (1035, 590), "bench": (550, 675), "bin": (668, 675),
        "fence_hedge": (910, 690), "planter_box": (1345, 665), "stairs": (1650, 675), "wall": (790, 770), "iron_fence": (1040, 765),
        "balustrade": (1420, 830), "bollard": (712, 850), "chain_posts": (1100, 845), "pot_a": (480, 760), "pot_b": (580, 760),
    },
    "bulwaryWislane/items.png": {
        "barge_restaurant": (540, 140), "houseboat": (1420, 150), "boat_small": (220, 330), "barge": (730, 340), "bench_a": (150, 475),
        "bench_b": (380, 480), "bin_wood": (570, 470), "bollard_a": (690, 490), "bollard_b": (800, 500), "bollard_rope": (920, 510),
        "bollard_c": (1055, 495), "gull": (1165, 500), "lifebuoy": (1290, 470), "lamp_a": (1440, 600), "lamp_flower": (1555, 600),
        "lamp_b": (1670, 600), "quay_tree_a": (160, 660), "quay_tree_b": (400, 720), "bush_a": (560, 690), "bush_pink": (720, 720), "crate_bush": (720, 830),
        "bush_flower": (910, 800), "chain_fence": (625, 610), "river_fence": (1030, 610), "river_sign": (1310, 650), "quay_stairs": (1180, 800),
        "quay_wall": (1440, 790), "quay_ramp": (1640, 790),
    },
}
out = f"{proj}/assets/game/lvl5"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1800, 2400), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for path, points in SHEETS.items():
    src = np.array(Image.open(f"{proj}/assets/lvl4/{path}").convert("RGBA"))
    lab, n = ndimage.label(src[..., 3] >= 128)
    for name, (cx, cy) in points.items():
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
surf = {}
for name in sizes:
    a = np.array(Image.open(f"{out}/{name}.png"))[..., 3] > 0; w = a.shape[1]
    solid = a[:, w // 4: 3 * w // 4].mean(1) > 0.97
    rows = [r for r in range(len(solid) - 12) if solid[r:r + 12].all()]
    surf[name] = round(rows[0] / 3, 1) if rows else 0
json.dump({"sizes": sizes, "surface": surf}, open(f"{out}/sizes.json", "w"), indent=0)
sheet.save(sheet_path)
print(len(sizes), "sprites")
