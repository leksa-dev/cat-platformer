extends AnimatableBody2D
# Stone slab gliding back and forth: `distance` px to the right of where it's placed and back (sync_to_physics carries the cat).

@export var distance := 112.0
@export var speed := 30.0

var _start := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	_start = position


func _physics_process(delta: float) -> void:
	_t += delta
	var period := 2.0 * distance / speed
	position.x = _start.x + distance * (0.5 - 0.5 * cos(TAU * _t / period))  # eases at both ends
