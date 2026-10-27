# Usage: python3 tools/level_grid.py map.png out_plain.png out_grid.png   (needs Pillow)
# Makes the plain and the gridded level screenshots from tools/render_level.gd's output: one grid square = one tile,
# a number every 5 columns / rows, and the names of the locations at their first column.
import sys
from PIL import Image, ImageDraw, ImageFont
src, plain, grid = sys.argv[1:4]
im = Image.open(src).convert("RGB"); im.save(plain)
S, T = 2, 32
g = im.resize((im.width * S, im.height * S), Image.NEAREST)
d = ImageDraw.Draw(g, "RGBA")
try: f = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 14)
except Exception: f = ImageFont.load_default()
for c in range(im.width // 16 + 1):
    x = c * T
    d.line([(x, 0), (x, g.height)], fill=(255, 0, 255, 200 if c % 5 == 0 else 70), width=2 if c % 5 == 0 else 1)
    if c % 5 == 0:
        for y in (2, g.height - 18):
            d.rectangle([x + 2, y, x + 2 + 8 * len(str(c)) + 4, y + 16], fill=(0, 0, 0, 170)); d.text((x + 4, y), str(c), fill=(255, 255, 0), font=f)
for r in range(im.height // 16 + 1):
    y = r * T
    d.line([(0, y), (g.width, y)], fill=(255, 0, 255, 200 if r % 5 == 0 else 70), width=2 if r % 5 == 0 else 1)
    for cx in range(0, g.width, 40 * T):
        d.rectangle([cx + 2, y + 2, cx + 26, y + 18], fill=(0, 0, 0, 170)); d.text((cx + 4, y + 2), str(r), fill=(0, 255, 255), font=f)
for name, c in [("Kopiec", 0), ("Kładka", 64), ("Fort 31", 128), ("Stadion", 192), ("Plac Lasoty (szary)", 256), ("Park Bednarskiego", 285),
                ("Rynek Podgórski", 358), ("Bulwary", 422), ("Kładka Bernatka", 486)]:
    d.rectangle([c * T + 4, 22, c * T + 12 + 9 * len(name), 42], fill=(0, 0, 0, 200)); d.text((c * T + 8, 24), name, fill=(255, 255, 255), font=f)
g.save(grid, optimize=True)
print(g.size)
