extends SceneTree
# One-off: makes the Kopiec three times longer. Everything from column 64 on (Kładka and the rest) moves 128 columns right
# with its exact tiles; columns 64-191 get the two new parts painted in autumn terrain:
#   part 2 (cols 64-127) the descent among the trees, part 3 (cols 128-191) a flat stretch that rises gently to the footbridge.
# Prints Ground tile_map_data (base64) to the given file.   Usage: godot --headless --script tools/kopiec_extend.gd -- out.txt
const AUTUMN := 4
const BOTTOM := 24
const SHIFT := 128
const FROM := 64
# [first col, last col, first solid row] for the new columns 64-191
const TOP := [[64, 67, 11], [68, 68, 12], [69, 72, 13], [73, 75, 14], [76, 79, 15], [80, 84, 16], [85, 87, 18], [88, 91, 17], [92, 97, 18],
		[98, 98, 19], [99, 102, 19], [103, 109, 20], [110, 111, 19], [112, 115, 20], [116, 127, 21],
		[128, 143, 21], [144, 159, 20], [160, 167, 19], [168, 175, 18], [176, 183, 17], [184, 191, 16]]


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var moved := []
	for c in g.get_used_cells():
		if c.x >= FROM:
			moved.append([c, g.get_cell_source_id(c), g.get_cell_atlas_coords(c), g.get_cell_alternative_tile(c)])
	for m in moved:
		g.erase_cell(m[0])
	for m in moved:
		g.set_cell(m[0] + Vector2i(SHIFT, 0), m[1], m[2], m[3])
	var cells: Array[Vector2i] = []
	for c in g.get_used_cells():
		var td = g.get_cell_tile_data(c)
		if c.x < FROM and td and td.terrain_set == 0 and td.terrain == AUTUMN:
			cells.append(c)
	for r in TOP:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], BOTTOM + 1):
				cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, AUTUMN)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size(), " moved ", moved.size(), " rect ", g.get_used_rect())
	quit()
