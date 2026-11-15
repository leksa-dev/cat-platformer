extends Node2D
# Hiding spot (cardboard box, or a bush when given a texture): the cat standing in it presses down and disappears inside; enemies don't
# see it (cat.gd hides itself, enemy.gd ignores an invisible cat). Jump / up / sideways comes out. Bottom-centre at the node.
# The box (assets/game/box_hide.png, 7 frames): cat climbing in 0-3, eyes open 4, eyes shut 5, empty 6. With `texture` (a bush) that
# sprite is drawn instead, and two eyes are drawn over it while the cat is inside.

const BOX := preload("res://assets/game/box_hide.png")

@export var texture: Texture2D
@export var width := 24.0

var occupied := false:
	set(value):
		occupied = value
		_t = 0.0
		queue_redraw()
var _t := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("hide_spot")
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2.ONE / 3
	_sprite.centered = false
	if texture:
		_sprite.texture = texture
		_sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
		width = texture.get_width() / 3.0
	else:
		_sprite.texture = BOX
		_sprite.hframes = 7
		_sprite.frame = 6
		var cell := Vector2(BOX.get_width() / 7.0, BOX.get_height())
		_sprite.offset = Vector2(-cell.x / 2, -cell.y)
	add_child(_sprite)


func enter(from_x: float) -> void:
	occupied = true
	_sprite.flip_h = from_x > global_position.x   # the climbing-in frames come from the left


func covers(p: Vector2) -> bool:
	return absf(p.x - global_position.x) < width / 2.0 + 2.0 and absf(p.y - global_position.y) < 6.0


func _process(delta: float) -> void:
	_t += delta
	if texture:
		if occupied:
			queue_redraw()
		return
	if not occupied:
		_sprite.frame = 6
	elif _t < 0.4:
		_sprite.frame = mini(int(_t * 10), 3)
	else:
		_sprite.frame = 5 if fmod(_t, 2.6) > 2.35 else 4   # eyes, blinking now and then


func _draw() -> void:
	if texture and occupied and fmod(_t, 2.6) < 2.35:
		draw_circle(Vector2(-3, -8), 1.2, Color(0.5, 1, 0.4))
		draw_circle(Vector2(3, -8), 1.2, Color(0.5, 1, 0.4))
