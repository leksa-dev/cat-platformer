@tool
extends Area2D
# Ladder: climbable like the vine (layer 2). Node at the top; the rung texture repeats down height_tiles.

@export var height_tiles := 6:
	set(value):
		height_tiles = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	var h := height_tiles * 16.0
	$Sprite.region_rect = Rect2(0, 0, 38, h * 3)
	$CollisionShape2D.shape.size = Vector2(10, h)
	$CollisionShape2D.position = Vector2(0, h / 2)
