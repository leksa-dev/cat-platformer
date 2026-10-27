@tool
extends Area2D
# Climbable pole (street lamp, catenary mast): climbs like the vine (layer 2). Node at the top; no art of its own,
# the lamp or mast sprite is placed as decor over it.

@export var height_tiles := 6:
	set(value):
		height_tiles = maxi(value, 1)
		_build()


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	var shape := get_node_or_null("Shape") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "Shape"
		shape.shape = RectangleShape2D.new()
		add_child(shape)
	var h := height_tiles * 16.0
	shape.shape.size = Vector2(10, h)
	shape.position = Vector2(0, h / 2)
