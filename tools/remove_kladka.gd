extends SceneTree
# One-off: removes the footbridge (Kładka) between the Kopiec and Fort 31: its tiles (cols 192-255) go, everything after moves
# 64 columns left with its exact tiles, and the end of the Kopiec's flat part is levelled to row 17 (the Fort's ground level).
# Prints Ground tile_map_data (base64) to the given file.   Usage: godot --headless --script tools/remove_kladka.gd -- out.txt
const AUTUMN := 4
const CUT_FROM := 192
const CUT_TO := 255
const SHIFT := 64
const BOTTOM := 24


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var moved := []
	for c in g.get_used_cells():
		if c.x >= CUT_FROM and c.x <= CUT_TO:
			g.erase_cell(c)
		elif c.x > CUT_TO:
			moved.append([c, g.get_cell_source_id(c), g.get_cell_atlas_coords(c), g.get_cell_alternative_tile(c)])
	for m in moved:
		g.erase_cell(m[0])
	for m in moved:
		g.set_cell(m[0] - Vector2i(SHIFT, 0), m[1], m[2], m[3])
	for x in range(184, 192):   # the Kopiec's last 8 columns: row 17, like the Fort
		g.erase_cell(Vector2i(x, 16))
	var cells: Array[Vector2i] = []
	for c in g.get_used_cells():
		var td = g.get_cell_tile_data(c)
		if c.x >= 126 and c.x <= 191 and td and td.terrain_set == 0 and td.terrain == AUTUMN:
			cells.append(c)
	g.set_cells_terrain_connect(cells, 0, AUTUMN)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size(), " rect ", g.get_used_rect())
	quit()
