@tool
extends Area2D
# Rectangle of water, top-left at the surface. Resize with the exports; visuals and shape rebuild themselves.

@export var top_texture: Texture2D = preload("res://assets/game/water_top.png"):
	set(value):
		top_texture = value
		_build()
@export var body_texture: Texture2D = preload("res://assets/game/water.png"):
	set(value):
		body_texture = value
		_build()
@export var swimmable := true  # false for the sea, where the cat surfs instead

@export var width_tiles := 5:
	set(value):
		width_tiles = maxi(value, 1)
		_build()
@export var depth_tiles := 2:
	set(value):
		depth_tiles = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	collision_layer = 16 if swimmable else 0
	for child in get_children():
		child.free()
	var size := Vector2(width_tiles, depth_tiles) * 16.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2
	add_child(shape)
	_strip(top_texture, Rect2(0, 0, size.x, 16))
	if depth_tiles > 1:
		_strip(body_texture, Rect2(0, 16, size.x, size.y - 16))


func _strip(texture: Texture2D, rect: Rect2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, rect.size)
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(sprite)
