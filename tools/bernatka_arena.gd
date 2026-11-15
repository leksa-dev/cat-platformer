extends SceneTree
# Level 4 beaver arena at one screen wide (20 columns, 794-813): drops columns 814-825 (the end wall moves 12 columns
# left) and paints 5 columns of bank, a 10-column pool (bed row 23), 5 columns of bank. Prints Ground tile_map_data (base64).
# Usage: godot --headless --script tools/bernatka_arena.gd -- out.txt
const BOTTOM := 24


func _initialize() -> void:
	var g: TileMapLayer = load("res://scenes/level/level_04.tscn").instantiate().get_node("Ground")
	var terrain: int = g.get_cell_tile_data(Vector2i(796, BOTTOM)).terrain
	var moved := []
	for c in g.get_used_cells():
		if c.x >= 814:
			moved.append([c, g.get_cell_source_id(c), g.get_cell_atlas_coords(c), g.get_cell_alternative_tile(c)])
	for m in moved:
		g.erase_cell(m[0])
	for m in moved:
		if m[0].x >= 826:
			g.set_cell(m[0] - Vector2i(12, 0), m[1], m[2], m[3])
	var cells: Array[Vector2i] = []
	for x in range(794, 814):
		var top := 23 if x >= 799 and x <= 808 else 17
		for y in range(0, BOTTOM + 1):
			g.erase_cell(Vector2i(x, y))
		for y in range(top, BOTTOM + 1):
			cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, terrain)
	FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE).store_string(Marshalls.raw_to_base64(g.tile_map_data))
	quit()
