extends "res://scenes/hazards/hazard.gd"
# Spiked block hanging over the path: waits up, drops fast, rests on the ground, rises slowly, repeats. The node is the bottom-centre
# of the block at rest on the ground; `lift` px up is where it hangs. The whole block hurts. Placeholder art (stone box with spikes).

@export var width := 144.0
@export var height := 56.0
@export var lift := 88.0
@export var wait_up := 1.9
@export var fall_time := 0.18
@export var wait_down := 0.5
@export var rise_time := 1.1
@export var phase := 0.0  # 0..1 of the cycle

var _t := 0.0
var _y := 0.0  # current lift above the ground


func _ready() -> void:
	_t = phase * _cycle()
	_y = lift


func _cycle() -> float:
	return wait_up + fall_time + wait_down + rise_time


func _move(delta: float) -> void:
	_t = fmod(_t + delta, _cycle())
	if _t < wait_up:
		_y = lift
	elif _t < wait_up + fall_time:
		_y = lift * (1.0 - pow((_t - wait_up) / fall_time, 2.0))   # accelerates
	elif _t < wait_up + fall_time + wait_down:
		_y = 0.0
	else:
		_y = lift * (_t - wait_up - fall_time - wait_down) / rise_time
	hit_size = Vector2(width - 4, height - 2)
	hit_offset = Vector2(0, -_y - height / 2)
	queue_redraw()


func _draw() -> void:
	var top := -_y - height
	draw_rect(Rect2(-width / 2, top, width, height - 12), Color(0.42, 0.40, 0.42))
	draw_rect(Rect2(-width / 2, top, width, 4), Color(0.6, 0.58, 0.6))
	for i in int(width / 8.0):
		var x := -width / 2 + i * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, top + height - 12), Vector2(x + 4, top + height), Vector2(x + 8, top + height - 12)]), Color(0.78, 0.78, 0.82))
	draw_line(Vector2(0, top), Vector2(0, top - 200), Color(0.3, 0.28, 0.3), 2.0)  # the chain it hangs on
