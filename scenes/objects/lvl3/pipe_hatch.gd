extends Area2D
# Hatch on top of a pipe: standing on it and pressing down sends the cat through the pipe (hidden, the camera
# follows along `route`, points relative to the hatch) and pops it out of the last point.

@export var route: PackedVector2Array = [Vector2(0, -20), Vector2(600, -20)]
@export var speed := 260.0

var _busy := false


func _physics_process(_delta: float) -> void:
	if _busy or not Input.is_action_just_pressed("down"):
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.is_on_floor():
			_travel(body)


func _travel(cat: CharacterBody2D) -> void:
	_busy = true
	Game.sfx("splash", 0.0)
	cat.visible = false
	cat.set_physics_process(false)
	cat.velocity = Vector2.ZERO
	var tween := create_tween()
	var from := cat.global_position
	for p in route:
		var to := global_position + p
		tween.tween_property(cat, "global_position", to, from.distance_to(to) / speed)
		from = to
	await tween.finished
	cat.visible = true
	cat.set_physics_process(true)
	cat.velocity = Vector2(30, cat.jump_velocity * 0.9)  # popped out of the exit pipe
	Game.sfx("jump", 0.0)
	_busy = false
