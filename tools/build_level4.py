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

# ---------------- background: level 1's sky and trees as placeholders ----------------
node("Background", typ="CanvasLayer", props=["layer = -1"])
node("Far", "Background", "Sprite2D", props=["texture_repeat = 2", f'texture = ExtResource("{R("res://assets/game/lvl1/level1_parallax_background.png", "Texture2D")}")',
     "centered = false", "scale = Vector2(0.439, 0.439)", "region_enabled = true", "region_rect = Rect2(0, 0, 729, 410)", "metadata/scroll = 0.1", "metadata/vscroll = 0.0"])
node("Trees", "Background", "Sprite2D", props=["texture_repeat = 2", f'texture = ExtResource("{R("res://assets/game/lvl1/level1_parallax_foreground.png", "Texture2D")}")',
     "centered = false", "position = Vector2(0, 23)", "scale = Vector2(0.3, 0.3)", "region_enabled = true", "region_rect = Rect2(0, 0, 1067, 377)",
     "metadata/scroll = 0.4", "metadata/vscroll = 1.0"])
node("Ground", typ="TileMapLayer", props=[f'tile_set = ExtResource("{R("res://scenes/level/tileset.tres", "TileSet")}")', "scale = Vector2(0.333333, 0.333333)"])

# ---------------- 1. Kopiec Krakusa ----------------
inst("Oak", "res://scenes/objects/tree.tscn", tx(7), ty(5))
crumble(24, 10); crumble(26, 11)                       # eroded slope over a small pit
inst("Crow1", "res://scenes/enemies/crow/crow.tscn", tx(20), ty(2))   # jackdaw
inst("Checkpoint1", "res://scenes/objects/checkpoint.tscn", tx(38), ty(12))

# ---------------- footbridge over al. Powstańców Śląskich ----------------
traffic("Car1", 43, 67, 20, 110, (28, 10), (0.75, 0.2, 0.2))
traffic("Car2", 43, 67, 20, -150, (26, 10), (0.2, 0.35, 0.8), 1.0, 0.5)
traffic("Train", 67, 83, 20, 260, (96, 20), (0.3, 0.5, 0.35), 3.5, 0.0, 3)
inst("Cable1", "res://scenes/hazards/cable.tscn", tx(72), ty(13))   # catenary over the tracks
inst("Cable2", "res://scenes/hazards/cable.tscn", tx(79), ty(13), ["phase = 0.5"])
ladder(83, 11, 9)                                       # out of the road, onto ul. Parkowa

# ---------------- 2. ul. Parkowa + stadium ----------------
inst("Dog1", "res://scenes/enemies/dog/dog.tscn", tx(104), ty(12), ["patrol_radius = 24.0"])   # on a lead
inst("Checkpoint2", "res://scenes/objects/checkpoint.tscn", tx(114), ty(12))
ladder(133, 0, 12)                                     # floodlight mast
inst("Crow2", "res://scenes/enemies/crow/crow.tscn", tx(133), ty(4))

# ---------------- 3. Plac Lasoty + Park Bednarskiego ----------------
ladder(154, 5, 7)                                      # ivy up Villa Mira
ladder(169, 0, 7)                                      # Villa Julia's clock tower
inst("Checkpoint3", "res://scenes/objects/checkpoint.tscn", tx(183), ty(16))
inst("Dog2", "res://scenes/enemies/dog/dog.tscn", tx(188), ty(16), ["patrol_radius = 32.0"])
ladder(191, 10, 6)                                     # playground tower
inst("Slide", "res://scenes/objects/lvl3/pipe_tunnel.tscn", 194 * T, ty(11), ["width_tiles = 11"])   # tube slide (level for now)
inst("Swing", "res://scenes/objects/lvl3/moving_platform.tscn", 209.5 * T, ty(15), ["distance = 112.0"])   # outdoor gym
inst("Hedgehog1", "res://scenes/hazards/spiky.tscn", tx(212), ty(19))
inst("Hedgehog2", "res://scenes/hazards/spiky.tscn", tx(216), ty(19))
inst("Bat1", "res://scenes/enemies/bat/bat.tscn", tx(224), ty(9), ["zone = Vector2(160, 112)"])   # bat boxes on the quarry wall

hint(3, 5, "Kopiec Krakusa! Zejdź w dół, w stronę kładki.")
hint(21, 10, "Osuwająca się ziemia długo nie wytrzyma - nie stój na niej.")
hint(40, 12, "Pod kładką jeżdżą auta i pociągi. Przeskocz po znakach nad jezdnią.")
hint(152, 12, "Wespnij się po bluszczu na dach willi.")
hint(189, 16, "Wejdź na wieżę placu zabaw i zjedź rurą.")

# ---------------- coins, 1ups, diamonds ----------------
for i, (x, y) in enumerate([(tx(7), -12), (tx(32), ty(18) - 8), (tx(25), ty(14) - 8), (tx(50), ty(20) - 8), (83 * T, ty(12) - 26),
                            (tx(97), ty(9) - 8), (tx(133), -8), (tx(159), ty(5) - 24), (tx(214), ty(19) - 8), (227 * T, ty(10) - 8)]):
    inst(f"Coin{i + 1}", "res://scenes/objects/coin.tscn", x, y)
inst("Life1", "res://scenes/objects/life.tscn", tx(173), ty(7))
inst("Life2", "res://scenes/objects/life.tscn", tx(27), ty(18))    # hidden in the caponier, at the bottom of the moat
for i, (x, y) in enumerate([(tx(60), ty(20) - 8), (171 * T, ty(1) - 8), (tx(148), ty(8) - 8), (tx(76), ty(20) - 8)]):
    inst(f"Diamond{i + 1}", "res://scenes/objects/diamond.tscn", x, y, [f"gem = {i}"])

node("Spawn", typ="Marker2D", props=[pos(tx(5), ty(5))])
inst("Goal", "res://scenes/objects/goal.tscn", tx(259), ty(12))
inst("Cat", "res://scenes/player/cat.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")
inst("HUD", "res://scenes/ui/hud.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")

head = ["[gd_scene format=4]\n", '[ext_resource type="Script" path="res://scenes/level/level.gd" id="r0"]']
head += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for p, (i, t) in res.items()]
head.append(f'[ext_resource type="Texture2D" path="res://assets/game/backdrop_dirt.png" id="rbd"]')
out = "\n".join(head) + "\n\n" + '[node name="Level04" type="Node2D"]\nscript = ExtResource("r0")\nbackdrop = ExtResource("rbd")\nbackdrop_top = 336.0\n\n' + "\n".join(nodes)
open("scenes/level/level_04.tscn", "w").write(out)
print("nodes", len(nodes))
