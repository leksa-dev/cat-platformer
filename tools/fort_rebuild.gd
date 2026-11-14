extends SceneTree
# One-off: rebuilds Fort 31 from the author's sketch as three parts (cols 192-383) and moves everything after it 128 columns right.
#   part 1: two spike pits (3 deep) and a fatal pit; part 2: a pit with a checkpoint, a tall block, a step, a fatal pit, higher ground;
#   part 3: a long fatal pit to cross on crumbling platforms. Prints Ground tile_map_data (base64) to the given file.
# Usage: godot --headless --script tools/fort_rebuild.gd -- out.txt
const GRASS := 0
const BOTTOM := 24
const OLD_FORT := [192, 255]
const SHIFT := 128
const BASE := 17
# [first col, last col, first solid row]; missing = pit / void
const TOP := [[192, 194, 17], [195, 203, 20], [204, 218, 17], [219, 227, 20], [228, 237, 17], [244, 255, 17],
		[256, 286, 17], [287, 293, 21], [294, 298, 11], [299, 302, 13], [306, 319, 14],
		[320, 336, 17], [360, 383, 17]]


func _initialize() -> void:
	var level = load("res://scenes/level/level_04.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var moved := []
	for c in g.get_used_cells():
		if c.x >= OLD_FORT[0] and c.x <= OLD_FORT[1]:
			g.erase_cell(c)
		elif c.x > OLD_FORT[1]:
			moved.append([c, g.get_cell_source_id(c), g.get_cell_atlas_coords(c), g.get_cell_alternative_tile(c)])
	for m in moved:
		g.erase_cell(m[0])
	for m in moved:
		g.set_cell(m[0] + Vector2i(SHIFT, 0), m[1], m[2], m[3])
	var cells: Array[Vector2i] = []
	for r in TOP:
		for x in range(r[0], r[1] + 1):
			for y in range(r[2], BOTTOM + 1):
				cells.append(Vector2i(x, y))
	g.set_cells_terrain_connect(cells, 0, GRASS)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size(), " moved ", moved.size(), " rect ", g.get_used_rect())
	quit()
