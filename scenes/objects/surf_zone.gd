@tool
extends Area2D
# Sea stretch the cat surfs across. Top-left = the water surface; the cat rides with its feet on it.
# The shape reaches above the surface so the cat stays "in" the zone while jumping.

@export var width_tiles := 40:
	set(value):
		width_tiles = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		child.free()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 16.0, 160)
	shape.shape = rect
	shape.position = Vector2(width_tiles * 8.0, -40)  # 120 px above the surface, 40 below
	add_child(shape)
