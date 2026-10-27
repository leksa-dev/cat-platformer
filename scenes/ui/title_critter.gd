extends Sprite2D
# Title screen cat / crab: plays its frames once, then sits still for a few seconds, and again.

@export var fps := 7.0
@export var rest_min := 2.0
@export var rest_max := 4.0
@export var first_delay := 1.0

var _t := 0.0
var _rest := 0.0


func _ready() -> void:
	_rest = first_delay


func _process(delta: float) -> void:
	if _rest > 0:
		_rest -= delta
		frame = 0
		return
	_t += delta
	var f := int(_t * fps)
	if f >= hframes:
		_t = 0.0
		_rest = randf_range(rest_min, rest_max)
		frame = 0
	else:
		frame = f
