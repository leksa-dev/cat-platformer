extends Node2D
# Hiding spot (cardboard box, or a bush when given a texture): the cat standing in it presses down and disappears inside; enemies don't
# see it (cat.gd hides itself, enemy.gd ignores an invisible cat). Jump / up / sideways comes out. Bottom-centre at the node.
# Placeholder art: a box drawn in code; with `texture` that sprite (drawn at 1/3) is used instead.

@export var texture: Texture2D
@export var width := 24.0

var occupied := false:
	set(value):
		occupied = value
		queue_redraw()
var _blink := 0.0


func _ready() -> void:
	add_to_group("hide_spot")
	if texture:
		var s := Sprite2D.new()
		s.texture = texture
		s.scale = Vector2.ONE / 3
		s.centered = false
		s.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
		add_child(s)
		width = texture.get_width() / 3.0


func covers(p: Vector2) -> bool:
	return absf(p.x - global_position.x) < width / 2.0 + 2.0 and absf(p.y - global_position.y) < 6.0


func _process(delta: float) -> void:
	if occupied:
		_blink += delta
		queue_redraw()


func _draw() -> void:
	if not texture:
		var w := width
		draw_rect(Rect2(-w / 2, -18, w, 18), Color(0.72, 0.53, 0.32))
		draw_rect(Rect2(-w / 2, -18, w, 18), Color(0.45, 0.31, 0.18), false, 1.0)
		draw_line(Vector2(-w / 2, -18), Vector2(-w / 2 - 5, -23), Color(0.62, 0.45, 0.27), 2.0)   # open flaps
		draw_line(Vector2(w / 2, -18), Vector2(w / 2 + 5, -23), Color(0.62, 0.45, 0.27), 2.0)
		draw_line(Vector2(-3, -12), Vector2(3, -12), Color(0.45, 0.31, 0.18), 1.0)
	if occupied and fmod(_blink, 2.6) < 2.3:   # two eyes peeking out, blinking now and then
		var y := -12.0 if not texture else -8.0
		draw_circle(Vector2(-3, y), 1.2, Color(1, 0.9, 0.3))
		draw_circle(Vector2(3, y), 1.2, Color(1, 0.9, 0.3))
