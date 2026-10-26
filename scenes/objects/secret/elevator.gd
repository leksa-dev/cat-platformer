extends AnimatableBody2D
# Lift out of a secret room: stand on it, it rises `rise` px into the shaft, then the cat steps out at `target`
# back in the level and the lift drops back down for next time.

@export var target: NodePath
@export var rise := 64.0
@export var speed := 40.0

var _start := Vector2.ZERO
var _wait := 0.0
var _moving := false


func _ready() -> void:
	_start = position


func _physics_process(delta: float) -> void:
	var cat := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var riding := cat != null and cat.is_on_floor() and absf(cat.global_position.x - global_position.x) < 20 \
		and absf(cat.global_position.y - global_position.y) < 3
	if not _moving:
		_wait = _wait + delta if riding else 0.0
		if _wait > 0.4:
			_moving = true
			Game.sfx("menu_move", 0.0)
		return
	position.y -= speed * delta
	if _start.y - position.y >= rise:
		if riding or (cat and cat.global_position.distance_to(global_position) < 40):
			cat.global_position = get_node(target).global_position
			cat.velocity = Vector2.ZERO
			get_tree().current_scene.leave_room()
		position = _start
		_moving = false
		_wait = 0.0
