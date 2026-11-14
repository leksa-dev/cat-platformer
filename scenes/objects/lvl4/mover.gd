@tool
extends AnimatableBody2D
# Floating block gliding along `direction` for `distance` px from where it is placed and back, easing at both ends; it carries
# the cat. Same look as float_platform (art drawn at 1/3, node = top-centre of the walkable top, `surface` = tufts above it,
# one-way top), no solid body.

@export var texture: Texture2D:
	set(value):
		texture = value
		_build()
@export var surface := 4.0
@export var direction := Vector2.RIGHT
@export var distance := 80.0
@export var speed := 30.0
@export var phase := 0.0  # 0..1 of the cycle, so neighbours don't move in step

var _start := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	_start = position
	_t = phase * 2.0 * distance / speed
	_build()


func _build() -> void:
	if not is_inside_tree() or texture == null:
		return
	for c in get_children():
		c.free()
	var w := texture.get_width() / 3.0
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2.ONE / 3
	sprite.position = Vector2(-w / 2, -surface)
	add_child(sprite)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w - 4, 6)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, 3)
	shape.one_way_collision = true
	add_child(shape)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var period := 2.0 * distance / speed
	position = _start + direction.normalized() * distance * (0.5 - 0.5 * cos(TAU * _t / period))
