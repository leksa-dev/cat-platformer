extends "res://scenes/hazards/hazard.gd"
# Row of steel spikes `width_tiles` wide, standing on the node (bottom-left); art from the Fort 31 sheet: strips of 8 and 4 spikes
# (8 px per spike) on a stone base, laid end to end, the last one cut short to fit.

const LONG := preload("res://assets/game/lvl4/fort/spikes_long.png")    # 8 spikes
const SHORT := preload("res://assets/game/lvl4/fort/spikes_short.png")  # 4 spikes

@export var width_tiles := 2


func _ready() -> void:
	hit_size = Vector2(width_tiles * 16.0 - 4, 9)
	hit_offset = Vector2(width_tiles * 8.0, -5)


func _draw() -> void:
	var total := width_tiles * 16.0
	var x := 0.0
	while x < total - 0.5:
		var left := total - x
		var tex: Texture2D = LONG if left >= 64.0 else SHORT
		var strip := 64.0 if tex == LONG else 32.0
		var s := strip / tex.get_width()
		var h := tex.get_height() * s
		var w := minf(strip, left)
		draw_texture_rect_region(tex, Rect2(x, -h + 1.5, w, h), Rect2(0, 0, w / s, tex.get_height()))
		x += strip
