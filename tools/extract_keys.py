# Usage: python3 tools/extract_keys.py .   (needs Pillow, numpy, scipy)
# The five keys from assets/temp/items.png (third row: silver, gold, red, green, blue) -> assets/game/key_<colour>.png,
# at 3x game density (~12 px tall in game), alpha made binary like the diamonds.
import sys, numpy as np
from PIL import Image
from scipy import ndimage
proj = sys.argv[1]
src = np.asarray(Image.open(f"{proj}/assets/temp/items.png").convert("RGB")).astype(int)
row = src[440:630, 40:800]
fg = np.abs(row - row[5, 5]).sum(2) > 60
lab, n = ndimage.label(ndimage.binary_closing(fg, iterations=2))
boxes = sorted([s for s in ndimage.find_objects(lab) if (s[0].stop - s[0].start) > 80], key=lambda s: s[1].start)
assert len(boxes) == 5, [(s[1].start, s[1].stop) for s in boxes]
for name, s in zip(["silver", "gold", "red", "green", "blue"], boxes):
    m = ndimage.binary_fill_holes(lab[s] > 0) & fg[s] | (lab[s] > 0) & fg[s]
    img = Image.fromarray(np.dstack([row[s], np.where(m, 255, 0)]).astype(np.uint8))
    h = 36; w = round(img.width * h / img.height)
    img = img.convert("RGBa").resize((w, h), Image.BOX).convert("RGBA")
    b = np.asarray(img).copy(); b[..., 3] = np.where(b[..., 3] > 110, 255, 0)
    Image.fromarray(b).save(f"{proj}/assets/game/key_{name}.png")
    print(name, img.size)
