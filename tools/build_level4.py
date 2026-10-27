# Run from the project root: python3 tools/build_level4.py --force && godot --headless --script tools/paint_level4.gd && mv scenes/level/_tmp.tscn scenes/level/level_04.tscn
# NOTE: level_04.tscn is now the source of truth (edited by hand in Godot); this generator needs --force and would overwrite it.
import sys
if "--force" not in sys.argv:   # from here on the level is edited by hand in Godot: rebuilding would throw those edits away
    sys.exit("level_04.tscn is edited by hand in Godot now. This generator rebuilds it from scratch and would overwrite those "
             "edits. Add --force only if you really want that (and then run paint_level4.gd and move _tmp.tscn over it).")

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

KLJ = __import__("json").load(open("assets/game/lvl4/kladka_sizes.json"))
KL = KLJ["sizes"]
KL_BG_SCALE = 0.4712   # bg_new 2173 px wide -> 64 tiles, the same scale as the mockup grid
KL_PAD = 220           # px of sky added on top of bg_new
def ldeco(img, x, row, h_tiles=0, parent="DecorBack", scale=0.333333):  # footbridge sprite, bottom-centre; h_tiles>0 scales it to that height
    w, h = KL[img]
    if h_tiles: scale = round(h_tiles * T / h, 4)
    node(uid(img + "_"), parent, "Sprite2D", props=[pos(round(x * T + T / 2), ty(row) + 2), f'texture = ExtResource("{R(f"res://assets/game/lvl4/kladka/{img}.png", "Texture2D")}")',
        "centered = false", f"offset = Vector2({-(w // 2)}, {-h})", f"scale = Vector2({scale}, {scale})"])
def lplat(name, img, x, row, n=1):
    surf = KLJ["surface"].get(img) if not img.startswith("bridge") else 9.0   # the deck lies under the railing
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round(x * T + T / 2), ty(row), [f'texture = ExtResource("{R(f"res://assets/game/lvl4/kladka/{img}.png", "Texture2D")}")',
        f"surface = {surf}", f"count = {n}"])
def pillar(name, x, top, h):
    inst(name, "res://scenes/objects/lvl4/pillar.tscn", round(x * T + T / 2), ty(top), [f'texture = ExtResource("{R("res://assets/game/lvl4/kladka/pillar_s2.png", "Texture2D")}")', f"height_tiles = {h}"])
def pole(x, top, h):
    inst(uid("Pole"), "res://scenes/objects/lvl4/pole.tscn", round(x * T + T / 2), ty(top), [f"height_tiles = {h}"])

FJ = __import__("json").load(open("assets/game/lvl4/fort_sizes.json"))
def fdeco(img, x, row, parent="DecorBack"):
    w, h = FJ["sizes"][img]
    node(uid(img + "_"), parent, "Sprite2D", props=[pos(round(x * T + T / 2), ty(row) + 2), f'texture = ExtResource("{R(f"res://assets/game/lvl4/fort/{img}.png", "Texture2D")}")',
        "centered = false", f"offset = Vector2({-(w // 2)}, {-h})", "scale = Vector2(0.333333, 0.333333)"])
def fplat(name, img, x, row, n=1):
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round(x * T + T / 2), round(ty(row)), [f'texture = ExtResource("{R(f"res://assets/game/lvl4/fort/{img}.png", "Texture2D")}")',
        f"surface = {FJ['surface'][img]}", f"count = {n}"])
def fwall(x0, x1, top, bot):  # solid brick block from column x0 to x1, rows top..bot
    inst(uid("FortWall"), "res://scenes/objects/lvl4/pillar.tscn", round((x0 + x1) / 2 * T), ty(top), [
        f'texture = ExtResource("{R("res://assets/game/lvl4/fort/brick_fill.png", "Texture2D")}")', f"height_tiles = {bot - top}",
        f"width_tiles = {x1 - x0}", f'cap = ExtResource("{R("res://assets/game/lvl4/fort/ledge_grass.png", "Texture2D")}")'])

SJ = __import__("json").load(open("assets/game/lvl4/stadion_sizes.json"))
def sdeco(img, x, row, h_tiles=0, scale=0.333333, parent="DecorBack"):
    w, h = SJ["sizes"][img]
    if h_tiles: scale = round(h_tiles * T / h, 4)
    node(uid(img + "_"), parent, "Sprite2D", props=[pos(round(x * T + T / 2), ty(row) + 2), f'texture = ExtResource("{R(f"res://assets/game/lvl4/stadion/{img}.png", "Texture2D")}")',
        "centered = false", f"offset = Vector2({-(w // 2)}, {-h})", f"scale = Vector2({scale}, {scale})"])

PJ = __import__("json").load(open("assets/game/lvl4/park_sizes.json"))
def pdeco(img, x, row, h_tiles=0, scale=0.333333, parent="DecorBack"):
    w, h = PJ["sizes"][img]
    if h_tiles: scale = round(h_tiles * T / h, 4)
    node(uid(img + "_"), parent, "Sprite2D", props=[pos(round(x * T + T / 2), round(ty(row)) + 2), f'texture = ExtResource("{R(f"res://assets/game/lvl4/park/{img}.png", "Texture2D")}")',
        "centered = false", f"offset = Vector2({-(w // 2)}, {-h})", f"scale = Vector2({scale}, {scale})"])
def pplat(name, img, x, row):
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round(x * T + T / 2), round(ty(row)), [f'texture = ExtResource("{R(f"res://assets/game/lvl4/park/{img}.png", "Texture2D")}")',
        f"surface = {PJ['surface'][img]}"])

# ---------------- background: sunset sky over Kraków, behind the whole level ----------------
node("Background", typ="CanvasLayer", props=["layer = -1"])
node("Sky", "Background", "Sprite2D", props=["texture_repeat = 2", f'texture = ExtResource("{R("res://assets/game/lvl4/sky_city.png", "Texture2D")}")',
     "centered = false", "scale = Vector2(0.53, 0.53)", "region_enabled = true", "region_rect = Rect2(0, 0, 1400, 340)", "metadata/scroll = 0.1", "metadata/vscroll = 0.0"])   # sunset over the Old Town, from the Kopiec backdrop

# ---------------- 1. Kopiec Krakusa (layout from assets/lvl4/kopiec/platforms.png, 64 tiles) ----------------
# the backdrop is locked to the world here (as in the mockup): its mound sits under the summit deck
node("WorldBack", typ="Node2D")   # world-locked backdrops of the later parts
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
node("DecorFront", typ="Node2D")   # drawn over the tiles (asphalt on the road)
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

# ---------------- 2. footbridge over al. Powstańców Śląskich (layout from assets/lvl4/kladkaParkowa/platforms.png) ----------------
# local column c of the mockup is global column B + c; its backdrop (bg_new) is locked to the world like the Kopiec one
B = 64
node("KladkaBg", "WorldBack", "Sprite2D", props=[f'texture = ExtResource("{R("res://assets/game/lvl4/kladka/bg.png", "Texture2D")}")',
     "centered = false", pos(B * T, round(-KL_PAD * KL_BG_SCALE)), f"scale = Vector2({KL_BG_SCALE}, {KL_BG_SCALE})"])
for img, x, row, h in [("mural", 8, 16, 0), ("tree_a", 1, 16, 0), ("bush_a", 3.5, 16, 0), ("tuft_a", 7, 17, 0), ("lamp_a", 5, 16, 12),
                       ("lamp_b", 14, 8, 6), ("bush_b", 16, 16, 0), ("tree_c", 18, 16, 0), ("gantry", 27, 20, 0), ("lamp_b", 39, 20, 12),
                       ("mast_b", 45, 18, 12), ("mast_a", 50.5, 16, 6), ("mast_b", 55, 17, 14), ("mast_d", 61, 17, 14), ("cabinet_a", 48, 17, 0),
                       ("bush_c", 52, 16, 0), ("tree_b", 57, 17, 0), ("grass_tall", 59.5, 17, 0), ("signal", 62.5, 13, 0)]:
    ldeco(img, B + x, row, h, scale=0.6667 if img == "mural" else 0.333333)
for i, (x0, x1) in enumerate([(9, 13), (22, 46)]):   # asphalt only where the road shows between the verges
    node(f"Road{i + 1}", "DecorFront", "Sprite2D", props=["texture_repeat = 2", f'texture = ExtResource("{R("res://assets/game/lvl4/kladka/road.png", "Texture2D")}")',
         "centered = false", pos((B + x0) * T, ty(20) - 1), "scale = Vector2(0.333333, 0.333333)", "region_enabled = true", f"region_rect = Rect2(0, 0, {(x1 - x0) * T * 3}, {KL['road'][1]})"])
pillar("PillarK2", B + 20, 7, 10); pillar("PillarK3", B + 31.5, 12, 3)
for name, img, x, row, n in [("W1a", "bridge_short", 13.6, 8, 1), ("W1b", "bridge_short", 17.4, 8, 1), ("W2", "bridge_short", 31.5, 8, 4),
                             ("K1", "grass_c", 6.5, 12, 2), ("K3", "grass_c", 15.5, 11, 2), ("K4", "grass_c", 11.5, 13, 2),
                             ("K6", "grass_c", 27, 7, 2), ("K7", "grass_c", 31.5, 11, 2), ("K8", "grass_a", 31.5, 15, 2),
                             ("K9", "grass_c", 24.5, 15, 2), ("K10", "grass_c", 38.5, 15, 2), ("K11", "grass_d", 44.5, 13, 3), ("K12", "grass_d", 47.5, 6, 3),
                             ("K13", "grass_b", 49.5, 11, 1)]:
    lplat(name, img, B + x, row, n)
pole(B + 5, 5, 11); pole(B + 39, 9, 11); pole(B + 45, 7, 11)   # lamps and catenary masts to climb
traffic("Car1", B + 22, B + 46, 20, 110, (28, 10), (0.75, 0.2, 0.2))
traffic("Car2", B + 22, B + 46, 20, -150, (26, 10), (0.2, 0.35, 0.8), 1.0, 0.5)
inst("Crow5", "res://scenes/enemies/crow/crow.tscn", tx(B + 18), ty(5))
inst("Crow6", "res://scenes/enemies/crow/crow.tscn", tx(B + 48), ty(3))
inst("DogK3", "res://scenes/enemies/dog/dog.tscn", tx(B + 52), ty(16), ["patrol_radius = 32.0"])
inst("CheckpointK", "res://scenes/objects/checkpoint.tscn", tx(B + 57), ty(17))

# ---------------- 3. Fort 31 "Benedykt" (layout from assets/lvl4/fort31/platforms.png) ----------------
# local column c of the mockup is global column F + c; ground at row 17, walls are solid brick blocks with a grass-ledge cap
F = 128
node("FortBg", "WorldBack", "Sprite2D", props=[f'texture = ExtResource("{R("res://assets/game/lvl4/fort/bg.png", "Texture2D")}")',
     "centered = false", pos(F * T, round(-KL_PAD * KL_BG_SCALE)), f"scale = Vector2({KL_BG_SCALE}, {KL_BG_SCALE})"])
for img, x, row in [("tree_big", 0.5, 15), ("bush", 11, 17), ("tree_s1", 22, 17), ("bush_s", 31, 13), ("tree_s2", 41, 17),
                    ("ruin_c", 47, 17), ("bush", 53, 17), ("tree_s1", 57.5, 17), ("tree_big", 63.5, 17), ("crate", 4.5, 9)]:
    fdeco(img, F + x, row)
for x0, x1, top, bot in [(1, 7, 15, 17), (3.5, 5.5, 9, 12), (7, 8.5, 9, 11), (10.5, 12, 11, 17), (12, 14, 12, 17), (14, 16, 13, 15),
                         (18, 20, 13, 17), (20, 22, 15, 17),
                         (23, 28.5, 12, 14), (26.5, 28, 11, 12), (23, 24, 14, 17), (27.5, 28.5, 14, 17), (28.5, 30.5, 12, 14), (29.5, 30.5, 14, 17),
                         (29, 30.5, 8, 9),
                         (33.5, 36, 11, 13), (42.5, 46.5, 11, 13), (43.5, 46, 7, 9),
                         (50, 51.5, 5, 8), (49.5, 53, 8, 9), (48.5, 50.5, 10, 12), (56.5, 58.5, 8, 9), (57.5, 58.5, 9, 11), (58.5, 61, 11, 12),
                         (54, 56.8, 14, 17), (59, 62.5, 14, 17)]:
    fwall(F + x0, F + x1, top, bot)
for name, img, x, row, n in [("FB1", "grass_s", 7.75, 11, 1), ("FB2", "rail_wood", 9.6, 12, 1), ("FB3", "rail_wood", 17, 13.6, 1),
                             ("FB4", "grass_block", 16.5, 10.6, 1), ("FB5", "grass_s", 18.2, 9.7, 1), ("FB6", "grass_s", 20.3, 9.7, 1),
                             ("FB7", "grass_s", 23.5, 7.8, 2), ("FB8", "grass_block", 27, 6.9, 2), ("FB9", "rail_wood", 29.3, 7, 1),
                             ("FB10", "ledge_stone", 33.5, 13, 1), ("FB11", "crate", 32.3, 12, 1), ("FB12", "crate", 33.2, 12, 1),
                             ("FB13", "grass_s", 34, 7.7, 1), ("FB14", "grass_s", 37.2, 8, 1), ("FB15", "crate", 36.5, 12, 1),
                             ("FB16", "ledge_grass", 39.5, 12.5, 1), ("FB17", "rail_wood", 48, 12, 1), ("FB18", "rail_wood", 48.4, 7.2, 2),
                             ("FB19", "ledge_stone", 52.5, 11, 1), ("FB20", "rail_wood", 55, 9, 2), ("FB21", "crate", 55.5, 8.1, 1)]:
    fplat(name, img, F + x, row, n)
ladder(F + 3, 9, 6); ladder(F + 52.5, 8, 3); ladder(F + 54.5, 11, 3)
for x0, w, row in [(14.2, 1, 13), (25, 1, 12), (20.2, 1, 15), (59.2, 1, 11)]:
    inst(uid("Spikes"), "res://scenes/hazards/spikes.tscn", round((F + x0) * T), ty(row), [f"width_tiles = {w}"])
inst("DogF1", "res://scenes/enemies/dog/dog.tscn", tx(F + 39), ty(17), ["patrol_radius = 40.0"])
inst("Crow7", "res://scenes/enemies/crow/crow.tscn", tx(F + 22), ty(5))
inst("Bat2", "res://scenes/enemies/bat/bat.tscn", tx(F + 47), ty(4), ["zone = Vector2(160, 112)"])
inst("CheckpointF", "res://scenes/objects/checkpoint.tscn", tx(F + 2), ty(15))
hint(F + 4, 15, "Fort 31! Wespnij się po drabinie i przejdź górą po murach.")

# ---------------- 4. old Olympic stadium on Krzemionki (layout from assets/lvl4/krzemionki/platforms.png) ----------------
# local column c of the mockup is global column C + c; some ledges and both yellow bridges crumble (design.md)
C = 192
node("StadionBg", "WorldBack", "Sprite2D", props=[f'texture = ExtResource("{R("res://assets/game/lvl4/stadion/bg.png", "Texture2D")}")',
     "centered = false", pos(C * T, round(-KL_PAD * KL_BG_SCALE)), f"scale = Vector2({KL_BG_SCALE}, {KL_BG_SCALE})"])
for img, x, row, sc in [("kiosk", 17, 12, 0.143), ("umbrella", 10.6, 10, 0.15), ("umbrella", 22.4, 11, 0.15), ("table_set", 25.5, 11, 0.15),
                        ("menu", 14, 12, 0.11), ("welcome", 20, 12, 0.11), ("crates", 11.8, 10, 0.12), ("flowers_red", 7, 11, 0.12),
                        ("bench", 31, 17, 0.333333), ("bench", 36.5, 15, 0.333333), ("goal", 41, 18, 0.25), ("flag", 51, 11, 0.333333),
                        ("flag", 59.5, 15, 0.333333), ("fence_mesh", 3.5, 15, 0.25), ("fence_mesh", 11, 18, 0.25), ("fence_mesh", 46.5, 18, 0.25),
                        ("fence_rail", 1, 9, 0.25), ("bins", 25, 17, 0.333333), ("dugout", 37.5, 18, 0.25), ("hedge", 16, 17, 0.333333),
                        ("bush_round", 43.5, 18, 0.333333), ("bush_c", 60.5, 15, 0.333333), ("stairs_rail_a", 6.7, 11, 0.333333),
                        ("stairs_rail_b", 29.4, 12, 0.333333), ("stairs_rail_a", 33.7, 15, 0.333333), ("stairs_rail_b", 22.6, 18, 0.333333),
                        ("stairs_rail_a", 48.8, 17, 0.333333)]:
    sdeco(img, C + x, row, scale=sc)
for x, row, img in [(10.5, 14.5, "grass_stone"), (43, 13, "grass_stone"), (54.2, 12.6, "grass_stone"), (55.2, 16, "grass_stone_s"),
                    (29.6, 17, "panel_yellow"), (31.2, 17, "panel_yellow"), (53.6, 17, "panel_yellow"), (55.2, 17, "panel_yellow")]:
    inst(uid("CrumbleS"), "res://scenes/objects/crumble.tscn", round(C * T + x * T), round(ty(row)), [
        f'texture = ExtResource("{R(f"res://assets/game/lvl4/stadion/{img}.png", "Texture2D")}")', f"surface = {SJ['surface'][img]}", "delay = 0.6"])
for i, x0 in enumerate([30, 54]):   # flooded pits under the bridges, with a ladder out
    inst(f"PitWater{i + 1}", "res://scenes/objects/water.tscn", (C + x0) * T, ty(19), ["width_tiles = 3", "depth_tiles = 2"])
    ladder(C + x0 + 2.5, 17, 4)
for x, row in [(2, 9), (9.2, 10), (32, 12)]:
    inst(uid("SnackS"), "res://scenes/objects/snack.tscn", tx(C + x), ty(row))
inst("CatnipS", "res://scenes/objects/catnip.tscn", tx(C + 55.6), ty(16) - 2)
inst("DogS1", "res://scenes/enemies/dog/dog.tscn", tx(C + 36), ty(18), ["patrol_radius = 40.0"])
inst("DogS2", "res://scenes/enemies/dog/dog.tscn", tx(C + 46), ty(15), ["patrol_radius = 24.0"])
inst("Crow4", "res://scenes/enemies/crow/crow.tscn", tx(C + 20), ty(5))
inst("Crow8", "res://scenes/enemies/crow/crow.tscn", tx(C + 48), ty(6))
inst("CheckpointS1", "res://scenes/objects/checkpoint.tscn", tx(C + 1), ty(14))
inst("CheckpointS2", "res://scenes/objects/checkpoint.tscn", tx(C + 34), ty(18))
hint(C + 2, 14, "Stary stadion! Uważaj, niektóre platformy i kładki się kruszą.")

# everything after the stadium (old greybox columns), shifted right by S tiles
S = 75   # the park starts right where the stadium ends (column 256), now that Plac Lasoty is gone

# ---------------- 6. Park Bednarskiego (layout from assets/lvl4/parkBednarskiego/platforms.png) ----------------
# floating stone islands over the bushes: falling between them loses a life. Local column c is global P + c.
# The mockup's gaps are taller than the cat's jump, so its lamp posts are climbable and reach up past the next island.
P = 181 + S
node("ParkBg", "WorldBack", "Sprite2D", props=[f'texture = ExtResource("{R("res://assets/game/lvl4/park/bg.png", "Texture2D")}")',
     "centered = false", pos(P * T, round(-KL_PAD * KL_BG_SCALE)), f"scale = Vector2({KL_BG_SCALE}, {KL_BG_SCALE})"])
for img, x, row in [("tree_a", 0.5, 11), ("fence_iron", 2, 11), ("bench_b", 4.5, 17), ("bush_flower", 7, 18), ("bin", 15.5, 18),
                    ("rocker", 13.5, 18), ("gate_iron", 65, 13), ("bush_f", 70.5, 13), ("tree_b", 71.5, 13)]:
    pdeco(img, P + x, row)
for i, img in enumerate(["bush_b", "tree_pink", "bush_c", "bush_flower", "bush_a", "bush_yellow", "bush_d", "bush_e", "bush_flower", "bush_b",
                         "tree_pink", "bush_c", "bush_a", "bush_e", "bush_d", "bush_yellow"]):   # hedge over the drop, in front of the dirt
    pdeco(img, P + 18 + i * 2.9, 22.5, parent="DecorFront")
for name, img, x, row in [("PA", "float_a", 7.5, 8.6), ("PB", "float_b", 13.1, 15.3), ("PC", "float_c", 16.2, 10.8), ("PBridge", "wood_bridge_b", 23.2, 12.8),
                          ("PF", "float_c", 30.8, 8.3), ("PG", "float_b", 31.5, 16.2), ("PG2", "tiny_e", 33, 14.3), ("PH", "float_c", 35.4, 12.4),
                          ("PI", "long_b", 40.4, 10.2), ("PI2", "block_s", 37.9, 9.2), ("PJ", "bench_block", 40.8, 15.4), ("PArch", "arch_bridge", 49.3, 13.3),
                          ("PK", "block_a", 44.8, 7.4), ("PL", "bench_block", 52.4, 7.1), ("PM", "ledge_a", 56.6, 14.5), ("PN", "float_c", 61.8, 12.5),
                          ("PO", "float_b", 61.7, 16.8)]:
    pplat(name, img, P + x, row)
for x, top, bottom in [(3.3, 7, 11), (16.4, 10, 18), (27.9, 7.5, 12.8), (38, 4.5, 10.2), (55.4, 6.5, 14.5), (49.2, 4.5, 7.1)]:
    pdeco("lamp_a", P + x, bottom, h_tiles=bottom - top)
    pole(P + x, top, round(bottom - top))
inst("DogP1", "res://scenes/enemies/dog/dog.tscn", tx(P + 15), ty(18), ["patrol_radius = 24.0"])
inst("Bat1", "res://scenes/enemies/bat/bat.tscn", tx(P + 34), ty(5), ["zone = Vector2(160, 112)"])   # bat boxes in the park
inst("Crow9", "res://scenes/enemies/crow/crow.tscn", tx(P + 48), ty(5))
inst("Checkpoint3", "res://scenes/objects/checkpoint.tscn", tx(P + 13.5), ty(18))
inst("Checkpoint4", "res://scenes/objects/checkpoint.tscn", tx(P + 46), ty(13.3))
hint(P + 1, 11, "Park Bednarskiego! Między wysepkami jest przepaść - wspinaj się po latarniach.")

hint(3, 10, "Kopiec Krakusa! Wejdź na szczyt, a potem zejdź w stronę kładki.")
hint(20, 15, "Osuwająca się ziemia długo nie wytrzyma - nie stój na niej.")
hint(B + 2, 16, "Pod kładką jeżdżą auta. Idź górą albo wspinaj się po latarniach i słupach.")

# ---------------- coins, 1ups, diamonds: 10 coins and 4 diamonds per location ----------------
def pickups(tag, coins, gems):
    assert len(coins) == 10 and len(gems) == 4, tag
    for i, (x, y) in enumerate(coins):
        inst(f"Coin{tag}{i + 1}", "res://scenes/objects/coin.tscn", round(x), round(y))
    for i, (x, y) in enumerate(gems):
        inst(f"Diamond{tag}{i + 1}", "res://scenes/objects/diamond.tscn", round(x), round(y), [f"gem = {i}"])
def above(x, row, up=14): return (x * T + T / 2, ty(row) - up)   # over a platform top at tile column x
pickups("K",   # Kopiec
        [(tx(9), ty(16) - 8), above(14.5, 8), (17 * T, ty(11) - 14), (tx(30.5), ty(17) - 8), above(34.9, 12), above(36, 8),
         (43.25 * T + 8, ty(9) - 14), above(48.25, 11), above(52.4, 13), above(60, 10, 40)],
        [(tx(6), ty(16) - 8), above(36.5, 8, 56), above(21.5, 15, 8), above(39, 10)])
pickups("B",   # footbridge over al. Powstańców Śląskich
        [above(B + 6.5, 12), above(B + 11.5, 13), above(B + 15.5, 11), above(B + 20, 8, 20), above(B + 27, 7), above(B + 24.5, 15),
         above(B + 38.5, 15), above(B + 44.5, 13), above(B + 49.5, 11), above(B + 56, 17)],
        [(tx(B + 30), ty(20) - 8), above(B + 31.5, 15), above(B + 47.5, 6), above(B + 61, 17)])
pickups("F",   # Fort 31
        [above(F + 16.5, 10.6), above(F + 23.5, 7.8), above(F + 27, 6.9), above(F + 27.2, 11, 10), above(F + 34, 7.7), above(F + 39.5, 12.5),
         above(F + 44.7, 7, 10), above(F + 48.4, 7.2), above(F + 50.7, 5, 10), above(F + 55.4, 14, 10)],
        [above(F + 4.5, 9, 30), above(F + 37.2, 8), above(F + 55.5, 8.1, 28), above(F + 57.5, 8, 10)])
pickups("S",   # old stadium
        [above(C + 4.6, 10, 28), above(C + 4.4, 15), above(C + 27.3, 11), above(C + 28.3, 17, 22), above(C + 36, 15), above(C + 36.8, 15),
         above(C + 51.2, 17), above(C + 51.9, 17), above(C + 59, 10), above(C + 59.8, 10)],
        [above(C + 11.2, 14.5), above(C + 44, 13), above(C + 55, 12.6), above(C + 58.5, 15)])
pickups("P",   # Park Bednarskiego
        [above(P + 7.5, 8.6), above(P + 13.1, 15.3), above(P + 16.2, 10.8), above(P + 23.2, 12.8), above(P + 30.8, 8.3), above(P + 35.4, 12.4),
         above(P + 41, 10.2), above(P + 47, 13.3), above(P + 57, 14.5), above(P + 61.7, 16.8)],
        [above(P + 13.8, 12.9, 0), above(P + 44.8, 7.4, 26), above(P + 52, 7.1), above(P + 61, 12.5, 18)])
# the 1up of the old Plac Lasoty now waits on the park's highest island, with a diamond beside it
inst("Life1", "res://scenes/objects/life.tscn", round((P + 44.8) * T + T / 2), ty(7.4) - 22)   # over island PK
inst("DiamondL1", "res://scenes/objects/diamond.tscn", round((P + 52.4) * T + T / 2), ty(7.1) - 22, ["gem = 0"])   # over island PL
inst("Life2", "res://scenes/objects/life.tscn", tx(11), ty(16) - 18)    # hidden in the cave under the start, on the chest

# ======== Podgórze: Rynek Podgórski (L .. L+63) and the Vistula boulevards (L+64 .. L+135) ========
# Written with local columns (0 = the square's left edge): pos() is shifted by L tiles while this part is built.
L = 329
import json
_pos = pos
def pos(x, y): return _pos(x + L * T, y)
J = json.load(open("assets/game/lvl4/podgorze/sizes.json"))
def tex(img): return f'texture = ExtResource("{R(f"res://assets/game/lvl4/podgorze/{img}.png", "Texture2D")}")'
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
BG_SCALE = 0.4712   # the 2172 px backdrops -> 64 tiles
BG_PAD = 220        # px of sky added on top of them

node("RynekBg", "WorldBack", "Sprite2D", props=[tex("rynek_bg"), "centered = false", pos(0, round(-BG_PAD * BG_SCALE)), f"scale = Vector2({BG_SCALE}, {BG_SCALE})"])
W = 64
node("BulwaryBg", "WorldBack", "Sprite2D", props=[tex("bulwary_bg"), "centered = false", pos(W * T, round(-BG_PAD * BG_SCALE)), f"scale = Vector2({BG_SCALE}, {BG_SCALE})"])
# ---------------- 7. Rynek Podgórski ----------------
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
for i, x in enumerate([9, 25, 33, 49]):   # pigeons strut about the square
    inst(f"PigeonR{i + 1}", "res://scenes/enemies/pigeon/pigeon.tscn", tx(x), ty(G))
inst("BikeR1", "res://scenes/hazards/bike_city.tscn", 19 * T + 12, ty(G), ["lane = 480"])   # a cyclist crosses the square in front of the church
inst("PgDog1", "res://scenes/enemies/dog/dog.tscn", tx(23), ty(G), ["patrol_radius = 40.0"])
inst("PgCheckpoint1", "res://scenes/objects/checkpoint.tscn", tx(37.5), ty(G))
hint(3, G, "Rynek Podgórski! Na kościół wejdziesz po wieżyczkach w narożnikach.")

# ---- Rynek: floating stone blocks from the mockup assets/lvl4/rynekPodgorski/platforms.png (48 columns, own grid) ----
# The mockup's ground (cobbles) is at its row 15.4 = our row 17 (YO = 1.6); it is placed XO columns into the square.
# Blocks are the Bernatka stone ledges with grass (the mockup shows the same kind of block). The mockup's backdrop is a
# sunset with the church at the left, unlike bg.png (church in the middle): the layout is only approximate against it.
XO, YO = 8, 1.6
BJR = json.load(open("assets/game/lvl4/bernatka_sizes.json"))["surface"]
def rplat(name, img, col, mrow):   # block centred on mockup column col, walkable top on mockup row mrow
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round((XO + col) * T), round(ty(mrow + YO)), [
         f'texture = ExtResource("{R(f"res://assets/game/lvl4/bernatka/{img}.png", "Texture2D")}")', f"surface = {BJR[img]}"])
for name, img, col, mrow in [("RP1", "ledge_grass_m", 3.35, 6.8), ("RP2", "ledge_grass_m", 4.45, 12.7), ("RP3", "ledge_grass_m", 9.35, 10.3),
                             ("RP4", "ledge_grass_l", 15.15, 7.9), ("RP5", "ledge_grass_m", 17.7, 12.1), ("RP6", "ledge_grass_l", 23.2, 6.0),
                             ("RP7", "ledge_grass_m", 27.85, 8.7), ("RP8", "ledge_grass_l", 35.75, 8.0), ("RP9", "ledge_grass_s", 34.2, 11.1),
                             ("RP10", "ledge_grass_m", 45.85, 8.4), ("RP11", "ledge_grass_m", 41.9, 11.0)]:
    rplat(name, img, col, mrow)
def rdeco(fn, img, col, mrow, **kw): fn(img, XO + col, mrow + YO, **kw)   # decoration on a block, bottom-centre on its top
for img, col, mrow, how in [("chest", 3.4, 6.8, kdeco), ("pot_a", 1.9, 6.8, deco), ("pot_b", 5.0, 6.8, deco), ("crate", 3.8, 12.7, fdeco),
                            ("pot_a", 8.0, 10.3, deco), ("crate", 13.8, 7.9, fdeco), ("pot_b", 12.9, 7.9, deco), ("crate", 16.3, 12.1, fdeco),
                            ("pot_a", 15.6, 12.1, deco), ("hedge_b", 21.7, 6.0, deco), ("crate", 25.0, 6.0, fdeco), ("crate", 26.2, 8.7, fdeco),
                            ("iron_fence", 29.0, 8.7, deco), ("pot_a", 33.3, 8.0, deco), ("iron_fence", 34.3, 8.0, deco), ("crate", 45.2, 8.4, fdeco),
                            ("bench", 46.8, 8.4, deco), ("pot_b", 40.5, 11.0, deco)]:
    rdeco(how, img, col, mrow)
# the mockup's tall street lamp beside the first block: climbable, tall enough to reach it from the ground
deco("lamp", XO + 1.8, G, h_tiles=G - (6.8 + YO) + 0.4)
pole(XO + 1.8, 6.8 + YO - 0.4, round(G - (6.8 + YO) + 0.4))

# ---------------- 8. Bulwary wiślane ----------------
# promenade (foreground strip) with two breaks where the river shows: cross on the moored boats or swim
PROM = [(0, 17), (38, 50)]   # past the second break the Bernatka quay takes over   # promenade stretches, columns relative to W
for i, (a, b) in enumerate(PROM):
    node(f"Promenade{i + 1}", "DecorFront", "Sprite2D", props=["texture_repeat = 2", tex("promenade"), "centered = false",
         pos((W + a) * T, ty(G) - 260 + 2), f"scale = Vector2({BG_SCALE}, {BG_SCALE})", "region_enabled = true",
         f"region_rect = Rect2({round((a % 64) * T / BG_SCALE)}, 0, {round((b - a) * T / BG_SCALE)}, 724)"])
for i, (a, b) in enumerate([(17, 38), (50, 64)]):
    inst(f"River{i + 1}", "res://scenes/objects/water.tscn", (W + a) * T, ty(G + 1.5), [f"width_tiles = {b - a}", "depth_tiles = 6"])
    deco("quay_wall", W + a - 1.1, G + 1.5, parent="DecorFront"); deco("quay_wall", W + b + 1.1, G + 1.5, parent="DecorFront", flip=True)
plat("BoatSmall", "boat_small", W + 21.2, G + 0.6, 24); plat("Barge", "barge", W + 31.6, G + 0.4, 14)
plat("Houseboat", "houseboat", W + 57, G - 0.2, 19)
for img, x in [("lifebuoy", 1.5), ("bollard_rope", 15.7), ("bollard_rope", 39), ("crate_bush", 44), ("lifebuoy", 48.5)]:
    deco(img, W + x, G)

inst("Bike1", "res://scenes/hazards/bike_city.tscn", (W + 1) * T + 12, ty(G), ["lane = 232"])   # the promenade: a city bike, a road bike, an MTB
inst("Bike2", "res://scenes/hazards/bike_road.tscn", (W + 1) * T + 12, ty(G), ["lane = 232", "phase = 0.5"])
inst("Bike3", "res://scenes/hazards/bike_mtb.tscn", (W + 38) * T + 12, ty(G), ["lane = 168"])
inst("PigeonW1", "res://scenes/enemies/pigeon/pigeon.tscn", tx(W + 9), ty(G))
inst("PigeonW2", "res://scenes/enemies/pigeon/pigeon.tscn", tx(W + 44), ty(G))
inst("PgCheckpoint2", "res://scenes/objects/checkpoint.tscn", tx(W + 2), ty(G))
inst("PgCheckpoint3", "res://scenes/objects/checkpoint.tscn", tx(W + 40), ty(G))
hint(W + 3, G, "Bulwary! Przeskakuj rowerzystów, a przez Wisłę przejdź po łodziach.")

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
def m(col, mrow): return ((XO + col) * T, (mrow + YO) * T)   # a spot on the Rynek mockup (column, row)
pickups("R",
        [m(5.0, 12.1), m(9.5, 9.6), m(10.3, 9.6), m(15.1, 7.0), m(16.0, 7.0), m(22.1, 5.2), m(22.9, 5.2), m(26.9, 8.1), m(36.8, 7.15), m(45.0, 7.65)],
        [m(2.9, 5.4), m(30.8, 7.4), m(42.4, 10.0), m(46.9, 7.2)])
pickups("W",
        [above(W + 8, G, 30), above(W + 12, G, 30), above(W + 19, G + 0.6), above(W + 23, G + 0.6), above(W + 28, G + 0.4), above(W + 35, G + 0.4),
         above(W + 44, G, 30), above(W + 53, G - 0.2), above(W + 60, G - 0.2), above(W + 62.5, G - 0.2)],
        [above(W + 27.5, G + 3.5, 0), above(W + 31.6, G + 0.4, 34), above(W + 57, G + 3.5, 0), above(W + 46, G, 44)])
inst("LifeR", "res://scenes/objects/life.tscn", tx(30.5), ty(3.4) - 2)   # on top of the spire
inst("LifeW", "res://scenes/objects/life.tscn", tx(W + 33), ty(G + 6))   # on the riverbed under the barge

pos = _pos

# ======== 9. Kładka Bernatka (layout from assets/lvl4/kladkaBernatka/platforms.png, 48 columns x 16 rows) ========
# local column c is global N + c; mockup row r is world row r + BR (its quay, row 12.4, meets the promenade, row 17)
N = L + 128
BR = 4.6
BJ = json.load(open("assets/game/lvl4/bernatka_sizes.json"))
def btex(img): return f'texture = ExtResource("{R(f"res://assets/game/lvl4/bernatka/{img}.png", "Texture2D")}")'
def bdeco(img, x, row, h_tiles=0, scale=0.333333, parent="DecorBack"):
    w, h = BJ["sizes"][img]
    if h_tiles: scale = round(h_tiles * T / h, 4)
    node(uid("b_" + img + "_"), parent, "Sprite2D", props=[pos(round((N + x) * T), round(ty(row)) + 2), btex(img), "centered = false",
         f"offset = Vector2({-(w // 2)}, {-h})", f"scale = Vector2({scale}, {scale})"])
def bplat(name, img, x, mrow, path=None):   # centred on mockup column x, walkable top on mockup row mrow
    t = f'texture = ExtResource("{R(path, "Texture2D")}")' if path else btex(img)
    inst(name, "res://scenes/objects/lvl4/float_platform.tscn", round((N + x) * T), round(ty(mrow + BR)), [t, f"surface = {0 if path else BJ['surface'][img]}"])
def blamp(x, mrow_top, mrow_bottom):   # climbable street lamp from the mockup
    h = mrow_bottom - mrow_top
    bdeco("lamp_a", x, mrow_bottom + BR, h_tiles=h)
    inst(uid("Pole"), "res://scenes/objects/lvl4/pole.tscn", round((N + x) * T), round(ty(mrow_top + BR + 0.4)), [f"height_tiles = {round(h - 0.4)}"])
node("BernatkaBg", "WorldBack", "Sprite2D", props=[btex("bg"), "centered = false", pos(N * T, round(336 - 944 * KL_BG_SCALE)), f"scale = Vector2({KL_BG_SCALE}, {KL_BG_SCALE})"])   # bg2 (+220 px sky) at the other parts' scale, its bottom under the quay
for name, img, x, r in [("BA", "ledge_l", 6.7, 7.4), ("BStep1", "ledge_grass_s", 9.2, 6.1), ("BB", "ledge_l", 11.75, 4.6), ("BC", "pier_c", 13.9, 7.6),
                        ("BD", "ledge_s", 16.45, 5.2), ("BE", "ledge_m", 20.4, 4.1), ("BF", "ledge_m", 19.15, 8.6), ("BG", "ledge_m", 25.75, 5.2),
                        ("BH", "pier_c", 29.8, 3.6), ("BI", "ledge_m", 32.8, 5.8), ("BJ", "pier_c", 32.85, 10.4), ("BK", "ledge_m", 37.3, 7.1),
                        ("BStep2", "ledge_grass_s", 39.9, 8.0), ("BL", "ledge_m", 41.8, 9.1), ("BM", "pier_b", 44.75, 10.5), ("BN", "ledge_m", 44.2, 5.4)]:
    bplat(name, img, x, r)
bplat("BCrate", None, 13.5, 6.6, "res://assets/game/lvl3/crate.png")
for x, top, bottom in [(2.0, 7.8, 12.4), (3.4, 5.8, 12.4), (19.2, 5.8, 8.6), (36.7, 4.9, 7.1), (39.0, 9.7, 12.4)]:
    blamp(x, top, bottom)
inst(uid("Pole"), "res://scenes/objects/lvl4/pole.tscn", round((N + 45.6) * T), round(ty(5.6 + BR)), ["height_tiles = 5"])   # ivy up the quay wall
for img, x, r, h in [("ivy", 46.3, 7.6, 0), ("chain_posts", 10.5, 12.4, 1.4), ("bench", 14, 12.4, 1.2), ("bin", 16, 12.4, 1.1), ("chain_posts", 21, 12.4, 1.4),
                     ("chain_posts", 29, 12.4, 1.4), ("chain_posts", 37, 12.4, 1.4), ("lifebuoy", 23.4, 13.6, 1.3), ("planter_a", 1, 11.2, 1.3),
                     ("bush_a", 44.5, 10.5, 1.3), ("padlock_heart", 32, 12.4, 0.6), ("padlock_gold", 32.7, 12.4, 0.6),
                     ("pigeon", 16.4, 5.2, 1), ("gull", 29.6, 3.6, 1.1), ("duck", 34, 13.6, 0.9)]:   # sheet items are drawn big: sized in tiles
    bdeco(img, x, r + BR, h_tiles=h)
inst("BernBike1", "res://scenes/hazards/bike_road.tscn", (N + 6) * T, ty(17), [f"lane = {38 * T}"])
inst("BernBike2", "res://scenes/hazards/bike_mtb.tscn", (N + 6) * T, ty(17), [f"lane = {38 * T}", "phase = 0.45"])
inst("BernScooter", "res://scenes/hazards/scooter.tscn", (N + 6) * T, ty(17), [f"lane = {38 * T}", "speed = -150.0", "gap = 3.0", "phase = 0.5"])
for i, (x, r) in enumerate([(11.75, 4.6), (20.4, 4.1), (37.3, 7.1)]):   # pigeons on the stone blocks, as in the mockup
    inst(f"BernPigeon{i + 1}", "res://scenes/enemies/pigeon/pigeon.tscn", round((N + x) * T), ty(r + BR))
inst("CheckpointBern1", "res://scenes/objects/checkpoint.tscn", round((N + 1.5) * T), ty(16))
inst("CheckpointBern2", "res://scenes/objects/checkpoint.tscn", round((N + 30) * T), ty(17))
hint(N + 1, 16, "Kładka Bernatka! Legowisko czeka na murze po prawej - wejdź po bluszczu.")
def babove(x, mrow, up=14): return ((N + x) * T, ty(mrow + BR) - up)
pickups("N",
        [babove(5.5, 7.4), babove(7.9, 7.4), babove(10.8, 4.6), babove(12.7, 4.6), babove(20.4, 4.1), babove(24.9, 5.2), babove(26.6, 5.2),
         babove(36.2, 7.1), babove(38.4, 7.1), babove(44.2, 5.4, 30)],
        [babove(16.45, 5.2), babove(29.8, 3.6), babove(41.8, 9.1, 28), babove(44.75, 10.5)])

node("Spawn", typ="Marker2D", props=[pos(tx(4), ty(10))])
inst("Goal", "res://scenes/objects/goal.tscn", tx(N + 46.5), ty(10))   # on the quay wall past the Bernatka footbridge
inst("Cat", "res://scenes/player/cat.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")
inst("HUD", "res://scenes/ui/hud.tscn", 0, 0); nodes[-1] = nodes[-1].replace("position = Vector2(0, 0)\n", "")

# a floating block that a climbable pole runs through gets a gap in its solid body there (float_platform.gd gap_x),
# so the cat can climb the pole past it
import re
_poles = [float(re.search(r"position = Vector2\(([-\d.]+),", n).group(1)) for n in nodes if "lvl4/pole.tscn" in n.split("\n")[0] or 'ExtResource("' + R("res://scenes/objects/lvl4/pole.tscn", "PackedScene") + '")' in n.split("\n")[0]]
_fp = R("res://scenes/objects/lvl4/float_platform.tscn", "PackedScene")
for _i, _n in enumerate(nodes):
    if f'instance=ExtResource("{_fp}")' not in _n.split("\n")[0]:
        continue
    _x = float(re.search(r"position = Vector2\(([-\d.]+),", _n).group(1))
    _near = [px for px in _poles if abs(px - _x) < 40]   # (the cat is 10 px wide: leave 8 px either side of the pole)
    if _near:
        nodes[_i] = _n.rstrip("\n") + f"\ngap_x = {_near[0] - _x}\n"

head = ["[gd_scene format=4]\n", '[ext_resource type="Script" path="res://scenes/level/level.gd" id="r0"]']
head += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for p, (i, t) in res.items()]
head.append(f'[ext_resource type="Texture2D" path="res://assets/game/backdrop_dirt.png" id="rbd"]')
out = "\n".join(head) + "\n\n" + '[node name="Level04" type="Node2D"]\nscript = ExtResource("r0")\nbackdrop = ExtResource("rbd")\nbackdrop_top = 336.0\ncamera_bottom = 344.0\n\n' + "\n".join(nodes)
open("scenes/level/level_04.tscn", "w").write(out)
print("nodes", len(nodes))
