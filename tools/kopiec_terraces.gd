extends SceneTree
# One-off: rebuilds the Kopiec ground between columns 19 and 53 as terraces climbing the mound (plus a pit before it),
# re-connects the autumn terrain and prints the new Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/kopiec_terraces.gd -- out.txt
const AUTUMN := 4
const BOTTOM := 24
# column ranges -> row of the walkable top (a 16 px step at most between neighbours, so every step is a plain jump)
const PROFILE := [[19, 22, 18], [23, 26, 16], [27, 28, 15], [29, 29, 14], [30, 31, 13], [32, 32, 12], [33, 34, 11], [35, 39, 10],
		[40, 41, 11], [42, 43, 12], [44, 45, 13], [46, 47, 14], [48, 48, 15], [49, 53, 17]]


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var autumn: Array[Vector2i] = []
	for c in g.get_used_cells():
		if c.x >= 19 and c.x <= 53:
			g.erase_cell(c)
	for c in g.get_used_cells():
		var td = g.get_cell_tile_data(c)
		if td and td.terrain_set == 0 and td.terrain == AUTUMN:
			autumn.append(c)
	for r in PROFILE:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], BOTTOM + 1):
				autumn.append(Vector2i(x, y))
	g.set_cells_terrain_connect(autumn, 0, AUTUMN)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size())
	quit()
