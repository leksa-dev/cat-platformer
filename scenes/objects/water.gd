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
@export var damage := 0  # toxic sludge: HP lost per sting while the cat is in it

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


func _physics_process(_delta: float) -> void:
	if damage > 0 and not Engine.is_editor_hint():
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.sting(damage)


func _build() -> void:
	if not is_inside_tree():
		return
	collision_layer = 16 if swimmable else 0
	collision_mask = 1 if damage > 0 else 0
	monitoring = damage > 0
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
	sprite.region_rect = Rect2(Vector2.ZERO, rect.size * 3)  # textures are 3x the logical size...
	sprite.scale = Vector2.ONE / 3                             # ...drawn at 1/3
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(sprite)
