extends "res://scenes/hazards/hazard.gd"
# Vehicle (car, train, bike) driving along a lane `lane` px long from the node, then gone for `gap` s and back at the
# lane's start. Negative `speed` drives right to left. Drawn as a plain box until it gets art.

@export var lane := 320.0
@export var speed := 120.0
@export var gap := 1.5
@export var phase := 0.0  # 0..1 of the cycle, so lanes don't move in step
@export var color := Color(0.75, 0.2, 0.2)

var _start := 0.0
var _t := 0.0


func _ready() -> void:
	_start = position.x
	_t = phase * _cycle()


func _cycle() -> float:
	return lane / absf(speed) + gap


func _move(delta: float) -> void:
	_t = fmod(_t + delta, _cycle())
	var x := _t * absf(speed)
	active = x <= lane
	visible = active
	position.x = _start + (x if speed > 0 else lane - x)


func _draw() -> void:
	draw_rect(Rect2(-hit_size.x / 2, -hit_size.y, hit_size.x, hit_size.y), color)
	draw_rect(Rect2(-hit_size.x / 2 + 3, -hit_size.y - 4, hit_size.x - 6, 4), color.darkened(0.3))  # roof
