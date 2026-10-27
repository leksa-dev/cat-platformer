# Usage: python3 tools/extract_enemies4.py .   (needs Pillow, numpy, scipy)
# assets/lvl4/enemies/pigeon.png (rows idle/run/attack/hurt/death) -> assets/game/enemies/pigeon.png
# assets/lvl4/enemies/rowery.png (rows road / city / mtb bike, 8 ride frames each) -> assets/game/enemies/bike_<kind>.png
# Strips of frames, bottom-centred on one shared canvas, 3x texture density (drawn at scale 1/3), alpha binary at 128.
import sys, numpy as np
from PIL import Image
from scipy import ndimage
P = sys.argv[1]
D = 3

def load(name):
    src = np.asarray(Image.open(f"{P}/assets/lvl4/enemies/{name}.png").convert("RGBA")).copy()
    src[:, :165, 3] = 0   # the row labels
    return src

def frames_of(src, y0, y1, max_effect_width=999, effects=True, centre="mass"):
    """The frames of one row, left to right: (image, x of the centre in it). Feathers/stars that sit by a frame join it
    (not when below its feet: that is dust and would lift the frame off the ground); effects=False drops them (bikes: the frame numbers).
    centre: "mass" = the body's centre of mass, "bbox" = the middle of the frame (bike wheels)."""
    mask = src[y0:y1, :, 3] > 128
    lab, k = ndimage.label(mask)
    objs = ndimage.find_objects(lab); areas = ndimage.sum(mask, lab, range(1, k + 1))
    mains = sorted([i for i in range(k) if areas[i] > 0.3 * areas.max()], key=lambda i: objs[i][1].start)
    groups = {i: [i + 1] for i in mains}
    for i in range(k):
        sy, sx = objs[i]
        if not effects or i in mains or areas[i] < 6 or min(sy.stop - sy.start, sx.stop - sx.start) <= 3 or sx.stop - sx.start > max_effect_width: continue
        cx = (sx.start + sx.stop) / 2
        j = min(mains, key=lambda j: abs((objs[j][1].start + objs[j][1].stop) / 2 - cx))
        if sx.start >= objs[j][1].start - 15 and sx.stop <= objs[j][1].stop + 15 and sy.stop <= objs[j][0].stop + 1:
            groups[j].append(i + 1)
    out = []
    for j in mains:
        sel = np.isin(lab, groups[j]); ys, xs = np.where(sel)
        crop = src[y0:y1].copy(); crop[~sel, 3] = 0; crop[sel, 3] = 255
        body = lab == j + 1
        cx = np.where(body)[1].mean() - xs.min() if centre == "mass" else (xs.max() - xs.min() + 1) / 2
        out.append((Image.fromarray(crop[ys.min():ys.max() + 1, xs.min():xs.max() + 1]), cx))
    return out

def strip(rows, S, path):
    FW = int(max(max(f.width - cx, cx) * 2 for v in rows.values() for f, cx in v) / S) + 2
    FH = int(max(f.height for v in rows.values() for f, _ in v) / S) + 2
    cells, table, idx = [], {}, 0
    for name, v in rows.items():
        table[name] = list(range(idx, idx + len(v)))
        for f, cx in v:
            f = f.resize((max(1, round(f.width / S)), max(1, round(f.height / S))), Image.BOX)
            b = np.asarray(f).copy(); b[..., 3] = np.where(b[..., 3] >= 128, 255, 0)
            c = Image.new("RGBA", (FW, FH)); c.paste(Image.fromarray(b), (int(FW / 2 - cx / S), FH - f.height))
            cells.append(c); idx += 1
    im = Image.new("RGBA", (FW * len(cells), FH))
    for i, c in enumerate(cells): im.paste(c, (i * FW, 0))
    im.save(path)
    print(path.split("/")[-1], f"{FW}x{FH}", len(cells), "frames", table)

# --- pigeon: 12 logical px tall standing; row bounds sit halfway between the row labels
src = load("pigeon")
bounds = [(0, 152), (152, 293), (293, 445), (445, 588), (588, 724)]
rows = {}
for name, (y0, y1) in zip(["idle", "run", "attack", "hurt", "death"], bounds):
    rows[name] = frames_of(src, y0, y1, 45 if name == "death" else 999)   # death: no ghost
S = rows["idle"][0][0].height / (12 * D)
strip(rows, S, f"{P}/assets/game/enemies/pigeon.png")

# --- bikes: 30 logical px tall with the rider
src = load("rowery")
for kind, (y0, y1) in zip(["road", "city", "mtb"], [(0, 221), (221, 461), (461, 724)]):
    fr = frames_of(src, y0, y1, effects=False, centre="bbox")
    assert len(fr) == 8, (kind, len(fr))
    strip({"ride": fr}, fr[0][0].height / (30 * D), f"{P}/assets/game/enemies/bike_{kind}.png")
