# Removes the painted checkerboard from kladkaParkowa/bloki.png -> RGBA in scratchpad; labels the sprites.
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
import sys
src = np.array(Image.open(sys.argv[1]).convert("RGB")).astype(int)
mx, mn = src.max(-1), src.min(-1)
grey = (mx - mn < 14) & (mn > 196)          # checker squares: ~251 white and ~211 grey, unsaturated
lab, n = ndimage.label(grey)
sizes = ndimage.sum(grey, lab, range(1, n + 1))
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
white = ndimage.sum(grey & (mn > 238), lab, range(1, n + 1)); dark = ndimage.sum(grey & (mn < 225), lab, range(1, n + 1))
# enclosed checker pockets (between wires, under brackets) hold both checker tones; white sign text holds only one
bg = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > 5000 or (i + 1) in border or (white[i] >= 25 and dark[i] >= 25)])
# grow into the anti-aliased seam between squares and the sprites' soft edge by one pixel when that pixel is greyish
edge = ndimage.binary_dilation(bg) & ~bg & (mx - mn < 22) & (mn > 170)
bg |= edge
alpha = np.where(bg, 0, 255).astype(np.uint8)
rgba = np.dstack([src.astype(np.uint8), alpha])
Image.fromarray(rgba).save(sys.argv[2])
m = alpha > 0
m = ndimage.binary_opening(m, iterations=1)
lab2, n2 = ndimage.label(m)
objs = ndimage.find_objects(lab2)
boxes = []
for i, s in enumerate(objs):
    area = (lab2[s] == i + 1).sum()
    if area < 250: continue
    boxes.append((s[1].start, s[0].start, s[1].stop, s[0].stop, int(area), i + 1))
boxes.sort(key=lambda b: (b[1] // 70, b[0]))
out = Image.fromarray(rgba).convert("RGBA")
viz = Image.new("RGBA", out.size, (255, 0, 255, 255)); viz.alpha_composite(out)
d = ImageDraw.Draw(viz)
for k, b in enumerate(boxes):
    d.rectangle(b[:4], outline=(0, 255, 255)); d.text((b[0] + 2, b[1] + 2), str(k), fill=(255, 255, 0))
    print(k, b[:5])
viz.save(sys.argv[3])
np.save(sys.argv[2] + ".lab.npy", lab2)
import json; json.dump([list(b) for b in boxes], open(sys.argv[2] + ".boxes.json", "w"))
