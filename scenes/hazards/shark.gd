extends "res://scenes/hazards/hazard.gd"
# Fin cutting the surface: swims back and forth around its spot and turns toward the surfing cat. Jump over it.

@export var speed := 45.0
@export var patrol_radius := 48.0

var _dir := -1.0
var _home := 0.0
var _t := 0.0


func _ready() -> void:
	_home = position.x


func _move(delta: float) -> void:
	_t += delta
	var cat: Node2D = get_tree().get_first_node_in_group("player")
	if cat and absf(cat.global_position.x - global_position.x) < 96:
		_dir = signf(cat.global_position.x - global_position.x)  # spotted: go for it
	elif absf(position.x - _home) > patrol_radius:
		_dir = signf(_home - position.x)
	position.x += _dir * speed * delta
	$Sprite.flip_h = _dir > 0
	$Sprite.position.y = -4 + sin(_t * 5.0)  # bob with the waves
