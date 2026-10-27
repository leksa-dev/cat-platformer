extends SceneTree
# Paints level_04: Autumn (terrain 4) for the Kopiec, Grass (0) for the park, Stone (1) for the city (greybox). Saves to _tmp.tscn.
const BOTTOM := 24
const grass := 0
const stone := 1
const autumn := 4  # the Kopiec: grass recoloured to its autumn blocks
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
	# 1. Kopiec Krakusa (from the platforms.png mockup): start, cave under it, lower path round the mound
	fill(autumn, 0, 1, 9); fill(autumn, 2, 9, 10); fill(autumn, 10, 12, 9); fill(autumn, 13, 13, 12)
	cut(4, 12, 12, 15); cut(13, 13, 14, 15)       # cave under the start, door on the right
	fill(autumn, 14, 18, 16); fill(autumn, 19, 22, 15); fill(autumn, 23, 27, 16)
	fill(autumn, 28, 28, 14); fill(autumn, 29, 31, 14, 14)   # pillar + overhang (sign on top, coin under it)
	fill(autumn, 29, 33, 17); fill(autumn, 34, 34, 15); fill(autumn, 35, 38, 17)
	fill(autumn, 39, 40, 15); fill(autumn, 41, 42, 16); fill(autumn, 43, 43, 15); fill(autumn, 44, 47, 14)
	fill(autumn, 48, 48, 16); fill(autumn, 49, 53, 17); fill(autumn, 54, 54, 16); fill(autumn, 55, 57, 14)
	fill(autumn, 58, 58, 12); fill(autumn, 59, 63, 10)   # up to the viewpoint
	# 2. footbridge over the road (from kladkaParkowa/platforms.png): verges, road under everything, right bank up to Parkowa
	const B := 64
	fill(stone, B, B + 63, 20)                      # road
	fill(grass, B, B + 5, 16); fill(grass, B + 6, B + 8, 17); fill(grass, B + 13, B + 19, 16); fill(grass, B + 20, B + 21, 17)
	fill(grass, B + 46, B + 46, 18); fill(grass, B + 47, B + 48, 17); fill(grass, B + 49, B + 54, 16); fill(grass, B + 55, B + 60, 17)
	fill(grass, B + 61, B + 61, 15); fill(grass, B + 62, B + 63, 13)
	# 3. Fort 31: flat ground, the walls are brick blocks placed by the builder
	fill(grass, 128, 191, 17)
	# everything after the fort (old greybox columns), shifted right by S tiles
	const S := 108
	# 2. ul. Parkowa
	fill(stone, 84 + S, 116 + S, 12)
	fill(stone, 92 + S, 93 + S, 11, 11)             # bench
	fill(stone, 95 + S, 99 + S, 9, 11)              # kiosk
	fill(stone, 109 + S, 109 + S, 10, 11)           # fence
	# stadium: stands, pitch, stands
	fill(stone, 117 + S, 118 + S, 11); fill(stone, 119 + S, 120 + S, 10); fill(stone, 121 + S, 122 + S, 9); fill(stone, 123 + S, 124 + S, 8)
	fill(grass, 125 + S, 141 + S, 12)               # pitch
	fill(stone, 142 + S, 143 + S, 10); fill(stone, 144 + S, 149 + S, 8); fill(stone, 150 + S, 151 + S, 10)
	# 3. Plac Lasoty: Villa Mira, Villa Julia with the clock tower
	fill(stone, 152 + S, 154 + S, 12)
	fill(stone, 155 + S, 163 + S, 6); fill(stone, 156 + S, 162 + S, 5, 5)
	fill(stone, 164 + S, 166 + S, 12)
	fill(stone, 167 + S, 174 + S, 7); fill(stone, 170 + S, 171 + S, 1, 6)
	fill(stone, 175 + S, 180 + S, 12)
	# Park Bednarskiego, in the old quarry
	fill(grass, 181 + S, 191 + S, 16)
	fill(stone, 192 + S, 193 + S, 11)               # playground tower
	fill(grass, 194 + S, 204 + S, 16)
	fill(grass, 205 + S, 208 + S, 11)               # rock ledge where the slide comes out
	fill(grass, 209 + S, 218 + S, 19)               # dip with hedgehogs, outdoor gym slab above
	fill(grass, 219 + S, 219 + S, 17)
	fill(grass, 220 + S, 230 + S, 16)
	fill(grass, 226 + S, 227 + S, 14, 14); fill(grass, 229 + S, 230 + S, 12, 12); fill(grass, 226 + S, 227 + S, 10, 10); fill(grass, 229 + S, 230 + S, 8, 8)   # limestone ledges
	fill(grass, 231 + S, 245 + S, 6)                # cliff top, park gate
	fill(stone, 246 + S, 247 + S, 7); fill(stone, 248 + S, 249 + S, 8); fill(stone, 250 + S, 251 + S, 9); fill(stone, 252 + S, 253 + S, 10); fill(stone, 254 + S, 255 + S, 11)
	fill(stone, 256 + S, 262 + S, 12)               # lair
	g.clear()
	for t in [grass, stone, autumn]:
		var list: Array[Vector2i] = []
		for c in cells:
			if cells[c] == t: list.append(c)
		g.set_cells_terrain_connect(list, 0, t)
	print("painted ", g.get_used_cells().size(), " of ", cells.size(), " rect ", g.get_used_rect())
	var packed := PackedScene.new()
	packed.pack(level)
	ResourceSaver.save(packed, "res://scenes/level/_tmp.tscn")
	quit()
