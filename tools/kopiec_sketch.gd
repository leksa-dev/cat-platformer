extends SceneTree
# Rebuilds the Kopiec ground (columns 0-63) from the author's sketch: start plateau over a big cave, a canyon whose floor
# climbs in steps to the mound, the stepped mound with a hollow chamber under it (stairs down on both sides, a well in the
# middle crossed on two ledges), the valley with stairs up to the right plateau. Prints Ground tile_map_data (base64).
# Usage: godot --headless --script tools/kopiec_sketch.gd -- out.txt
const AUTUMN := 4
const BOTTOM := 24
const LAST_COL := 63
# first solid row of each column (outer surface); ranges are [first col, last col, row]
const TOP := [[0, 1, 10], [2, 9, 11], [10, 12, 10], [13, 13, 13], [14, 15, 23], [16, 21, 21], [22, 22, 19], [23, 26, 17], [27, 28, 16],
		[29, 29, 18], [30, 31, 14], [32, 32, 13], [33, 34, 12], [35, 35, 11], [36, 37, 10], [38, 40, 9], [41, 42, 11], [43, 44, 13],
		[45, 45, 14], [46, 47, 15], [48, 53, 18], [54, 54, 17], [55, 57, 15], [58, 58, 13], [59, 63, 11]]
# chamber under the mound: [first col, last col, floor row] (air from row 16 down to the floor); the well has no floor
const CHAMBER := [[30, 30, 19], [31, 31, 20], [32, 32, 21], [33, 35, 22], [41, 44, 22], [45, 45, 21], [46, 46, 20], [47, 47, 19]]
const WELL := [36, 40]
const CAVE := [5, 13]  # air rows 13-23; the roof hook stays at cols 12-13, rows 13-14


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	for c in g.get_used_cells():
		if c.x >= 0 and c.x <= LAST_COL:
			var td = g.get_cell_tile_data(c)
			if td and td.terrain_set == 0 and td.terrain == AUTUMN:
				g.erase_cell(c)
	var solid := {}
	for r in TOP:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], BOTTOM + 1):
				solid[Vector2i(x, y)] = true
	for x in range(CAVE[0], CAVE[1] + 1):
		for y in range(13, 24):
			if not (x >= 12 and y <= 14):
				solid.erase(Vector2i(x, y))
	for r in CHAMBER:
		for x in range(r[0], r[1] + 1):
			for y in range(16, r[2]):
				solid.erase(Vector2i(x, y))
	for x in range(WELL[0], WELL[1] + 1):
		for y in range(16, BOTTOM + 1):
			solid.erase(Vector2i(x, y))
	var cells: Array[Vector2i] = []
	cells.assign(solid.keys())
	# the autumn terrain also borders what is already painted (columns 64+ are other terrains, left alone)
	g.set_cells_terrain_connect(cells, 0, AUTUMN)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size())
	quit()
