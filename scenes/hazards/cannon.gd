extends Node2D
# Cannon on the ground: when the cat is within `range` in front of it (`facing` -1 = left, 1 = right) it lobs a ball in an arc
# at the cat every `interval` seconds (1 damage on a hit). Placeholder art.

const BALL := preload("res://scenes/hazards/cannonball.tscn")

@export var facing := -1
@export var interval := 2.6
@export var range := 300.0
@export var speed := 170.0

var _cool := 1.2


func _physics_process(delta: float) -> void:
	_cool -= delta
	var cat := get_tree().get_first_node_in_group("player") as Node2D
	if cat == null or _cool > 0:
		return
	var d := cat.global_position + Vector2(0, -6) - (global_position + Vector2(facing * 14, -14))
	if d.x * facing < 24.0 or absf(d.x) > range or absf(d.y) > 90.0:
		return
	_cool = interval
	var ball := BALL.instantiate()
	get_parent().add_child(ball)
	ball.global_position = global_position + Vector2(facing * 16, -14)
	var t := absf(d.x) / speed   # flight time for a horizontal speed that lands on the cat
	ball.velocity = Vector2(facing * speed, d.y / t - 0.5 * ball.GRAVITY * t)
	Game.sfx("enemy_hit", 0.1, -4.0)
	queue_redraw()


func _draw() -> void:
	var s := float(facing)
	draw_circle(Vector2(-s * 2, -6), 6.0, Color(0.3, 0.2, 0.12))   # wheel
	draw_circle(Vector2(-s * 2, -6), 2.0, Color(0.15, 0.1, 0.06))
	draw_colored_polygon(PackedVector2Array([Vector2(-s * 8, -10), Vector2(s * 14, -18), Vector2(s * 16, -12), Vector2(-s * 8, -4)]), Color(0.22, 0.22, 0.26))
	draw_rect(Rect2(s * 13 - (4 if s < 0 else 0), -19, 4, 8), Color(0.14, 0.14, 0.17))
