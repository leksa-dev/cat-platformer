extends SceneTree
# One-off: widens the Fort's fatal pit in part 1 (cols 238-243) by 3 columns: everything from col 244 on moves 3 columns right.
# Prints Ground tile_map_data (base64) to the given file.   Usage: godot --headless --script tools/fort_widen_pit.gd -- out.txt
const FROM := 244
const SHIFT := 3


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
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("moved ", moved.size(), " rect ", g.get_used_rect())
	quit()
