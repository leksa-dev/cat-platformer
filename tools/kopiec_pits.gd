extends SceneTree
# One-off: digs the pits of the Kopiec's flat part (part 3) into the ground and re-connects the autumn terrain around them.
#   pit 1 (cols 134-136): shallow, 2 rows; pit 2 (cols 150-153): 3 rows, needs a wall-jump out; pit 3 (cols 163-167): no floor, fatal.
# Usage: godot --headless --script tools/kopiec_pits.gd -- out.txt   (prints Ground tile_map_data, base64)
const AUTUMN := 4
const BOTTOM := 24
const PITS := [[134, 136, 21, 22], [150, 153, 20, 22], [163, 167, 19, BOTTOM]]  # [first col, last col, first row, last row] removed


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	for p in PITS:
		for x in range(p[0], p[1] + 1):
			for y in range(p[2], p[3] + 1):
				g.erase_cell(Vector2i(x, y))
	var cells: Array[Vector2i] = []
	for c in g.get_used_cells():
		var td = g.get_cell_tile_data(c)
		if c.x >= 126 and c.x <= 176 and td and td.terrain_set == 0 and td.terrain == AUTUMN:
			cells.append(c)
	g.set_cells_terrain_connect(cells, 0, AUTUMN)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size())
	quit()
