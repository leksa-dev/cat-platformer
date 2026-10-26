extends Node2D

signal hit(body: Node2D)  # each body at most once per cloud

const FPS := 20.0

@export var drag := 60.0  # px/s² — the cloud drifts on in the fart direction, slowing down
@export var rise := 6.0  # px/s upward drift
@export var damage := 2
@export var stun := 1.0

var velocity := Vector2.ZERO
var _time := 0.0
var _already_hit := []

@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	sprite.flip_h = velocity.x < 0


func _physics_process(delta: float) -> void:
	_time += delta
	var frame := int(_time * FPS)
	if frame >= sprite.hframes:
		queue_free()
		return
	sprite.frame = frame
	position += (velocity + Vector2(0, -rise)) * delta
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta)

	# direct query, same reason as the cat's claws: Area2D overlap lists lag
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox_shape.shape
	query.transform = hitbox_shape.global_transform
	query.collision_mask = hitbox.collision_mask
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		if not _already_hit.has(result.collider):
			_already_hit.append(result.collider)
			if result.collider.has_method("hurt"):
				result.collider.hurt(damage, global_position, stun)
			hit.emit(result.collider)
