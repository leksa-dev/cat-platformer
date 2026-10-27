# Run once from the project root: python3 tools/autumn_tiles.py (refuses to run twice)
# Adds an "Autumn" terrain to the tileset: grass tiles 0-10 recoloured to the Kopiec blocks' palette
# (olive-yellow grass, darker earth), appended to tiles.png as tiles 49-59, with the same peering bits.
import re, numpy as np
from PIL import Image
GRASS = [0, 1, 3, 4, 5, 6, 7, 8, 9, 10]
BASE = 49
src = Image.open("assets/game/tiles.png").convert("RGBA")
assert src.size == (2352, 48), src.size
a = np.array(src).astype(float) / 255
rgb = a[..., :3]
mx, mn = rgb.max(-1), rgb.min(-1)
v = mx; s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
d = np.maximum(mx - mn, 1e-6)
h = np.select([mx == r, mx == g], [((g - b) / d) % 6, (b - r) / d + 2], (r - g) / d + 4) / 6
green = (h > 0.15) & (h < 0.45) & (s > 0.25)
h2 = np.where(green, h - 0.058, h - 0.008) % 1
v2 = np.where(green, v * 0.72, v * 0.76)
# hsv -> rgb
i = np.floor(h2 * 6).astype(int) % 6; f = h2 * 6 - np.floor(h2 * 6)
p, q, t = v2 * (1 - s), v2 * (1 - s * f), v2 * (1 - s * (1 - f))
out = np.stack([np.choose(i, [v2, q, p, p, t, v2]), np.choose(i, [t, v2, v2, q, p, p]), np.choose(i, [p, p, t, v2, v2, q])], -1)
autumn = np.concatenate([out, a[..., 3:]], -1)
atlas = Image.new("RGBA", (48 * (BASE + 11), 48))
atlas.paste(src, (0, 0))
rec = Image.fromarray((autumn * 255).round().astype(np.uint8))
for k in range(11):
    atlas.paste(rec.crop((k * 48, 0, k * 48 + 48, 48)), ((BASE + k) * 48, 0))
atlas.save("assets/game/tiles.png")

ts = open("scenes/level/tileset.tres").read()
assert "terrain_4" not in ts
lines = ts.split("\n")
new = []
for ln in lines:
    m = re.match(r"^(\d+):0/(.*)$", ln)
    if m and int(m.group(1)) in GRASS:
        rest = m.group(2)
        rest = re.sub(r"/terrain = 0$", "/terrain = 4", rest)
        rest = re.sub(r"(terrains_peering_bit/\w+) = 0$", r"\1 = 4", rest)
        new.append(f"{int(m.group(1)) + BASE}:0/{rest}")
idx = lines.index("[resource]")
# the atlas source block ends right before [resource] (skip blank lines)
j = idx
while lines[j - 1].strip() == "": j -= 1
lines[j:j] = new
k = next(n for n, ln in enumerate(lines) if ln.startswith("terrain_set_0/terrain_3/color"))
lines[k + 1:k + 1] = ['terrain_set_0/terrain_4/name = "Autumn"', "terrain_set_0/terrain_4/color = Color(0.75, 0.55, 0.2, 1)"]
open("scenes/level/tileset.tres", "w").write("\n".join(lines))
print("added", len(new), "tile lines")
