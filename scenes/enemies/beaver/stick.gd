extends "res://scenes/hazards/cannonball.gd"
# Branch thrown by the beaver boss: the cannonball's arc, drawn as a spinning stick.


func _draw() -> void:
	draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0.36, 0.22, 0.1), 3.0)
	draw_line(Vector2(2, 0), Vector2(5, -3), Color(0.36, 0.22, 0.1), 2.0)
	draw_line(Vector2(-6, -1), Vector2(6, -1), Color(0.55, 0.36, 0.18), 1.0)
