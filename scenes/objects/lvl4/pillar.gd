@tool
extends StaticBody2D
# Solid concrete pillar (good for wall-jumps): the texture repeats downward `height_tiles` from the node (top-centre).

@export var texture: Texture2D:
	set(value):
		texture = value
		_build()
@export var height_tiles := 6:
	set(value):
		height_tiles = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree() or texture == null:
		return
	for c in get_children():
		c.free()
	var w := texture.get_width() / 3.0
	var h := height_tiles * 16.0
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.centered = false
	sprite.scale = Vector2.ONE / 3
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, texture.get_width(), h * 3)
	sprite.position = Vector2(-w / 2, 0)
	add_child(sprite)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w - 2, h)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, h / 2)
	add_child(shape)
