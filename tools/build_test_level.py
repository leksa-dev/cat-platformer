"""Generates scenes/level/level_test.tscn (the mechanics test level, "Poligon") and paints its grey stone ground.

A hub with seven doors (press down at a door) and seven rooms to the right of it, each with one group of mechanics laid out station by
station, with signs. After this the scene is meant to be edited by hand in Godot; the generator refuses to overwrite it without --force.

    python3 tools/build_test_level.py --force
"""
import json
import subprocess
import sys
from pathlib import Path

OUT = Path("scenes/level/level_test.tscn")
T = 16            # px per tile
FLOOR = 17        # row of the walkable top (y = 272), like the campaign levels
BOTTOM = 22       # last solid row of the floor slab
TOP = -10         # ceiling row of every room
STRIDE = 84       # columns between rooms (the gap keeps neighbours out of the camera after a respawn)
HUB_W = 64

ROOMS = ["RUCH", "WSPINANIE", "PLATFORMY", "PRZESZKODY", "WODA I SURFING", "WROGOWIE I BROŃ", "SEKRETY"]

ext = {}          # key -> (type, path)
nodes = []        # text blocks
solid = []        # (c0, c1, r0, r1) inclusive, in tiles
cut = []          # carved out of `solid` (pits, pools)


def res(key, path, typ="PackedScene"):
    ext[key] = (typ, path)
    return key


def v2(x, y):
    return f"Vector2({x:g}, {y:g})"


def fmt(v):
    if isinstance(v, str) and v.startswith(("Vector2", "Rect2", "NodePath", "ExtResource", "Color", "Array")):
        return v
    if isinstance(v, str):
        return '"' + v.replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(v, bool):
        return "true" if v else "false"
    return f"{v:g}" if isinstance(v, float) else str(v)


def inst(name, key, x, y, **props):
    lines = [f'[node name="{name}" parent="." instance=ExtResource("{key}")]', f"position = {v2(x, y)}"]
    lines += [f"{k} = {fmt(v)}" for k, v in props.items()]
    nodes.append("\n".join(lines) + "\n")


def marker(name, x, y):
    nodes.append(f'[node name="{name}" type="Marker2D" parent="."]\nposition = {v2(x, y)}\n')


def S(c0, c1, r0, r1):
    solid.append((c0, c1, r0, r1))


def C(c0, c1, r0, r1):
    cut.append((c0, c1, r0, r1))


# ---- scenes
SIGN = res("sign", "res://scenes/objects/sign.tscn")
WARP = res("warp", "res://scenes/objects/secret/warp.tscn")
CHECK = res("check", "res://scenes/objects/checkpoint.tscn")
HINT = res("hint", "res://scenes/objects/hint.tscn")
CRATE = res("crate", "res://scenes/objects/crate.tscn")
LEDGE = res("t_ledge", "res://assets/game/lvl4/kopiec/ledge_b.png", "Texture2D")
FLOATA = res("t_float", "res://assets/game/lvl4/kopiec/float_a.png", "Texture2D")
BRICK = res("t_brick", "res://assets/game/lvl4/fort/brick_fill.png", "Texture2D")
CAP = res("t_cap", "res://assets/game/lvl4/fort/ledge_stone.png", "Texture2D")
SEA_TOP = res("t_seatop", "res://assets/game/beach/sea_top.png", "Texture2D")
SEA = res("t_sea", "res://assets/game/beach/sea.png", "Texture2D")


def sign(name, x, y, text, width=120, title=False):
    inst(name, SIGN, x, y, text=text, width=width, **({"title": True} if title else {}))


def door(name, x, y, target, label, room=None):
    props = dict(target=f"NodePath(\"../{target}\")", door=True, label=label, size="Vector2(16, 32)")
    if room:
        props["room"] = f"Rect2({room[0]:g}, {room[1]:g}, {room[2]:g}, {room[3]:g})"
    inst(name, WARP, x, y - 32, **props)


# ======================================================== hub
S(0, 0, TOP, BOTTOM)
S(HUB_W - 1, HUB_W - 1, TOP, BOTTOM)
S(0, HUB_W - 1, TOP, TOP + 1)
S(0, HUB_W - 1, FLOOR, BOTTOM)
sign("HubTitle", 7 * T, (FLOOR - 4) * T, "POLIGON - test mechanizmów\nStań w drzwiach i naciśnij DÓŁ.\nGOD MODE i latanie włączysz w dev menu (F1).", width=190, title=True)
marker("Spawn", 3 * T, FLOOR * T - 2)

room_rects = []
for i, name in enumerate(ROOMS):
    x0 = (i + 1) * STRIDE      # first column of room i
    room_rects.append((x0 * T, (TOP) * T, 64 * T, (BOTTOM + 1 - TOP) * T))
    hx = (6 + i * 8) * T       # hub door x
    marker(f"HubOut{i + 1}", hx + 40, FLOOR * T - 2)   # beside the door, not inside it
    marker(f"R{i + 1}In", (x0 + 7) * T, FLOOR * T - 2)
    door(f"HubDoor{i + 1}", hx, FLOOR * T, f"R{i + 1}In", f"{i + 1}. {name}", room_rects[i])
    # room shell
    S(x0, x0, TOP, BOTTOM)
    S(x0 + 63, x0 + 63, TOP, BOTTOM)
    S(x0, x0 + 63, TOP, TOP + 1)
    S(x0, x0 + 63, FLOOR, BOTTOM)
    door(f"R{i + 1}Exit", (x0 + 3) * T, FLOOR * T, f"HubOut{i + 1}", "< hub")
    inst(f"R{i + 1}Check", CHECK, (x0 + 7) * T, FLOOR * T)
    sign(f"R{i + 1}Title", (x0 + 8) * T, (FLOOR - 6) * T, f"{i + 1}. {name}", width=140, title=True)


def X(i, c):
    """x of local column c in room i (0-based room index)."""
    return ((i + 1) * STRIDE + c) * T


def room_x0(i):
    return (i + 1) * STRIDE


# ======================================================== 1. RUCH
i = 0
x0 = room_x0(i)
sign("R1A", X(i, 13), (FLOOR - 2) * T, "SKOK Z ROZBIEGU\nSpacja trzymana = wyżej", width=110)
C(x0 + 15, x0 + 17, FLOOR, BOTTOM)
inst("R1Check2", CHECK, X(i, 21), FLOOR * T)
sign("R1B", X(i, 22), (FLOOR - 3) * T, "WALL-JUMP\nWbij się w ścianę i skacz", width=110)
S(x0 + 26, x0 + 27, 7, FLOOR - 3)    # shaft: left wall leaves a 2-row doorway at the floor, right wall is full; 3 tiles between
S(x0 + 31, x0 + 32, 7, FLOOR - 1)
inst("R1Check3", CHECK, X(i, 40), FLOOR * T)
sign("R1C", X(i, 43), (FLOOR - 3) * T, "DASH (Shift / B)\nw powietrzu, raz na skok", width=110)
C(x0 + 44, x0 + 50, FLOOR, BOTTOM)
inst("R1Cat", res("catnip", "res://scenes/objects/catnip.tscn"), X(i, 55), FLOOR * T)
sign("R1D", X(i, 54), (FLOOR - 3) * T, "KOCIMIĘTKA\nprzyspiesza i podbija skok", width=110)
C(x0 + 58, x0 + 61, FLOOR, BOTTOM)
inst("R1Check4", CHECK, X(i, 57), FLOOR * T)

# ======================================================== 2. WSPINANIE
i = 1
x0 = room_x0(i)
tree = res("tree", "res://scenes/objects/tree.tscn")
vine = res("vine", "res://scenes/objects/vine.tscn")
ladder = res("ladder", "res://scenes/objects/lvl3/ladder.tscn")
chain = res("chain", "res://scenes/objects/lvl4/chain.tscn")
pole = res("pole", "res://scenes/objects/lvl4/pole.tscn")
pillar = res("pillar", "res://scenes/objects/lvl4/pillar.tscn")
inst("R2Tree", tree, X(i, 13), FLOOR * T)
sign("R2TreeSign", X(i, 13), (FLOOR - 7) * T, "DRZEWO\nGÓRA = wspina, skok odbija", width=100)
S(x0 + 19, x0 + 25, 8, 8)    # ledge for the vine
inst("R2Vine", vine, X(i, 22), 8 * T + 6)
sign("R2VineSign", X(i, 22), 5 * T, "PNĄCZE\nwisi z półki", width=90)
S(x0 + 33, x0 + 38, 11, 11)  # ledge for the ladder
inst("R2Ladder", ladder, X(i, 32) + 8, 11 * T, height_tiles=6)
sign("R2LadderSign", X(i, 35), 8 * T, "DRABINA", width=70)
S(x0 + 42, x0 + 47, 11, 11)
inst("R2Chain", chain, X(i, 41) + 8, 11 * T, height_tiles=6)
sign("R2ChainSign", X(i, 44), 8 * T, "ŁAŃCUCH", width=70)
S(x0 + 51, x0 + 55, 11, 11)
inst("R2Pole", pole, X(i, 50) + 8, 11 * T, height_tiles=6)
sign("R2PoleSign", X(i, 53), 8 * T, "SŁUP", width=60)
inst("R2Pillar", pillar, X(i, 59), 9 * T, texture=f"ExtResource(\"{BRICK}\")", height_tiles=8, width_tiles=2.0, cap=f"ExtResource(\"{CAP}\")")
sign("R2PillarSign", X(i, 59), 6 * T, "FILAR\nwall-jump po bokach", width=90)

# ======================================================== 3. PLATFORMY
i = 2
x0 = room_x0(i)
crumble = res("crumble", "res://scenes/objects/crumble.tscn")
mover = res("mover", "res://scenes/objects/lvl4/mover.tscn")
floatp = res("float", "res://scenes/objects/lvl4/float_platform.tscn")
wheel = res("wheel", "res://scenes/objects/lvl3/wheel.tscn")
sign("R3A", X(i, 11), (FLOOR - 3) * T, "KRUSZĄCE\nspadają po ~0,5 s i wracają", width=110)
C(x0 + 12, x0 + 22, FLOOR, BOTTOM)
for k, c in enumerate([12, 15, 18, 21]):
    inst(f"R3Crumble{k + 1}", crumble, X(i, c), FLOOR * T, width_tiles=2.0)
inst("R3Check2", CHECK, X(i, 24), FLOOR * T)
sign("R3B", X(i, 26), (FLOOR - 3) * T, "RUCHOMA POZIOMA", width=100)
C(x0 + 27, x0 + 36, FLOOR, BOTTOM)
inst("R3Mover1", mover, X(i, 27) + 8, FLOOR * T - 2, texture=f"ExtResource(\"{LEDGE}\")", distance=96.0)
inst("R3Check3", CHECK, X(i, 38), FLOOR * T)
sign("R3C", X(i, 40), (FLOOR - 3) * T, "RUCHOMA PIONOWA", width=100)
C(x0 + 41, x0 + 44, FLOOR, BOTTOM)
S(x0 + 45, x0 + 49, 10, FLOOR - 1)
inst("R3Mover2", mover, X(i, 42) + 16, FLOOR * T - 2, texture=f"ExtResource(\"{LEDGE}\")", direction="Vector2(0, -1)", distance=112.0)
sign("R3D", X(i, 53), (FLOOR - 3) * T, "KOŁO WODNE", width=100)
C(x0 + 50, x0 + 60, FLOOR, BOTTOM)
inst("R3Wheel", wheel, X(i, 55), 13 * T, radius=64.0)
inst("R3Check4", CHECK, X(i, 61), FLOOR * T)
inst("R3Float", floatp, X(i, 61), 12 * T, texture=f"ExtResource(\"{FLOATA}\")", body_depth=0.0)
sign("R3FloatSign", X(i, 61), 9 * T, "JEDNOSTRONNA\nwskocz od dołu", width=90)

# ======================================================== 4. PRZESZKODY
i = 3
x0 = room_x0(i)
spikes = res("spikes", "res://scenes/hazards/spikes.tscn")
crusher = res("crusher", "res://scenes/hazards/crusher.tscn")
cannon = res("cannon", "res://scenes/hazards/cannon.tscn")
fpipe = res("fpipe", "res://scenes/hazards/fire_pipe.tscn")
coco = res("coconut", "res://scenes/hazards/coconut.tscn")
sign("R4A", X(i, 9), (FLOOR - 3) * T, "KOLCE\nprzeskocz", width=90)
inst("R4Spikes", spikes, X(i, 12), FLOOR * T, width_tiles=3)
sign("R4B", X(i, 18), (FLOOR - 7) * T, "ZGNIATACZ\nprzebiegnij, gdy podniesiony", width=110)
inst("R4Crusher", crusher, X(i, 22), FLOOR * T)
sign("R4C", X(i, 30), (FLOOR - 4) * T, "RURA OGNISTA", width=100)
inst("R4Fire", fpipe, X(i, 33), FLOOR * T - 32)
sign("R4D", X(i, 40), (FLOOR - 5) * T, "KOKOS\nspada, gdy ktoś pod nim", width=110)
inst("R4Coco", coco, X(i, 43), 9 * T)
sign("R4E", X(i, 51), (FLOOR - 3) * T, "ARMATA\nstrzela po łuku", width=100)
inst("R4Cannon", cannon, X(i, 61), FLOOR * T, facing=-1)
inst("R4CrateA", CRATE, X(i, 55), FLOOR * T)
inst("R4CoinCrate", CRATE, X(i, 56), FLOOR * T, contents=1)   # a coin crate: the name decides the level count, here an extra
inst("R4DiaCrate", CRATE, X(i, 57), FLOOR * T, contents=2, gem=1)

# ======================================================== 5. WODA I SURFING
i = 4
x0 = room_x0(i)
water = res("water", "res://scenes/objects/water.tscn")
surf = res("surf", "res://scenes/objects/surf_zone.tscn")
fish = res("fish", "res://scenes/hazards/fish.tscn")
shark = res("shark", "res://scenes/hazards/shark.tscn")
sign("R5A", X(i, 6), (FLOOR - 3) * T, "PŁYWANIE\nGÓRA/DÓŁ w wodzie, skok = wyjście", width=110)
C(x0 + 12, x0 + 28, FLOOR, FLOOR + 3)
inst("R5Pool", water, X(i, 12), FLOOR * T, width_tiles=17, depth_tiles=4)
inst("R5Fish", fish, X(i, 20), FLOOR * T + 8)
sign("R5B", X(i, 31), (FLOOR - 3) * T, "MAŹ TOKSYCZNA\nzabiera HP", width=100)
C(x0 + 34, x0 + 38, FLOOR, FLOOR + 3)
inst("R5Sludge", water, X(i, 34), FLOOR * T, width_tiles=5, depth_tiles=4, damage=1)
sign("R5C", X(i, 42), (FLOOR - 4) * T, "SURFING\nwejdź w morze; skacz nad rekinem", width=120)
C(x0 + 44, x0 + 60, FLOOR, FLOOR + 3)
inst("R5Sea", water, X(i, 44), FLOOR * T, width_tiles=17, depth_tiles=4, swimmable=False, top_texture=f"ExtResource(\"{SEA_TOP}\")", body_texture=f"ExtResource(\"{SEA}\")")
inst("R5Surf", surf, X(i, 44), FLOOR * T, width_tiles=17)
inst("R5Shark", shark, X(i, 52), FLOOR * T)

# ======================================================== 6. WROGOWIE I BROŃ
i = 5
x0 = room_x0(i)
enemies = [("Dog", "dog/dog", "PIES", 0), ("Rat", "rat/rat", "SZCZUR", 0), ("Crow", "crow/crow", "WRONA", -64), ("Pigeon", "pigeon/pigeon", "GOŁĄB", 0),
           ("Boar", "boar/boar", "DZIK", 0), ("Frog", "frog/frog", "ŻABA", 0), ("Wasp", "wasp/wasp", "OSA", -64), ("Crab", "crab/crab", "KRAB", 0),
           ("Spider", "spider/spider", "PAJĄK", -96), ("Bat", "bat/bat", "NIETOPERZ", -64)]
for k, (nm, path, label, dy) in enumerate(enemies):
    c = 8 + k * 4
    key = res("e" + nm, f"res://scenes/enemies/{path}.tscn")
    inst(f"R6{nm}", key, X(i, c) + 32, FLOOR * T + dy)
    sign(f"R6{nm}Sign", X(i, c) + 32, (FLOOR - 3) * T, label, width=52)
    S(x0 + c + 3, x0 + c + 3, FLOOR - 2, FLOOR - 1)   # low walls between the pens
bikes = [res("bikeC", "res://scenes/hazards/bike_city.tscn"), res("bikeM", "res://scenes/hazards/bike_mtb.tscn"), res("bikeR", "res://scenes/hazards/bike_road.tscn")]
sign("R6Bike", X(i, 53), (FLOOR - 4) * T, "ROWERY: miejski, MTB, szosowy\nnie do zabicia", width=130)
sign("R6Weapons", X(i, 61), (FLOOR - 3) * T, "MANEKINY\ndrap (J/X), pierd (K/C), włóczka (L/V)", width=120)
for k in range(3):
    inst(f"R6Dummy{k + 1}", CRATE, X(i, 60 + k), FLOOR * T)

# ======================================================== 7. SEKRETY
i = 6
x0 = room_x0(i)
chest = res("chest", "res://scenes/objects/chest.tscn")
key = res("key", "res://scenes/objects/key.tscn")
bush = res("bush", "res://scenes/objects/secret/berry_bush.tscn")
sign("R7A", X(i, 14), (FLOOR - 3) * T, "SKRZYNIA NA KLUCZ\nbez klucza podpowiada", width=110)
inst("R7Chest", chest, X(i, 14), FLOOR * T, key_name="KeyTest", reward_name="LifeChestTest")
S(x0 + 24, x0 + 25, 15, FLOOR - 1)     # steps up to the key ledge (32 px each)
S(x0 + 26, x0 + 27, 13, FLOOR - 1)
S(x0 + 28, x0 + 32, 12, 12)
inst("R7Key", key, X(i, 30), 12 * T, color="gold", message="Klucz! Pasuje do skrzyni w tym pokoju.")
sign("R7B", X(i, 30), 9 * T, "KLUCZ\nschowany na półce", width=90)
sign("R7C", X(i, 44), (FLOOR - 4) * T, "KRZAK Z JAGODAMI\ndrap 7 razy = życie", width=120)
inst("R7Bush", bush, X(i, 44), FLOOR * T)

# the three cyclists share one lane (they pass each other), laps offset by phase
for k, (bk, ph) in enumerate(zip(bikes, [0.0, 0.35, 0.7])):
    inst(f"R6Bike{k + 1}", bk, X(5, 49), FLOOR * T, lane=144.0, phase=ph)

# ======================================================== write
solid_cells = set()
for c0, c1, r0, r1 in solid:
    for c in range(c0, c1 + 1):
        for r in range(r0, r1 + 1):
            solid_cells.add((c, r))
for c0, c1, r0, r1 in cut:
    for c in range(c0, c1 + 1):
        for r in range(r0, r1 + 1):
            solid_cells.discard((c, r))
cells_path = Path("/private/tmp/test_level_cells.json")


def build():
    ids = list(ext.items())
    head = ["[gd_scene format=3]", ""]
    head.append('[ext_resource type="Script" path="res://scenes/level/level.gd" id="level_script"]')
    head.append('[ext_resource type="TileSet" path="res://scenes/level/tileset.tres" id="tileset"]')
    for k, (typ, p) in ids:
        head.append(f'[ext_resource type="{typ}" path="{p}" id="{k}"]')
    body = ['', '[node name="LevelTest" type="Node2D"]', 'script = ExtResource("level_script")', 'title = "POLIGON"', 'music = "forest"', '',
            '[node name="Background" type="CanvasLayer" parent="."]', 'layer = -1', '',
            '[node name="Grey" type="ColorRect" parent="Background"]', 'anchors_preset = 15', 'anchor_right = 1.0', 'anchor_bottom = 1.0', 'grow_horizontal = 2', 'grow_vertical = 2', 'color = Color(0.17, 0.19, 0.24, 1)', '',
            '[node name="Ground" type="TileMapLayer" parent="."]', 'scale = Vector2(0.333333, 0.333333)', 'tile_map_data = PackedByteArray("")',
            'tile_set = ExtResource("tileset")', '']
    # Cat and HUD last so they draw over the rest
    cat = '[node name="Cat" parent="." instance=ExtResource("cat_scene")]\n'
    hud = '[node name="HUD" parent="." instance=ExtResource("hud_scene")]\n'
    ext["cat_scene"] = ("PackedScene", "res://scenes/player/cat.tscn")
    ext["hud_scene"] = ("PackedScene", "res://scenes/ui/hud.tscn")
    ids = list(ext.items())
    head = head[:4] + [f'[ext_resource type="{typ}" path="{p}" id="{k}"]' for k, (typ, p) in ids]
    text = "\n".join(head) + "\n" + "\n".join(body) + "\n" + "\n".join(nodes) + "\n" + cat + "\n" + hud
    return text


if __name__ == "__main__":
    if OUT.exists() and "--force" not in sys.argv:
        sys.exit(f"{OUT} exists and is edited by hand in Godot now; run with --force to regenerate (this overwrites it).")
    cells_path.write_text(json.dumps(sorted(solid_cells)))
    OUT.write_text(build())
    r = subprocess.run(["godot", "--headless", "--script", "tools/paint_test_level.gd", "--", str(cells_path), "/private/tmp/test_level_b64.txt"], capture_output=True, text=True)
    b64 = Path("/private/tmp/test_level_b64.txt").read_text()
    OUT.write_text(OUT.read_text().replace('tile_map_data = PackedByteArray("")', f'tile_map_data = PackedByteArray("{b64}")'))
    print("written", OUT, len(solid_cells), "cells,", len(nodes), "nodes")
