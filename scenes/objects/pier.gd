@tool
extends StaticBody2D
# Wooden pier: boards on top (one-way: jump up through, stand on), posts down to the ground every 2 tiles.
# Top-left = the board surface.

const PLANK := preload("res://assets/game/beach/pier_plank.png")
const POST := preload("res://assets/game/beach/pier_post.png")

@export var width_tiles := 6:
	set(value):
		width_tiles = maxi(value, 1)
		_build()
@export var post_tiles := 3:  # how far the posts reach down
	set(value):
		post_tiles = maxi(value, 0)
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		child.free()
	var w := width_tiles * 16.0
	for x in range(8, int(w), 32):
		var post := Sprite2D.new()
		post.texture = POST
		post.centered = false
		post.region_enabled = true
		post.region_rect = Rect2(0, 0, 5, post_tiles * 16)
		post.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		post.position = Vector2(x - 2, 4)
		add_child(post)
	var boards := Sprite2D.new()
	boards.texture = PLANK
	boards.centered = false
	boards.region_enabled = true
	boards.region_rect = Rect2(0, 0, w, 5)
	boards.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(boards)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 4)
	shape.shape = rect
	shape.position = Vector2(w / 2, 2)
	shape.one_way_collision = true
	add_child(shape)
