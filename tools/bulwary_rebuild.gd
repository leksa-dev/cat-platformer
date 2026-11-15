extends SceneTree
# Level 4 Bulwary at double length: inserts 64 columns where Bernatka starts (col 684) and repaints cols 620-747 as quays (floor
# row 17) and Wisła channels (bed row 23). Prints Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/bulwary_rebuild.gd -- out.txt
const AT := 684
const COUNT := 64
const BOTTOM := 24
const RIVERS := [[637, 657], [670, 689], [702, 723], [736, 747]]


func _initialize() -> void:
	var g: TileMapLayer = load("res://scenes/level/level_04.tscn").instantiate().get_node("Ground")
	var terrain: int = g.get_cell_tile_data(Vector2i(625, 20)).terrain
	var moved := []
	for c in g.get_used_cells():
		if c.x >= AT:
			moved.append([c, g.get_cell_source_id(c), g.get_cell_atlas_coords(c), g.get_cell_alternative_tile(c)])
	for m in moved:
		g.erase_cell(m[0])
	for m in moved:
		g.set_cell(m[0] + Vector2i(COUNT, 0), m[1], m[2], m[3])
	var cells: Array[Vector2i] = []
	for x in range(620, AT + COUNT):
		var top := 17
		for r in RIVERS:
			if x >= r[0] and x <= r[1]:
				top = 23
		for y in range(0, BOTTOM + 1):
			g.erase_cell(Vector2i(x, y))
		for y in range(top, BOTTOM + 1):
			cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, terrain)
	FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE).store_string(Marshalls.raw_to_base64(g.tile_map_data))
	print("terrain ", terrain, " done")
	quit()
