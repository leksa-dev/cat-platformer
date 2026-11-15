"""Cuts animation frames out of a ChatGPT sprite sheet whose background is a soft gradient / glow (not transparent).

Sprites are found by local texture: pixels with a strong colour gradient (outlines, shading) are grown into blobs and their holes filled;
the smooth background and glows stay out. Label plates (flat dark rounded boxes with text) are dropped. Rows are found from the
vertical projection, frames inside a row from gaps in the horizontal one. Every frame of a sheet goes into one strip of equal cells,
feet on the bottom line, centred.

    python3 tools/extract_chatgpt_sheet.py <sheet.png> <out_prefix> [--skip x0,y0,x1,y1 ...] [--min-gap N]
prints the rows found (y range, frame count) and writes <out_prefix>_row<k>.png strips plus <out_prefix>_rows.json.
"""
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def sprite_mask(a, skips):
    rgb = a[:, :, :3].astype(float)
    lum = rgb @ [0.3, 0.59, 0.11]
    gx = np.abs(np.diff(lum, axis=1, append=lum[:, -1:]))
    gy = np.abs(np.diff(lum, axis=0, append=lum[-1:, :]))
    edge = (gx + gy) > 28
    m = ndimage.binary_closing(edge, iterations=3)
    m = ndimage.binary_fill_holes(m)
    m = ndimage.binary_opening(m, iterations=2)
    for x0, y0, x1, y1 in skips:
        m[y0:y1, x0:x1] = False
    lab, n = ndimage.label(m)
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        part = lab[sl] == i
        area = part.sum()
        h, w = part.shape
        if area < 150:
            m[sl][part] = False
            continue
        # label plates: flat, dark-grey, low-saturation boxes that fill their bounding box
        px = rgb[sl][part]
        sat = (px.max(axis=1) - px.min(axis=1)).mean()
        if area / (h * w) > 0.8 and sat < 20 and px.mean() < 90:
            m[sl][part] = False
    return m


def runs(profile, min_gap, min_len=8):
    out, start, gap = [], None, 0
    for i, v in enumerate(profile):
        if v:
            if start is None:
                start = i
            gap = 0
            end = i
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                if end - start >= min_len:
                    out.append((start, end + 1))
                start = None
    if start is not None and end - start >= min_len:
        out.append((start, end + 1))
    return out


def main():
    args = sys.argv[1:]
    src, prefix = args[0], args[1]
    skips, min_gap, counts, fixed_rows, cuts = [], 10, None, None, {}
    i = 2
    while i < len(args):
        if args[i] == "--skip":
            skips.append(tuple(int(v) for v in args[i + 1].split(",")))
            i += 2
        elif args[i] == "--rows":   # y ranges of the rows, when they can't be told apart automatically: 11-149,170-302,...
            fixed_rows = [tuple(int(v) for v in r.split("-")) for r in args[i + 1].split(",")]
            i += 2
        elif args[i] == "--cuts":   # hand-placed frame boundaries for one row: <row>:x0,x1,...,xn (sheet x)
            r, xs = args[i + 1].split(":")
            cuts[int(r)] = [int(v) for v in xs.split(",")]
            i += 2
        elif args[i] == "--counts":   # frames per row, when touching frames (dust, tails) can't be split by gaps
            counts = [int(v) for v in args[i + 1].split(",")]
            i += 2
        elif args[i] == "--min-gap":
            min_gap = int(args[i + 1])
            i += 2
        else:
            i += 1
    im = Image.open(src).convert("RGBA")
    a = np.array(im)
    m = sprite_mask(a, skips)
    rows = fixed_rows or runs(m.any(axis=1), 6, 20)
    info = []
    for k, (y0, y1) in enumerate(rows):
        band = m[y0:y1]
        cols = runs(band.any(axis=0), min_gap, 12)
        if k in cuts:
            xs = cuts[k]
            cols = [(xs[j], xs[j + 1]) for j in range(len(xs) - 1)]
        elif counts and k < len(counts) and len(cols) != counts[k]:
            n = counts[k]
            xa, xb = cols[0][0], cols[-1][1]
            prof = band.sum(axis=0)
            bounds = [xa]
            for j in range(1, n):
                ideal = int(xa + (xb - xa) * j / n)
                lo, hi = max(ideal - 30, bounds[-1] + 10), min(ideal + 30, xb - 10)
                bounds.append(lo + int(np.argmin(prof[lo:hi])))
            bounds.append(xb)
            cols = [(bounds[j], bounds[j + 1]) for j in range(n)]
        frames = []
        for x0, x1 in cols:
            fm = band[:, x0:x1]
            xs = np.where(fm.any(axis=0))[0]
            ys = np.where(fm.any(axis=1))[0]
            frames.append((x0 + xs[0], x0 + xs[-1] + 1, y0 + ys[0], y0 + ys[-1] + 1))
        cw = max(f[1] - f[0] for f in frames) + 4
        ch = max(f[3] - f[2] for f in frames) + 4
        strip = Image.new("RGBA", (cw * len(frames), ch), (0, 0, 0, 0))
        for j, (x0, x1, fy0, fy1) in enumerate(frames):
            crop = a[fy0:fy1, x0:x1].copy()
            crop[:, :, 3] = np.where(m[fy0:fy1, x0:x1], 255, 0)
            piece = Image.fromarray(crop)
            strip.paste(piece, (j * cw + (cw - (x1 - x0)) // 2, ch - 2 - (fy1 - fy0)), piece)
        strip.save(f"{prefix}_row{k}.png")
        info.append({"row": k, "y": [int(y0), int(y1)], "frames": len(frames), "cell": [int(cw), int(ch)]})
        print(k, (y0, y1), len(frames), "frames, cell", (int(cw), int(ch)), [(int(f[0]), int(f[1])) for f in frames])
    json.dump(info, open(f"{prefix}_rows.json", "w"))


main()
