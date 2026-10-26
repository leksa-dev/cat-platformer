@tool
extends StaticBody2D
# Walkable pipe: a one-way platform, top at the node, pipe sections with flanges repeated width_tiles across.

@export var solid := true:  # false: background pipe, nothing stands on it
	set(value):
		solid = value
		_build()
@export var width_tiles := 6:
	set(value):
		width_tiles = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	var w := width_tiles * 16.0
	$Sprite.region_rect = Rect2(0, 0, w * 3, 31)
	$CollisionShape2D.shape.size = Vector2(w, 4)
	$CollisionShape2D.position = Vector2(w / 2, 2)
	$CollisionShape2D.disabled = not solid
