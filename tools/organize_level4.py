# One-off, works on the scene's text: sorts level_04.tscn into folders by location (bare Node2D groups), each with sub-groups by kind:
#   1_Kopiec ... 8_Bernatka / Dekoracje_tyl, Dekoracje_przod, Platformy, Znajdzki, Wrogowie, Przeszkody, Inne
# Positions are global and the groups sit at the origin, so nothing moves. The old DecorBack / DecorFront disappear: "Dekoracje_tyl"
# is a group at z_index -1 (behind the ground, like DecorBack was by tree order), the backdrops (WorldBack, KopiecBg, CaveBack)
# are at -2, and a decoration that had its own z_index keeps its effective one (+1 to make up for the group).
# Usage: python3 tools/organize_level4.py scenes/level/level_04.tscn scenes/level/_tmp.tscn
import re, sys
src, dst = sys.argv[1:3]
text = open(src).read()
first = text.index("\n[node ")
head, body = text[:first + 1], text[first + 1:]
blocks = ["[node " + b for b in re.split(r"(?m)^\[node ", body) if b.strip()]
ext = {m.group(2): m.group(1) for m in re.finditer(r'\[ext_resource type="[^"]+"(?: uid="[^"]+")? path="([^"]+)" id="([^"]+)"\]', head)}
LOCATIONS = [("1_Kopiec", 0), ("2_Kladka", 64), ("3_Fort31", 128), ("4_Stadion", 192), ("5_Park", 256), ("6_Rynek", 329), ("7_Bulwary", 393), ("8_Bernatka", 457)]
SUBS = ["Dekoracje_tyl", "Dekoracje_przod", "Platformy", "Znajdzki", "Wrogowie", "Przeszkody", "Inne"]
PLATFORMS = ["float_platform.tscn", "pillar.tscn", "crumble.tscn", "moving_platform.tscn", "pier.tscn"]
COLLECT = ["/coin.tscn", "/diamond.tscn", "/life.tscn", "/snack.tscn", "/catnip.tscn", "/berry.tscn", "/berry_bush.tscn"]
def info(b):
    h = b.split("\n", 1)[0]
    g = lambda k: (re.search(k + r'="([^"]*)"', h) or [None, None])[1]
    inst = re.search(r'instance=ExtResource\("([^"]+)"\)', h)
    pos = re.search(r"(?m)^position = Vector2\(([-\d.e]+), ([-\d.e]+)\)", b)
    return dict(name=g("name"), parent=g("parent"), path=ext.get(inst.group(1), "") if inst else "", x=float(pos.group(1)) if pos else 0.0)
def location(x):
    name = LOCATIONS[0][0]
    for n, c in LOCATIONS:
        if x >= c * 16: name = n
    return name
def kind(i):
    p = i["path"]
    if "/enemies/" in p: return "Wrogowie"
    if "/hazards/" in p or p.endswith("water.tscn"): return "Przeszkody"
    if any(p.endswith(c) for c in COLLECT): return "Znajdzki"
    if any(p.endswith(c) for c in PLATFORMS): return "Platformy"
    return "Inne"
def set_z(b, z):
    if re.search(r"(?m)^z_index = ", b): return re.sub(r"(?m)^z_index = .*$", f"z_index = {z}", b)
    return b.rstrip("\n") + f"\nz_index = {z}\n\n" if b.endswith("\n\n") else b.rstrip("\n") + f"\nz_index = {z}\n"
root_blk = blocks[0]
pre, last, moved, groups = [], [], [], {}
FIRST = {"Background", "WorldBack", "KopiecBg", "CaveBack"}
for b in blocks[1:]:
    i = info(b)
    top = (i["parent"] or "").split("/")[0]
    if i["parent"] == "." and i["name"] in FIRST or top in ("Background", "WorldBack"):
        pre.append(set_z(b, -2) if i["parent"] == "." and i["name"] in ("WorldBack", "KopiecBg", "CaveBack") else b)
    elif i["parent"] == "." and i["name"] == "Ground": ground = b
    elif i["parent"] == "." and i["name"] in ("Spawn", "Goal", "Cat", "HUD"): last.append(b)
    elif i["parent"] == "." and i["name"] in ("DecorBack", "DecorFront"): pass   # replaced by the groups
    elif i["parent"] in ("DecorBack", "DecorFront"):
        back = i["parent"] == "DecorBack"
        m = re.search(r"(?m)^z_index = (-?\d+)", b)
        if back and m and int(m.group(1)) != 0: b = set_z(b, int(m.group(1)) + 1)
        moved.append((location(i["x"]), "Dekoracje_tyl" if back else "Dekoracje_przod", b))
    elif i["parent"] == ".": moved.append((location(i["x"]), kind(i), b))
    else: raise SystemExit("unexpected node parent: %s / %s" % (i["parent"], i["name"]))
used = {(l, k) for l, k, _ in moved}
out = [root_blk] + pre + [ground]
for loc, _ in LOCATIONS:
    if not any(l == loc for l, _ in used): continue
    out.append(f'[node name="{loc}" type="Node2D" parent="."]\n\n')
    for k in SUBS:
        if (loc, k) in used:
            out.append(f'[node name="{k}" type="Node2D" parent="{loc}"]\n' + ("z_index = -1\n" if k == "Dekoracje_tyl" else "") + "\n")
            out += [re.sub(r'parent="[^"]*"', f'parent="{loc}/{k}"', b.split("\n", 1)[0], count=1) + "\n" + b.split("\n", 1)[1] for l, kk, b in moved if l == loc and kk == k]
out += last
open(dst, "w").write(head + "".join(x if x.endswith("\n\n") or x.endswith("\n") and False else x.rstrip("\n") + "\n\n" for x in out).rstrip("\n") + "\n")
from collections import Counter
c = Counter((l, k) for l, k, _ in moved)
for loc, _ in LOCATIONS: print(loc, {k: c[(loc, k)] for k in SUBS if c[(loc, k)]})
print("nodes in:", len(blocks), " out:", sum(1 for x in out for _ in [0]), "(+ groups)")
