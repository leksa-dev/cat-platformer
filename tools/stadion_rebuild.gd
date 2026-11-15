extends SceneTree
# One-off: repaints the Stadion (level 4, cols 387-450) almost flat: the pitch at row 17, a one-row dip for the dugout, and steps up
# to the park (row 11) at the end. Prints Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/stadion_rebuild.gd -- out.txt
const GRASS := 0
const BOTTOM := 24
const FROM := 387
const TO := 450
const TOP := [[387, 419, 17], [420, 423, 18], [424, 437, 17], [438, 439, 16], [440, 441, 15], [442, 443, 14], [444, 445, 13],
		[446, 447, 12], [448, 450, 11]]


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	for c in g.get_used_cells():
		if c.x >= FROM and c.x <= TO:
			g.erase_cell(c)
	var cells: Array[Vector2i] = []
	for r in TOP:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], BOTTOM + 1):
				cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, GRASS)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size())
	quit()
