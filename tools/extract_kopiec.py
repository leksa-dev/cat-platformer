# Usage: python3 tools/extract_kopiec.py . contact_sheet.png  (needs Pillow, numpy, scipy)
# Cuts the Kopiec sprites out of assets/lvl4/kopiec/bloki.png into assets/game/lvl4/kopiec/<name>.png.
# Alpha is made binary at 128 (drops the red/yellow halo), each sprite keeps only its own connected blob(s).
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
proj = sys.argv[1]
src = np.array(Image.open(f"{proj}/assets/lvl4/kopiec/bloki.png").convert("RGBA"))
mask = src[..., 3] >= 128
lab, n = ndimage.label(mask)
objs = ndimage.find_objects(lab)
big = [i + 1 for i, s in enumerate(objs) if (lab[s] == i + 1).sum() >= 300]
order = sorted(big, key=lambda i: (objs[i - 1][0].start // 60, objs[i - 1][1].start))
ID = {k: lab_id for k, lab_id in enumerate(order)}
NAMES = {
    "block_a": 0, "block_b": 1, "block_c": 2, "float_a": 3, "float_s": 4, "island_a": 6, "island_b": 7,
    "block_s1": 8, "block_s2": 9, "block_xs": 10, "hump": 11, "block_d": 13, "block_e": 14, "block_f": 15, "block_g": 16,
    "block_s3": 17, "block_s4": 18, "block_s5": 19, "deck": 20, "ledge_a": 24, "ledge_b": 25, "ledge_c": 26,
    "ledge_long": 27, "ledge_d": 28,
    "fence_post": 21, "fence_a": 22, "fence_rope": 29, "fence_rope_long": 23, "fence_long": 37, "fence_s": 38,
    "sign_board": 30, "bin": 39, "info_board": 31, "signpost": 32, "flag": 33, "monument": 34, "chest": 35, "lamp": 36,
    "rock_a": 47, "rock_b": 48, "rock_c": 49, "rock_d": 50, "rock_e": 51,
    "tree_big": 46, "tree_b": 60, "tree_c": 56, "tree_d": 70, "tree_e": 72, "tree_f": 71, "bush_a": 57, "bush_b": 61,
    "bush_c": 65, "bush_d": 68, "bush_e": 73, "bush_f": 76, "bush_g": 77, "leaves": 82,
}
out = f"{proj}/assets/game/lvl4/kopiec"
os.makedirs(out, exist_ok=True)
sizes = {}
sheet = Image.new("RGBA", (1600, 1400), (40, 40, 60, 255)); d = ImageDraw.Draw(sheet); x = y = 0; rowh = 0
for name, k in NAMES.items():
    lid = ID[k]; sl = objs[lid - 1]
    y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
    keep = lab[y0:y1, x0:x1] == lid
    px = src[y0:y1, x0:x1].copy()
    px[..., 3] = np.where(keep, 255, 0)
    im = Image.fromarray(px)
    im.save(f"{out}/{name}.png")
    sizes[name] = im.size
    if x + im.size[0] > 1600: x = 0; y += rowh + 14; rowh = 0
    sheet.alpha_composite(im, (x, y + 12)); d.text((x, y), name, fill=(255, 255, 0))
    x += im.size[0] + 8; rowh = max(rowh, im.size[1] + 12)
json.dump(sizes, open(f"{out}/../kopiec_sizes.json", "w"), indent=0)
sheet.save(sys.argv[2])
print(len(sizes), "sprites")
