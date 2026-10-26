extends Node2D
# Water wheel: turns clockwise and carries planks around its rim; the planks stay level (one-way, they carry the cat).

const PLANK := preload("res://assets/game/lvl3/plank.png")

@export var radius := 64.0
@export var planks := 5
@export var turn_time := 9.0  # seconds per revolution

var _angle := 0.0
var _planks: Array[AnimatableBody2D] = []


func _ready() -> void:
	$Wheel.scale = Vector2.ONE * (radius * 2.0 + 8.0) / $Wheel.texture.get_width()
	for i in planks:
		var body := AnimatableBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 4)
		shape.shape = rect
		shape.position.y = 2
		shape.one_way_collision = true
		body.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = PLANK
		sprite.scale = Vector2.ONE / 3
		sprite.position.y = 4
		body.add_child(sprite)
		add_child(body)
		_planks.append(body)
	_place()


func _physics_process(delta: float) -> void:
	_angle += TAU * delta / turn_time
	$Wheel.rotation = _angle
	_place()


func _place() -> void:
	for i in _planks.size():
		var a := _angle + TAU * i / _planks.size()
		_planks[i].position = Vector2(cos(a), sin(a)) * radius
