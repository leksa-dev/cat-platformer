# Run from the project root: python3 tools/build_level5.py && godot --headless --script tools/paint_level5.gd && mv scenes/level/_tmp.tscn scenes/level/level_05.tscn
# Builds scenes/level/level_05.tscn: Podgórze. No platform mockups came with these parts, so the layout is our own:
# 1. Rynek Podgórski (columns 0-63): cobbled square with tenements (walkable roofs), planters, an advertising column,
#    the church of St Joseph in the middle (climb its gallery, buttresses and ridge up to the spire), balustrade, lamps.
# 2. Bulwary wiślane (columns 64-135): the riverside promenade with cyclists, broken by the Vistula twice; cross on the
#    moored boats or swim. The lair waits at the end of the promenade (Bernatka footbridge comes next).
import json
T = 16
def tx(x): return int(x * T + T // 2)
def ty(row): return round(row * T)

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
J = json.load(open("assets/game/lvl5/sizes.json"))
def tex(img): return f'texture = ExtResource("{R(f"res://assets/game/lvl5/{img}.png", "Texture2D")}")'
def deco(img, x, row, h_tiles=0, scale=0.333333, parent="DecorBack", flip=False):   # bottom-centre on row, at tile column x
    w, h = J["sizes"][img]
    if h_tiles: scale = round(h_tiles * T / h, 4)
    node(uid(img + "_"), parent, "Sprite2D", props=[pos(round(x * T + T / 2), ty(row) + 2), tex(img), "centered = false",
         f"offset = Vector2({-(w // 2)}, {-h})", f"scale = Vector2({scale}, {scale})"] + (["flip_h = true"] if flip else []))
def plat(name, img, x, walk_row, surface=None):   # one-way platform at walk_row; the sprite pokes `surface` px above it
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round(x * T + T / 2), ty(walk_row), [tex(img),
         f"surface = {J['surface'][img] if surface is None else surface}"])
def standing(name, img, x, ground_row, surface):   # a prop standing on the ground whose top (surface px below its top) is walkable
    h = J["sizes"][img][1] / 3
    plat(name, img, x, ground_row - (h - surface) / T, surface)
def pole(x, top, h):
    inst(uid("Pole"), "res://scenes/objects/lvl4/pole.tscn", round(x * T + T / 2), ty(top), [f"height_tiles = {h}"])
def lamp(x, ground_row, img="lamp"):   # a street lamp you can climb
    h = J["sizes"][img][1] / 3 / T
    deco(img, x, ground_row)
    pole(x, ground_row - h + 0.5, round(h - 0.5))
def bike(name, x0, x1, row, speed, color, gap=1.8, phase=0.0):   # cyclist along the promenade: jump over
    inst(name, "res://scenes/hazards/bike.tscn", x0 * T + 12, ty(row), [f"lane = {(x1 - x0) * T - 24}", f"speed = {speed}", f"gap = {gap}",
         f"phase = {phase}", f"color = Color({color[0]}, {color[1]}, {color[2]}, 1)"])
BG_SCALE = 0.4712   # the 2172 px backdrops -> 64 tiles
BG_PAD = 220        # px of sky added on top of them

node("Background", typ="CanvasLayer", props=["layer = -1"])
node("Sky", "Background", "Sprite2D", props=["texture_repeat = 2", tex("sky"), "centered = false", "scale = Vector2(0.6, 0.6)",
     "region_enabled = true", "region_rect = Rect2(0, 0, 2000, 300)", "metadata/scroll = 0.1", "metadata/vscroll = 0.0"])
node("WorldBack", typ="Node2D")
node("RynekBg", "WorldBack", "Sprite2D", props=[tex("rynek_bg"), "centered = false", pos(0, round(-BG_PAD * BG_SCALE)), f"scale = Vector2({BG_SCALE}, {BG_SCALE})"])
W = 64
node("BulwaryBg", "WorldBack", "Sprite2D", props=[tex("bulwary_bg"), "centered = false", pos(W * T, round(-BG_PAD * BG_SCALE)), f"scale = Vector2({BG_SCALE}, {BG_SCALE})"])
node("DecorBack", typ="Node2D")
node("Ground", typ="TileMapLayer", props=[f'tile_set = ExtResource("{R("res://scenes/level/tileset.tres", "TileSet")}")', "scale = Vector2(0.333333, 0.333333)"])
node("DecorFront", typ="Node2D")

# ---------------- 1. Rynek Podgórski ----------------
G = 17   # ground row of the square
for img, x in [("hedge_a", 1), ("tree_c", 13), ("bench", 21.5), ("bin", 23.5), ("cypress", 25), ("cypress", 36.5), ("chain_posts", 40),
               ("hedge_pink", 43.5), ("pot_a", 49.5), ("pot_b", 50.7), ("fence_hedge", 61), ("signpost", 63)]:
    deco(img, x, G)
deco("church", 30.5, G)
# tenements along the square: their roofs are walkable
standing("TenementA", "tenement_a", 6.5, G, 9); standing("TenementB", "tenement_b", 10.6, G, 9)
standing("TenementC", "tenement_c", 55.5, G, 9); standing("TenementD", "tenement_a", 60.4, G, 9)
standing("Planter1", "planter_tree_a", 15, G, 44); standing("Planter2", "planter_tree_b", 47.5, G, 44); standing("Planter3", "planter_tree_a", 52, G, 44)
standing("AdColumn", "ad_column", 18, G, 6)
standing("Balustrade", "balustrade", 44.5, G, 30)
# the church: gallery over the doors, buttress tops either side, the ridge, the spire; its corner towers are climbable
for name, x, row, w in [("Gallery", 30.5, 12.8, 7.6), ("ButtressL", 26.8, 9.4, 1.6), ("ButtressR", 34.2, 9.4, 1.6), ("Ridge", 30.5, 6.6, 3), ("Spire", 30.5, 3.4, 1.2)]:
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round(x * T + T / 2), ty(row), [f"ledge_width = {w * T}"])
pole(26.8, 9.4, 8); pole(34.2, 9.4, 8)   # corner towers, from the square up; pole(28.6, 6.6, 3); pole(30.5, 3.4, 3)
lamp(2.5, G); lamp(20, G); lamp(38.5, G); lamp(58, G)
inst("Crow1", "res://scenes/enemies/crow/crow.tscn", tx(16), ty(7))     # pigeons
inst("Crow2", "res://scenes/enemies/crow/crow.tscn", tx(46), ty(8))
inst("Dog1", "res://scenes/enemies/dog/dog.tscn", tx(23), ty(G), ["patrol_radius = 40.0"])
inst("Checkpoint1", "res://scenes/objects/checkpoint.tscn", tx(37.5), ty(G))
hint(3, G, "Rynek Podgórski! Na kościół wejdziesz po wieżyczkach w narożnikach.")

# ---------------- 2. Bulwary wiślane ----------------
# promenade (foreground strip) with two breaks where the river shows: cross on the moored boats or swim
PROM = [(0, 17), (38, 50), (64, 72)]   # promenade stretches, columns relative to W
for i, (a, b) in enumerate(PROM):
    node(f"Promenade{i + 1}", "DecorFront", "Sprite2D", props=["texture_repeat = 2", tex("promenade"), "centered = false",
         pos((W + a) * T, ty(G) - 260 + 2), f"scale = Vector2({BG_SCALE}, {BG_SCALE})", "region_enabled = true",
         f"region_rect = Rect2({round((a % 64) * T / BG_SCALE)}, 0, {round((b - a) * T / BG_SCALE)}, 724)"])
for i, (a, b) in enumerate([(17, 38), (50, 64)]):
    inst(f"River{i + 1}", "res://scenes/objects/water.tscn", (W + a) * T, ty(G + 1.5), [f"width_tiles = {b - a}", "depth_tiles = 6"])
    deco("quay_wall", W + a - 1.1, G + 1.5, parent="DecorFront"); deco("quay_wall", W + b + 1.1, G + 1.5, parent="DecorFront", flip=True)
plat("BoatSmall", "boat_small", W + 21.2, G + 0.6, 24); plat("Barge", "barge", W + 31.6, G + 0.4, 14)
plat("Houseboat", "houseboat", W + 57, G - 0.2, 19)
for img, x in [("lifebuoy", 1.5), ("bollard_rope", 15.7), ("bollard_rope", 39), ("crate_bush", 44), ("lifebuoy", 48.5), ("bollard_rope", 65),
               ("river_sign", 70.5)]:
    deco(img, W + x, G)
deco("gull", W + 33, G - 0.6); deco("gull", W + 26, G + 0.3)
bike("Bike1", W + 1, W + 17, G, 95, (0.2, 0.55, 0.85)); bike("Bike2", W + 1, W + 17, G, -150, (0.85, 0.3, 0.2), 2.5, 0.5)
bike("Bike3", W + 38, W + 50, G, 70, (0.3, 0.7, 0.3), 1.2)
inst("Crow3", "res://scenes/enemies/crow/crow.tscn", tx(W + 28), ty(10))  # gulls
inst("Crow4", "res://scenes/enemies/crow/crow.tscn", tx(W + 56), ty(10))
inst("Checkpoint2", "res://scenes/objects/checkpoint.tscn", tx(W + 2), ty(G))
inst("Checkpoint3", "res://scenes/objects/checkpoint.tscn", tx(W + 40), ty(G))
hint(W + 3, G, "Bulwary! Przeskakuj rowerzystów, a przez Wisłę przejdź po łodziach.")

# ---------------- coins, 1ups, diamonds: 10 coins and 4 diamonds per location ----------------
def pickups(tag, coins, gems):
    assert len(coins) == 10 and len(gems) == 4, tag
    for i, (x, y) in enumerate(coins):
        inst(f"Coin{tag}{i + 1}", "res://scenes/objects/coin.tscn", round(x), round(y))
    for i, (x, y) in enumerate(gems):
        inst(f"Diamond{tag}{i + 1}", "res://scenes/objects/diamond.tscn", round(x), round(y), [f"gem = {i}"])
def above(x, row, up=14): return (x * T + T / 2, ty(row) - up)
def node_y(name):   # walk row of a placed platform
    for n in nodes:
        if n.startswith(f'[node name="{name}"'):
            return float(n.split("position = Vector2(")[1].split(")")[0].split(", ")[1]) / T
pickups("R",
        [above(6.5, node_y("TenementA")), above(10.6, node_y("TenementB")), above(15, node_y("Planter1")), above(18, node_y("AdColumn")),
         above(28, 12.8), above(33, 12.8), above(30.5, 6.6), above(44.5, node_y("Balustrade")), above(55.5, node_y("TenementC")),
         above(60.4, node_y("TenementD"))],
        [above(26.8, 9.4), above(34.2, 9.4), above(52, node_y("Planter3")), above(9, G, 40)])
pickups("W",
        [above(W + 8, G, 30), above(W + 12, G, 30), above(W + 19, G + 0.6), above(W + 23, G + 0.6), above(W + 28, G + 0.4), above(W + 35, G + 0.4),
         above(W + 44, G, 30), above(W + 53, G - 0.2), above(W + 60, G - 0.2), above(W + 68, G)],
        [above(W + 27.5, G + 3.5, 0), above(W + 31.6, G + 0.4, 34), above(W + 57, G + 3.5, 0), above(W + 46, G, 44)])
inst("Life1", "res://scenes/objects/life.tscn", tx(30.5), ty(3.4) - 2)   # on top of the spire
inst("Life2", "res://scenes/objects/life.tscn", tx(W + 33), ty(G + 6))   # on the riverbed under the barge

node("Spawn", typ="Marker2D", props=[pos(tx(1), ty(G))])
inst("Goal", "res://scenes/objects/goal.tscn", tx(W + 70), ty(G))
inst("Cat", "res://scenes/player/cat.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")
inst("HUD", "res://scenes/ui/hud.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")

head = ["[gd_scene format=4]\n", '[ext_resource type="Script" path="res://scenes/level/level.gd" id="r0"]']
head += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for p, (i, t) in res.items()]
out = "\n".join(head) + "\n\n" + '[node name="Level05" type="Node2D"]\nscript = ExtResource("r0")\nmusic = "beach"\ncamera_bottom = 304.0\n\n' + "\n".join(nodes)
open("scenes/level/level_05.tscn", "w").write(out)
print("nodes", len(nodes))
