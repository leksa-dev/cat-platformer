extends CharacterBody2D
# Yarn ball the cat throws: flies in an arc, bounces off the ground losing speed, hits each enemy once
# (damage + a long stun: it's tangled), then lies on the ground for a moment and fades away.

signal hit(body: Node2D)

const FLIGHT := 8  # frames 0-7 spinning in flight, 8-10 lying on the ground
const REST := 8

@export var damage := 1
@export var stun := 2.0
@export var gravity := 500.0
@export var bounce := 0.5
@export var rest_time := 1.2  # on the ground before it fades

var _time := 0.0
var _rest := -1.0  # seconds lying on the ground, < 0 while it moves
var _already_hit := []

@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _physics_process(delta: float) -> void:
	_time += delta
	if _time > 6.0:
		queue_free()  # fell into a pit or the sea
		return
	if _rest >= 0:
		_rest += delta
		sprite.frame = REST + mini(int(_rest * 8), 2)
		modulate.a = clampf(1.0 - (_rest - rest_time) / 0.4, 0.0, 1.0)
		if _rest > rest_time + 0.4:
			queue_free()
		return
	velocity.y += gravity * delta
	var col := move_and_collide(velocity * delta)
	if col:
		var floor_hit := col.get_normal().y < -0.5
		velocity = velocity.bounce(col.get_normal()) * bounce
		if floor_hit and absf(velocity.y) < 40:  # too slow to bounce again: it stops
			_rest = 0.0
			return
	sprite.frame = int(_time * 16) % FLIGHT
	sprite.flip_h = velocity.x < 0  # frames fly right, the string trailing behind

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
				Game.rumble(0.3, 0.2, 0.1)
				velocity = Vector2(-velocity.x * 0.3, -80)  # bounces off the enemy and drops
			hit.emit(result.collider)
