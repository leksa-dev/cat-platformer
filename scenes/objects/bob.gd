extends Sprite2D
# Floating in the sea (buoys, boats, jet skis): rocks gently side to side and bobs a little.
# The sprite's origin is its bottom centre, at the waterline, so it tilts around it.

@export var angle := 4.0  # degrees either way
@export var speed := 1.6

var _y0 := 0.0
var _phase := 0.0


func _ready() -> void:
	_y0 = position.y
	_phase = position.x * 0.05  # neighbours don't rock in step


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * speed + _phase
	rotation_degrees = sin(t) * angle
	position.y = _y0 + sin(t * 1.3) * 0.8
