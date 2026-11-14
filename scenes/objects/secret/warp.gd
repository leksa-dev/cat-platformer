extends Area2D
# Moves the cat to `target` (a Marker2D). With a `room` the camera is boxed into it (secret rooms float far above
# the level); without one the camera goes back to the level. push_dir 0: fires on touch (a pit); -1 / 1: the cat
# has to walk into it that way, or press down (a pipe mouth).

@export var target: NodePath
@export var room := Rect2()
@export_range(-1, 1) var push_dir := 0
@export var size := Vector2(16, 16)  # trigger area, top-left at the node
@export var door := false  # a drawn door: only "down" at it opens it (walking past does nothing); `label` is written above
@export var label := ""
@export var pipe_mouth := false  # draw an open pipe end (sewers), opening against push_dir

var _push := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2
	add_child(shape)
	if door:
		_draw_door()
	if pipe_mouth:
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://assets/game/lvl3/pipe_mouth.png")
		sprite.scale = Vector2.ONE / 3
		sprite.centered = false
		sprite.flip_h = push_dir > 0  # open end faces the cat walking in
		sprite.offset = Vector2(0, -46)
		sprite.position = Vector2(0, size.y)
		add_child(sprite)
	body_entered.connect(func(body): if push_dir == 0 and body.is_in_group("player"): warp(body))


func _draw_door() -> void:
	var frame := ColorRect.new()
	frame.color = Color(0.85, 0.8, 0.62)
	frame.position = Vector2(-2, -2)
	frame.size = size + Vector2(4, 2)
	frame.z_index = -1
	add_child(frame)
	var inside := ColorRect.new()
	inside.color = Color(0.08, 0.07, 0.1)
	inside.size = size
	inside.z_index = -1
	add_child(inside)
	if label != "":
		var text := Label.new()
		text.text = label
		text.add_theme_font_size_override("font_size", 8)
		text.add_theme_color_override("font_outline_color", Color.BLACK)
		text.add_theme_constant_override("outline_size", 3)
		text.position = Vector2(size.x / 2 - 40, -26)
		text.size = Vector2(80, 22)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		add_child(text)


func _physics_process(delta: float) -> void:
	if push_dir == 0 and not door:
		return
	var cat: Node2D = null
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			cat = body
	var pushing := cat != null and not door and Input.get_axis("left", "right") == push_dir
	_push = _push + delta if pushing else 0.0
	if cat and (_push > 0.15 or Input.is_action_just_pressed("down")):
		_push = 0.0
		warp(cat)


func warp(cat: CharacterBody2D) -> void:
	var level := get_tree().current_scene
	cat.global_position = get_node(target).global_position
	cat.velocity = Vector2.ZERO
	Game.sfx("splash" if push_dir else "dash", 0.0)
	if room.has_area():
		level.enter_room(room)
	else:
		level.leave_room()
