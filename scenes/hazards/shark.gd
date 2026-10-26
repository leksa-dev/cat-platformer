extends "res://scenes/hazards/hazard.gd"
# Fin cutting the surface: swims back and forth around its spot and turns toward the surfing cat. Jump over it.

@export var speed := 45.0
@export var patrol_radius := 48.0
@export var turn_delay := 0.8  # seconds it keeps going after the cat jumped over it, before it turns back

var _dir := -1.0
var _home := 0.0
var _t := 0.0
var _turn := 0.0  # time spent wanting to turn around
var _min_x := -INF  # its stretch of sea (the surf zone it swims in): never onto land
var _max_x := INF


func _ready() -> void:
	_home = position.x
	for zone in get_parent().get_children():
		if zone is Area2D and zone.collision_layer == 32 and "width_tiles" in zone:
			var x0: float = zone.position.x
			var x1: float = x0 + zone.width_tiles * 16.0
			if position.x >= x0 and position.x <= x1:
				_min_x = x0 + 8
				_max_x = x1 - 8


func _move(delta: float) -> void:
	_t += delta
	var cat: Node2D = get_tree().get_first_node_in_group("player")
	if cat and absf(cat.global_position.x - global_position.x) < 96:
		var want := signf(cat.global_position.x - global_position.x)  # spotted: go for it
		_turn = _turn + delta if want != _dir else 0.0
		if _turn >= turn_delay:
			_dir = want
	elif absf(position.x - _home) > patrol_radius:
		_dir = signf(_home - position.x)
	position.x = clampf(position.x + _dir * speed * delta, _min_x, _max_x)
	$Sprite.flip_h = _dir > 0
	$Sprite.position.y = -4 + sin(_t * 5.0)  # bob with the waves
