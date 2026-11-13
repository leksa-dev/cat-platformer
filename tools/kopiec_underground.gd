extends SceneTree
# One-off, runs on top of kopiec_terraces.gd: digs the Kopiec's underground. A deeper pit (steps up on its right) opens into
# corridor 2 running left under the cave, with a hole in the cave floor; corridor 1 runs under the mound from the valley
# at its right foot. Prints the new Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/kopiec_underground.gd -- out.txt
const AUTUMN := 4
const BOTTOM := 24
const CUT := [[5, 5, 16, 16],        # hole in the cave floor
		[5, 21, 17, 18],              # corridor 2 (under the cave and the start ground, into the pit)
		[19, 22, 16, 18],             # the pit, down to the corridor floor
		[29, 47, 15, 16]]             # corridor 1 under the mound
const FILL := [[22, 22, 18, 18]]      # step up out of the pit
const VALLEY := [48, 48, 17]          # the last terrace step becomes valley floor, so corridor 1 opens onto it


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var autumn := {}
	for c in g.get_used_cells():
		var td = g.get_cell_tile_data(c)
		if td and td.terrain_set == 0 and td.terrain == AUTUMN:
			autumn[c] = true
	for r in CUT:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], r[3] + 1):
				autumn.erase(Vector2i(x, y))
				g.erase_cell(Vector2i(x, y))
	for r in FILL:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], BOTTOM + 1):
				autumn[Vector2i(x, y)] = true
	for y in range(15, VALLEY[2]):
		autumn.erase(Vector2i(VALLEY[0], y))
		g.erase_cell(Vector2i(VALLEY[0], y))
	var list: Array[Vector2i] = []
	list.assign(autumn.keys())
	g.set_cells_terrain_connect(list, 0, AUTUMN)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size())
	quit()
