extends SceneTree
# Inserts empty columns into level 4's ground: every tile from column AT on moves COUNT columns right; the new columns get a flat
# floor of TERRAIN from row ROW down, joined to its neighbours. Prints Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/insert_columns.gd -- <at> <count> <row> <terrain> out.txt
const BOTTOM := 24


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var at := int(a[0])
	var count := int(a[1])
	var row := int(a[2])
	var terrain := int(a[3])
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var moved := []
	for c in g.get_used_cells():
		if c.x >= at:
			moved.append([c, g.get_cell_source_id(c), g.get_cell_atlas_coords(c), g.get_cell_alternative_tile(c)])
	for m in moved:
		g.erase_cell(m[0])
	for m in moved:
		g.set_cell(m[0] + Vector2i(count, 0), m[1], m[2], m[3])
	var cells: Array[Vector2i] = []
	for x in range(at - 2, at + count + 2):
		for y in range(row, BOTTOM + 1):
			cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, terrain)
	var f := FileAccess.open(a[4], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("moved ", moved.size(), " rect ", g.get_used_rect())
	quit()
