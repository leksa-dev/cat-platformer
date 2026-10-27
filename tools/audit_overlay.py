"""Draws audit_level.gd's result over a level render: surfaces green (reachable) / red (not), poles blue, pickups as rings.
Usage: audit_overlay.py audit.json render.png out_prefix  -> out_prefix_<location>.png"""
import json, sys
from PIL import Image, ImageDraw, ImageFont

d = json.load(open(sys.argv[1]))
im = Image.open(sys.argv[2]).convert("RGB")
S = 2
im = im.resize((im.width * S, im.height * S), Image.NEAREST)
dr = ImageDraw.Draw(im)
font = ImageFont.load_default()
for s in d["surfaces"]:
    col = (0, 230, 0) if s["reach"] else (255, 30, 30)
    dr.line([(s["x0"] * S, s["y"] * S), (s["x1"] * S, s["y"] * S)], fill=col, width=4)
    if s["kind"] != "ground":
        dr.text((s["x0"] * S + 2, s["y"] * S - 12), s["name"], fill=(255, 255, 0), font=font)
for p in d["poles"]:
    dr.line([(p["x"] * S, p["y0"] * S), (p["x"] * S, p["y1"] * S)], fill=(60, 140, 255) if p["reach"] else (255, 0, 255), width=3)
for p in d["pickups"]:
    c = (0, 255, 255) if p["reach"] else (255, 0, 0)
    dr.ellipse([p["x"] * S - 7, p["y"] * S - 7, p["x"] * S + 7, p["y"] * S + 7], outline=c, width=3)
LOC = [("kopiec", 0), ("kladka", 64), ("fort", 128), ("stadion", 192), ("park", 256), ("rynek", 329), ("bulwary", 393), ("bernatka", 457)]
for i, (n, c0) in enumerate(LOC):
    c1 = LOC[i + 1][1] if i + 1 < len(LOC) else 506
    im.crop((c0 * 16 * S, 0, c1 * 16 * S, im.height)).save("%s_%s.png" % (sys.argv[3], n))
