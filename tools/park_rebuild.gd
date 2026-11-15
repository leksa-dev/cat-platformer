extends SceneTree
# One-off: repaints Park Bednarskiego (level 4, cols 483-555) as rolling hills with no drops (and a shallow pond, cols 520-523).
# Prints Ground tile_map_data (base64) to the given file.   Usage: godot --headless --script tools/park_rebuild.gd -- out.txt
const GRASS := 0
const BOTTOM := 24
const FROM := 483
const TO := 555
const TOP := [[483, 489, 11], [490, 491, 12], [492, 493, 13], [494, 497, 14], [498, 503, 15], [504, 505, 14], [506, 507, 13],
		[508, 512, 12], [513, 514, 13], [515, 518, 14], [519, 519, 15], [520, 523, 17], [524, 524, 15], [525, 526, 14], [527, 528, 13],
		[529, 533, 12], [534, 536, 11], [537, 538, 12], [539, 555, 13]]


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
