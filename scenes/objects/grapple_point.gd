@tool
extends Node2D
# Yarn hook point: a ring the cat can throw its yarn at (grapple button, R2 / U / B) when it is within `reach` and above the cat;
# the cat swings from it while the button is held (cat.gd _try_grapple / _swing). Placeholder art drawn in code.

@export var reach := 120.0:
	set(value):
		reach = value
		queue_redraw()


func _ready() -> void:
	add_to_group("grapple")


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var cat := get_tree().get_first_node_in_group("player") as Node2D
	var near := cat != null and cat.global_position.distance_to(global_position) < reach and global_position.y < cat.global_position.y - 8
	if near != get_meta("near", false):
		set_meta("near", near)
		queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, -10), Vector2(0, -4), Color(0.35, 0.3, 0.28), 2.0)
	draw_arc(Vector2.ZERO, 4.0, 0, TAU, 16, Color(0.95, 0.8, 0.3) if get_meta("near", false) else Color(0.7, 0.62, 0.45), 2.0)
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, reach, 0, TAU, 48, Color(1, 1, 1, 0.25), 1.0)
