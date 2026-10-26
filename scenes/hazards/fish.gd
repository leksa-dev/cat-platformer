extends "res://scenes/hazards/hazard.gd"
# Jumps out of the sea in an arc every few seconds, then dives back. Harmless while under water.

@export var leap_velocity := Vector2(30, -230)
@export var gravity := 600.0
@export var interval := 2.0
@export var phase := 0.0  # stagger several fish

var _vel := Vector2.ZERO
var _home := Vector2.ZERO
var _wait := 0.0
var _in_air := false


func _ready() -> void:
	_home = position
	_wait = phase
	visible = false
	active = false


func _move(delta: float) -> void:
	if not _in_air:
		_wait -= delta
		if _wait <= 0:
			_in_air = true
			_vel = leap_velocity
			position = _home
			visible = true
			active = true
		return
	_vel.y += gravity * delta
	position += _vel * delta
	$Sprite.rotation = _vel.angle() if _vel.x >= 0 else _vel.angle() + PI
	$Sprite.flip_h = _vel.x < 0
	if position.y > _home.y and _vel.y > 0:  # back in the water
		_in_air = false
		_wait = interval
		visible = false
		active = false
