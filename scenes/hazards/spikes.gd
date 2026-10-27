extends "res://scenes/hazards/hazard.gd"
# Row of red spikes `width_tiles` wide, standing on the node (bottom-left). Drawn as triangles until it gets art.

@export var width_tiles := 2


func _ready() -> void:
	hit_size = Vector2(width_tiles * 16.0 - 4, 6)
	hit_offset = Vector2(width_tiles * 8.0, -3)


func _draw() -> void:
	for i in width_tiles * 3:
		var x := i * 16.0 / 3
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 2.67, -7), Vector2(x + 5.33, 0)]), Color(0.85, 0.15, 0.15))
		draw_line(Vector2(x + 2.67, -7), Vector2(x + 4, -3), Color(1, 0.6, 0.6))
