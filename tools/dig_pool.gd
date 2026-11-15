extends SceneTree
# Digs a pool into level 4's ground: columns FROM..TO lose their tiles above row BED (the bed stays, re-joined to its
# neighbours). Prints Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/dig_pool.gd -- <from> <to> <bed row> out.txt
const BOTTOM := 24


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var g: TileMapLayer = load("res://scenes/level/level_04.tscn").instantiate().get_node("Ground")
	var c0 := int(a[0])
	var c1 := int(a[1])
	var bed := int(a[2])
	var terrain: int = g.get_cell_tile_data(Vector2i(c0, BOTTOM)).terrain
	var cells: Array[Vector2i] = []
	for x in range(c0, c1 + 1):
		for y in range(0, bed):
			g.erase_cell(Vector2i(x, y))
		for y in range(bed, BOTTOM + 1):
			cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, terrain)
	FileAccess.open(a[3], FileAccess.WRITE).store_string(Marshalls.raw_to_base64(g.tile_map_data))
	quit()
