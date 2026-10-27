extends SceneTree
# Paints level_05: Stone (terrain 1) under the square and the promenade, nothing where the river breaks it. Saves to _tmp.tscn.
const BOTTOM := 24
func _initialize():
	var level = load("res://scenes/level/level_05.tscn").instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var cells: Array[Vector2i] = []
	const W := 64
	for r in [[0, 63], [W, W + 16], [W + 38, W + 49], [W + 64, W + 71]]:   # square, then promenade stretches between the river breaks
		for x in range(r[0], r[1] + 1):
			for y in range(17, BOTTOM + 1):
				cells.append(Vector2i(x, y))
	for x in range(W + 17, W + 64):   # riverbed
		for y in range(BOTTOM - 1, BOTTOM + 1):
			cells.append(Vector2i(x, y))
	g.clear()
	g.set_cells_terrain_connect(cells, 0, 1)
	print("painted ", g.get_used_cells().size(), " rect ", g.get_used_rect())
	var packed := PackedScene.new()
	packed.pack(level)
	ResourceSaver.save(packed, "res://scenes/level/_tmp.tscn")
	quit()
