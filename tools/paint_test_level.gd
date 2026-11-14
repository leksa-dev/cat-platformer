extends SceneTree
# Paints the test level's ground (Stone terrain, grey) from a JSON list of [col, row] cells and prints its tile_map_data (base64) to a file.
# Usage: godot --headless --script tools/paint_test_level.gd -- cells.json out.txt   (called by tools/build_test_level.py)
const STONE := 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cells: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var scene: PackedScene = load("res://scenes/level/level_test.tscn")
	var level := scene.instantiate()
	var g: TileMapLayer = level.get_node("Ground")
	var list: Array[Vector2i] = []
	for c in cells:
		list.append(Vector2i(int(c[0]), int(c[1])))
	g.set_cells_terrain_connect(list, 0, STONE)
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(Marshalls.raw_to_base64(g.tile_map_data))
	f.close()
	print("cells ", g.get_used_cells().size())
	quit()
