extends "res://scenes/hazards/hazard.gd"
# Spiked stone slab hanging on a chain over the path (art from the Fort 31 sheet): waits up, drops fast, rests on the ground,
# rises slowly, repeats. The node is the bottom-centre of the slab resting on the ground; `lift` px up is where it hangs. The
# whole slab hurts. Two sprites: hanging and falling (on the ground it keeps the falling one, with dust).

const TEX_UP := preload("res://assets/game/lvl4/fort/crusher_up.png")
const TEX_MID := preload("res://assets/game/lvl4/fort/crusher_mid.png")

@export var width := 144.0      # drawn width of the slab (the art is scaled to it)
@export var lift := 88.0
@export var chain := 24.0       # px of chain drawn above the slab
@export var wait_up := 1.9
@export var fall_time := 0.18
@export var wait_down := 0.5
@export var rise_time := 1.1
@export var phase := 0.0  # 0..1 of the cycle

var _t := 0.0
var _y := 0.0  # current lift above the ground
var _tex: Texture2D = TEX_UP


func _ready() -> void:
	_t = phase * _cycle()
	_y = lift


func _cycle() -> float:
	return wait_up + fall_time + wait_down + rise_time


func _move(delta: float) -> void:
	_t = fmod(_t + delta, _cycle())
	if _t < wait_up:
		_y = lift
		_tex = TEX_UP
	elif _t < wait_up + fall_time:
		_y = lift * (1.0 - pow((_t - wait_up) / fall_time, 2.0))   # accelerates
		_tex = TEX_MID
	elif _t < wait_up + fall_time + wait_down:
		_y = 0.0
		_tex = TEX_MID   # spikes stay visible; the slam is shown by the dust
	else:
		_y = lift * (_t - wait_up - fall_time - wait_down) / rise_time
		_tex = TEX_UP
	var h := _tex.get_height() * width / TEX_UP.get_width()
	hit_size = Vector2(width - 8, h * 0.85)
	hit_offset = Vector2(0, -_y - h / 2)
	if _t >= wait_up and _t < wait_up + fall_time + wait_down:   # falling or slammed: smash crates in its way
		var box := Rect2(global_position.x - width / 2, global_position.y - _y - h, width, h)
		for c in get_tree().get_nodes_in_group("breakable"):
			if is_instance_valid(c) and box.has_point(c.global_position + Vector2(0, -10)):
				c.smash(global_position)
	queue_redraw()


func _draw() -> void:
	var s := width / TEX_UP.get_width()
	var size := _tex.get_size() * s
	var top := -_y - size.y
	draw_line(Vector2(0, top + 4), Vector2(0, top - chain), Color(0.22, 0.22, 0.26), 2.0)
	draw_texture_rect(_tex, Rect2(-size.x / 2, top, size.x, size.y), false)
	var since := _t - wait_up - fall_time
	if _y == 0.0 and since >= 0.0 and since < wait_down:   # dust puffs rolling out of both sides
		var k := since / wait_down
		for side in [-1.0, 1.0]:
			for i in 3:
				draw_circle(Vector2(side * (width / 2 + 2 + k * (10 + i * 8)), -3 - i * 2.0 - k * 4), 4.0 + i * 1.5, Color(0.82, 0.74, 0.6, 0.65 * (1.0 - k)))
