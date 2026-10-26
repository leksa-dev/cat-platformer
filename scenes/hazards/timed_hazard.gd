@tool
extends Node2D
# Something that switches on and off on a cycle (fire from a pipe, sparks from a cable): flickers as a warning,
# then hurts the cat (and enemies) inside `hit_rect` while on. `phase` offsets the cycle so neighbours don't fire together.

@export var on_time := 1.2
@export var off_time := 1.8
@export var warn_time := 0.4
@export var phase := 0.0
@export var damage := 2
@export var hit_rect := Rect2(-6, 0, 12, 32)
@export var sound := ""

var _t := 0.0
var _was_on := false


func _ready() -> void:
	_t = phase * (on_time + off_time)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t = fmod(_t + delta, on_time + off_time)
	var on := _t < on_time
	var warn := not on and _t > on_time + off_time - warn_time
	$Effect.visible = on or (warn and int(_t * 16) % 2 == 0)
	$Effect.modulate.a = 1.0 if on else 0.35
	if on and not _was_on and sound != "" and _near_cat():
		Game.sfx(sound, 0.1, -6.0)
	_was_on = on
	if on:
		_hurt_cat()


func _near_cat() -> bool:
	var cat := get_tree().get_first_node_in_group("player")
	return cat != null and cat.global_position.distance_to(global_position) < 200


func _hurt_cat() -> void:
	var shape := RectangleShape2D.new()
	shape.size = hit_rect.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position + hit_rect.get_center())
	query.collision_mask = 1 | 8  # the cat, and enemies (layer 4) get burnt too
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		if result.collider.is_in_group("player"):
			result.collider.take_damage(damage, global_position)
		elif result.collider.has_method("hurt"):
			result.collider.hurt(damage, global_position)
