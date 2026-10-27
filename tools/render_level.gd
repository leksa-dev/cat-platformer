extends SceneTree
# Renders a whole level at 1:1 (window = the map, no stretch, a camera over the middle, HUD hidden). Needs a window:
#   godot --path . --script tools/render_level.gd -- <level index, 0-based> <out.png>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var index := int(args[0])
	var G = root.get_node("Game")
	G.level_index = index
	change_scene_to_file(G.LEVELS[index])
	for i in 5: await process_frame
	var lvl := current_scene
	for n in lvl.get_node("HUD").get_children():
		if n is CanvasItem:
			n.visible = false
	var cat: Node2D = lvl.get_node("Cat")
	cat.set_physics_process(false)
	cat.position = lvl.get_node("Spawn").position
	var rect: Rect2i = lvl.get_node("Ground").get_used_rect()
	var width := rect.end.x * 16
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(width, 416)
	var cam := Camera2D.new()
	lvl.add_child(cam)
	cam.position = Vector2(width / 2.0, 192)
	cam.make_current()
	for i in 20: await process_frame
	root.get_texture().get_image().save_png(args[1])
	quit()
