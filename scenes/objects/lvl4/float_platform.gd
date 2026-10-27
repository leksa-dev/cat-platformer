@tool
extends StaticBody2D
# Floating grass block (art from the Kopiec sheet, drawn at 1/3): the node is the top-centre of the walkable grass;
# `surface` is how far the grass tufts stick up above it. One-way, so the cat can jump up through it.

@export var texture: Texture2D:
	set(value):
		texture = value
		_build()
@export var surface := 4.0:
	set(value):
		surface = value
		_build()
@export var ledge_width := 0.0:  # no texture: an invisible ledge this wide (cornices, gables on a backdrop building)
	set(value):
		ledge_width = value
		_build()
@export var count := 1:  # the block repeated side by side, for longer platforms (footbridge deck, long ledges)
	set(value):
		count = maxi(value, 1)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree() or (texture == null and ledge_width <= 0):
		return
	for c in get_children():
		c.free()
	var piece := texture.get_width() / 3.0 if texture else ledge_width
	var w := piece * count
	for i in count if texture else 0:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE / 3
		sprite.position = Vector2(-w / 2 + i * piece, -surface)
		add_child(sprite)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w - 4, 6)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, 3)
	shape.one_way_collision = true
	add_child(shape)
