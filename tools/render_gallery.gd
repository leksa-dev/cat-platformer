extends SceneTree
# Renders one band of the asset gallery to a PNG (needs a window): godot --path . --script tools/render_gallery.gd -- <band index> <out.png>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	change_scene_to_file("res://scenes/gallery.tscn")
	for i in 5: await process_frame
	var g := current_scene
	var b: Dictionary = g.bands[int(args[0])]
	g.get_node("Cat").visible = false
	for n in g.get_children():
		if n is CanvasLayer:
			n.visible = false
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(3040, int(b.y1 - b.y0))
	var cam := Camera2D.new()
	g.add_child(cam)
	cam.position = Vector2(1520, b.y0 + (b.y1 - b.y0) / 2.0)
	cam.make_current()
	for i in 20: await process_frame
	root.get_texture().get_image().save_png(args[1])
	quit()
