extends SceneTree
# Paints level_04 (greybox): Grass (terrain 0) for the hill and the park, Stone (terrain 1) for the city. Saves to _tmp.tscn.
const BOTTOM := 24
const grass := 0
const stone := 1
var cells := {}  # Vector2i -> terrain
func fill(terrain, x0, x1, y0, y1 = BOTTOM):
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			cells[Vector2i(x, y)] = terrain
func cut(x0, x1, y0, y1):
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			cells.erase(Vector2i(x, y))
func _initialize():
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	# 1. Kopiec Krakusa: flat top, stepped slope, crumbling-ledge pit, moat with a caponier
	fill(grass, 0, 11, 5)
	fill(grass, 12, 13, 6); fill(grass, 14, 15, 7); fill(grass, 16, 18, 8); fill(grass, 19, 20, 9); fill(grass, 21, 23, 10)
	fill(grass, 24, 27, 14)                 # pit under the crumbling ledges
	fill(grass, 28, 29, 12)
	fill(grass, 30, 33, 18)                 # fort moat floor (wall-jump out, or dash over)
	cut(26, 29, 15, 17)                     # caponier: a bunker in the moat's wall
	fill(grass, 34, 42, 12)
	# footbridge, sign gantry, road + railway below
	fill(stone, 43, 70, 12, 12)             # footbridge deck
	fill(stone, 74, 81, 13, 13)             # sign gantry
	fill(stone, 43, 83, 20)                 # road (43-66) and tracks (67-83)
	# 2. ul. Parkowa
	fill(stone, 84, 116, 12)
	fill(stone, 92, 93, 11, 11)             # bench
	fill(stone, 95, 99, 9, 11)              # kiosk
	fill(stone, 109, 109, 10, 11)           # fence
	# stadium: stands, pitch, stands
	fill(stone, 117, 118, 11); fill(stone, 119, 120, 10); fill(stone, 121, 122, 9); fill(stone, 123, 124, 8)
	fill(grass, 125, 141, 12)               # pitch
	fill(stone, 142, 143, 10); fill(stone, 144, 149, 8); fill(stone, 150, 151, 10)
	# 3. Plac Lasoty: Villa Mira, Villa Julia with the clock tower
	fill(stone, 152, 154, 12)
	fill(stone, 155, 163, 6); fill(stone, 156, 162, 5, 5)
	fill(stone, 164, 166, 12)
	fill(stone, 167, 174, 7); fill(stone, 170, 171, 1, 6)
	fill(stone, 175, 180, 12)
	# Park Bednarskiego, in the old quarry
	fill(grass, 181, 191, 16)
	fill(stone, 192, 193, 11)               # playground tower
	fill(grass, 194, 204, 16)
	fill(grass, 205, 208, 11)               # rock ledge where the slide comes out
	fill(grass, 209, 218, 19)               # dip with hedgehogs, outdoor gym slab above
	fill(grass, 219, 219, 17)
	fill(grass, 220, 230, 16)
	fill(grass, 226, 227, 14, 14); fill(grass, 229, 230, 12, 12); fill(grass, 226, 227, 10, 10); fill(grass, 229, 230, 8, 8)   # limestone ledges
	fill(grass, 231, 245, 6)                # cliff top, park gate
	fill(stone, 246, 247, 7); fill(stone, 248, 249, 8); fill(stone, 250, 251, 9); fill(stone, 252, 253, 10); fill(stone, 254, 255, 11)
	fill(stone, 256, 262, 12)               # lair
	g.clear()
	for t in [grass, stone]:
		var list: Array[Vector2i] = []
		for c in cells:
			if cells[c] == t: list.append(c)
		g.set_cells_terrain_connect(list, 0, t)
	print("painted ", g.get_used_cells().size(), " of ", cells.size(), " rect ", g.get_used_rect())
	var packed := PackedScene.new()
	packed.pack(level)
	ResourceSaver.save(packed, "res://scenes/level/_tmp.tscn")
	quit()
