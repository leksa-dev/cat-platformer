extends "res://scenes/hazards/hazard.gd"
# Cannon shot: flies a ballistic arc and is gone when it touches the ground, a wall, or after a few seconds.

const GRAVITY := 260.0

var velocity := Vector2.ZERO
var _age := 0.0


func _ready() -> void:
	hit_size = Vector2(8, 8)
	hit_offset = Vector2.ZERO


func _move(delta: float) -> void:
	_age += delta
	var from := global_position
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	var query := PhysicsRayQueryParameters2D.create(from, global_position, 1)
	if _age > 4.0 or not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
	rotation += delta * 8.0


func hit_cat() -> bool:
	if super.hit_cat():
		queue_free()
		return true
	return false


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.16, 0.16, 0.2))
	draw_circle(Vector2(-1, -1), 1.5, Color(0.5, 0.5, 0.58))
