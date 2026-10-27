# Run from the project root: python3 tools/build_level4.py && godot --headless --script tools/paint_level4.gd && mv scenes/level/_tmp.tscn scenes/level/level_04.tscn
# Builds scenes/level/level_04.tscn: GREYBOX of Krzemionki (Kraków, Podgórze), from the user's sketch (docs/sketches).
# Kopiec Krakusa (oak on top, eroded slope with crumbling ledges, fort moat with a caponier) -> footbridge over
# al. Powstańców Śląskich (cars below, sign gantry as the way across, railway with a train) -> ul. Parkowa (bench,
# kiosk, dog on a lead, fence) -> Krzemionki stadium (stands, floodlight mast) -> Plac Lasoty (Villa Mira, Villa Julia
# with the clock tower) -> Park Bednarskiego in the old quarry (playground tower + tube slide, dip with hedgehogs and a
# swing-like slab, bats, limestone cliff) -> park gate, stairs down, lair. Tiles: paint_level4.gd.
T = 16
def tx(x): return int(x * T + T // 2)
def ty(row): return row * T

res = {}
def R(path, typ):
    if path not in res: res[path] = (f"r{len(res) + 1}", typ)
    return res[path][0]
nodes = []
def node(name, parent=".", typ=None, inst=None, props=()):
    head = f'[node name="{name}"' + (f' type="{typ}"' if typ else "") + f' parent="{parent}"' + (f' instance=ExtResource("{inst}")' if inst else "") + "]"
    nodes.append("\n".join([head, *props]) + "\n")
def pos(x, y): return f"position = Vector2({x}, {y})"
def inst(name, scene, x, y, props=()):
    node(name, inst=R(scene, "PackedScene"), props=[pos(x, y), *props])
_n = {}
def uid(base):
    _n[base] = _n.get(base, 0) + 1
    return f"{base}{_n[base]}"
def hint(x, row, text):
    inst(uid("Hint"), "res://scenes/objects/hint.tscn", tx(x), ty(row), [f'text = "{text}"'])
def ladder(x, top, height):  # also stands in for ivy and the floodlight mast
    inst(uid("Ladder"), "res://scenes/objects/lvl3/ladder.tscn", tx(x), ty(top), [f"height_tiles = {height}"])
def crumble(x, row, w=2):
    inst(uid("Crumble"), "res://scenes/objects/crumble.tscn", x * T, ty(row), [f"width_tiles = {w}"])
def traffic(name, x0, x1, row, speed, size, color, gap=1.5, phase=0.0, damage=2):
    inst(name, "res://scenes/hazards/traffic.tscn", x0 * T + size[0] // 2, ty(row), [
        f"lane = {(x1 - x0) * T - size[0]}", f"speed = {speed}", f"gap = {gap}", f"phase = {phase}", f"damage = {damage}",
        f"hit_size = Vector2({size[0]}, {size[1]})", f"hit_offset = Vector2(0, {-size[1] / 2})", f"color = Color({color[0]}, {color[1]}, {color[2]}, 1)"])

def kdeco(img, x, row, parent="DecorBack"):  # Kopiec sprite, bottom-centre on the ground at tile column x
    w, h = KSIZE[img]
    node(uid(img + "_"), parent, "Sprite2D", props=[pos(round(x * T + T / 2), ty(row) + 2), f'texture = ExtResource("{R(f"res://assets/game/lvl4/kopiec/{img}.png", "Texture2D")}")',
        "centered = false", f"offset = Vector2({-(w // 2)}, {-h})", "scale = Vector2(0.333333, 0.333333)"])
def plat(name, img, x, row):  # floating grass block, walkable top at row, centred on tile column x
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round(x * T + T / 2), ty(row), [f'texture = ExtResource("{R(f"res://assets/game/lvl4/kopiec/{img}.png", "Texture2D")}")'])
KSIZE = __import__("json").load(open("assets/game/lvl4/kopiec_sizes.json"))

# ---------------- background: sunset sky over Kraków, behind the whole level ----------------
node("Background", typ="CanvasLayer", props=["layer = -1"])
node("Sky", "Background", "Sprite2D", props=["texture_repeat = 2", f'texture = ExtResource("{R("res://assets/game/lvl4/sky_city.png", "Texture2D")}")',
     "centered = false", "scale = Vector2(0.53, 0.53)", "region_enabled = true", "region_rect = Rect2(0, 0, 1400, 340)", "metadata/scroll = 0.1", "metadata/vscroll = 0.0"])   # sunset over the Old Town, from the Kopiec backdrop

# ---------------- 1. Kopiec Krakusa (layout from assets/lvl4/kopiec/platforms.png, 64 tiles) ----------------
# the backdrop is locked to the world here (as in the mockup): its mound sits under the summit deck
node("KopiecBg", typ="Sprite2D", props=[f'texture = ExtResource("{R("res://assets/game/lvl4/kopiec/bg.png", "Texture2D")}")',
     "centered = false", "position = Vector2(0, -20)", "scale = Vector2(0.5, 0.5)"])
node("CaveBack", typ="Sprite2D", props=["texture_repeat = 2", f'texture = ExtResource("{R("res://assets/game/backdrop_dirt.png", "Texture2D")}")',
     "centered = false", pos(4 * T, 12 * T), "scale = Vector2(0.333333, 0.333333)", "region_enabled = true", f"region_rect = Rect2(0, 0, {10 * T * 3}, {4 * T * 3})"])
node("DecorBack", typ="Node2D")
for img, x, row in [("tree_big", 1, 9), ("tree_b", 6, 10), ("sign_board", 3, 10), ("fence_a", 8, 10), ("leaves", 7, 16), ("chest", 11, 16),
                    ("bush_b", 16, 16), ("tree_d", 20, 15), ("rock_b", 24.5, 16), ("signpost", 28.5, 14), ("tree_c", 36.5, 17),
                    ("fence_long", 36.5, 8), ("monument", 35, 8), ("flag", 38.3, 8), ("sign_board", 39.5, 15), ("bush_c", 42, 16),
                    ("tree_e", 46.5, 14), ("rock_d", 50, 17), ("bush_a", 52.5, 17), ("tree_b", 56, 14), ("info_board", 57, 14),
                    ("tree_f", 60, 10), ("fence_long", 62, 10), ("lamp", 63.3, 10)]:
    kdeco(img, x, row)
node("Ground", typ="TileMapLayer", props=[f'tile_set = ExtResource("{R("res://scenes/level/tileset.tres", "TileSet")}")', "scale = Vector2(0.333333, 0.333333)"])
for name, img, x, row in [("F1", "island_b", 14.5, 8), ("F2", "float_a", 17, 11), ("Deck", "deck", 36.5, 8), ("F4", "ledge_long", 34.9, 12),
                          ("F5", "float_a", 39.0, 10), ("F6", "island_a", 43.25, 9), ("F7", "ledge_b", 48.25, 11), ("F8", "ledge_a", 52.4, 13)]:  # F5 sits under the deck: jump up through it
    plat(name, img, x, row)
crumble(21, 13, 2)                                     # eroded slope
inst("Crow1", "res://scenes/enemies/crow/crow.tscn", tx(15), ty(6))   # jackdaws
inst("Crow2", "res://scenes/enemies/crow/crow.tscn", tx(46), ty(7))
inst("Crow3", "res://scenes/enemies/crow/crow.tscn", tx(53), ty(10))
inst("DogK1", "res://scenes/enemies/dog/dog.tscn", tx(36.5), ty(17), ["patrol_radius = 20.0"])
inst("DogK2", "res://scenes/enemies/dog/dog.tscn", tx(51), ty(17), ["patrol_radius = 24.0"])
inst("Checkpoint0", "res://scenes/objects/checkpoint.tscn", tx(24), ty(16))
inst("Checkpoint1", "res://scenes/objects/checkpoint.tscn", tx(61), ty(10))

# everything after the Kopiec, shifted right by S tiles
S = 21
# ---------------- footbridge over al. Powstańców Śląskich ----------------
traffic("Car1", 43 + S, 67 + S, 20, 110, (28, 10), (0.75, 0.2, 0.2))
traffic("Car2", 43 + S, 67 + S, 20, -150, (26, 10), (0.2, 0.35, 0.8), 1.0, 0.5)
traffic("Train", 67 + S, 83 + S, 20, 260, (96, 20), (0.3, 0.5, 0.35), 3.5, 0.0, 3)
inst("Cable1", "res://scenes/hazards/cable.tscn", tx(72 + S), ty(13))   # catenary over the tracks
inst("Cable2", "res://scenes/hazards/cable.tscn", tx(79 + S), ty(13), ["phase = 0.5"])
ladder(83 + S, 11, 9)                                   # out of the road, onto ul. Parkowa

# ---------------- 2. ul. Parkowa + stadium ----------------
inst("Dog1", "res://scenes/enemies/dog/dog.tscn", tx(104 + S), ty(12), ["patrol_radius = 24.0"])   # on a lead
inst("Checkpoint2", "res://scenes/objects/checkpoint.tscn", tx(114 + S), ty(12))
ladder(133 + S, 0, 12)                                 # floodlight mast
inst("Crow4", "res://scenes/enemies/crow/crow.tscn", tx(133 + S), ty(4))

# ---------------- 3. Plac Lasoty + Park Bednarskiego ----------------
ladder(154 + S, 5, 7)                                  # ivy up Villa Mira
ladder(169 + S, 0, 7)                                  # Villa Julia's clock tower
inst("Checkpoint3", "res://scenes/objects/checkpoint.tscn", tx(183 + S), ty(16))
inst("Dog2", "res://scenes/enemies/dog/dog.tscn", tx(188 + S), ty(16), ["patrol_radius = 32.0"])
ladder(191 + S, 10, 6)                                 # playground tower
inst("Slide", "res://scenes/objects/lvl3/pipe_tunnel.tscn", (194 + S) * T, ty(11), ["width_tiles = 11"])   # tube slide (level for now)
inst("Swing", "res://scenes/objects/lvl3/moving_platform.tscn", (209.5 + S) * T, ty(15), ["distance = 112.0"])   # outdoor gym
inst("Hedgehog1", "res://scenes/hazards/spiky.tscn", tx(212 + S), ty(19))
inst("Hedgehog2", "res://scenes/hazards/spiky.tscn", tx(216 + S), ty(19))
inst("Bat1", "res://scenes/enemies/bat/bat.tscn", tx(224 + S), ty(9), ["zone = Vector2(160, 112)"])   # bat boxes on the quarry wall

hint(3, 10, "Kopiec Krakusa! Wejdź na szczyt, a potem zejdź w stronę kładki.")
hint(20, 15, "Osuwająca się ziemia długo nie wytrzyma - nie stój na niej.")
hint(40 + S, 12, "Pod kładką jeżdżą auta i pociągi. Przeskocz po znakach nad jezdnią.")
hint(152 + S, 12, "Wespnij się po bluszczu na dach willi.")
hint(189 + S, 16, "Wejdź na wieżę placu zabaw i zjedź rurą.")

# ---------------- coins, 1ups, diamonds ----------------
for i, (x, y) in enumerate([(tx(9), ty(16) - 8), (17 * T, ty(11) - 14), (tx(36), ty(8) - 14), (43.25 * T + 8, ty(9) - 14), (tx(30.5), ty(17) - 8),
                            (tx(50 + S), ty(20) - 8), (tx(97 + S), ty(9) - 8), (tx(133 + S), -8), (tx(159 + S), ty(5) - 24), ((227 + S) * T, ty(10) - 8)]):
    inst(f"Coin{i + 1}", "res://scenes/objects/coin.tscn", x, y)
inst("Life1", "res://scenes/objects/life.tscn", tx(173 + S), ty(7))
inst("Life2", "res://scenes/objects/life.tscn", tx(11), ty(16) - 18)    # hidden in the cave under the start, on the chest
for i, (x, y) in enumerate([(tx(60 + S), ty(20) - 8), ((171 + S) * T, ty(1) - 8), (tx(148 + S), ty(8) - 8), (tx(76 + S), ty(20) - 8)]):
    inst(f"Diamond{i + 1}", "res://scenes/objects/diamond.tscn", x, y, [f"gem = {i}"])

node("Spawn", typ="Marker2D", props=[pos(tx(4), ty(10))])
inst("Goal", "res://scenes/objects/goal.tscn", tx(259 + S), ty(12))
inst("Cat", "res://scenes/player/cat.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")
inst("HUD", "res://scenes/ui/hud.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")

head = ["[gd_scene format=4]\n", '[ext_resource type="Script" path="res://scenes/level/level.gd" id="r0"]']
head += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for p, (i, t) in res.items()]
head.append(f'[ext_resource type="Texture2D" path="res://assets/game/backdrop_dirt.png" id="rbd"]')
out = "\n".join(head) + "\n\n" + '[node name="Level04" type="Node2D"]\nscript = ExtResource("r0")\nbackdrop = ExtResource("rbd")\nbackdrop_top = 336.0\n\n' + "\n".join(nodes)
open("scenes/level/level_04.tscn", "w").write(out)
print("nodes", len(nodes))
