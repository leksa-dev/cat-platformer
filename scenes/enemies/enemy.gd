class_name Enemy
extends CharacterBody2D
# Shared enemy base: HP, getting hit (knockback, short invulnerability, stun), death, contact damage, stomp,
# frame animation from a sprite strip. Subclasses fill `anims` (name -> list of sheet frames) and implement _ai(delta).

signal died

@export var max_hp := 3
@export var contact_damage := 1
@export var stompable := false  # cat can jump on its head (rat, frog)
@export var stomp_damage := 3
@export var flying := false
@export var gravity := 700.0
@export var hurt_invuln := 0.4  # so a scratch flurry doesn't delete it instantly
@export var knockback := 80.0
@export var anim_fps := 8.0
## In water: NONE = the subclass handles it (frog), SWIM_OUT = paddle back to land (dog, rat), DROWN = dies (crow, wasp)
@export_enum("None", "Swim out", "Drown") var water_behavior := 0

enum { WATER_NONE, WATER_SWIM_OUT, WATER_DROWN }

var anims := {}  # name -> [sheet frame, ...]
var hp := 0
var facing := 1.0
var home := Vector2.ZERO  # where it was placed; patrols/hovers around it
var dead := false
var _invuln := 0.0
var _stun := 0.0
var _anim := ""
var _anim_loop := true
var _anim_time := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var body_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hp = max_hp
	home = global_position
	_ignore_cat.call_deferred()


func _ignore_cat() -> void:
	var cat := find_cat()
	if cat:
		add_collision_exception_with(cat)  # pass through the cat; touching hurts instead of pushing


func find_cat() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player")


func hurt(amount: int, from: Vector2, stun := 0.0) -> void:
	if dead or _invuln > 0:
		return
	hp -= amount
	Game.sfx("enemy_hit")
	_invuln = hurt_invuln
	_stun = maxf(stun, 0.3)
	velocity = Vector2(signf(global_position.x - from.x) * knockback, -60.0 if not flying else 0.0)
	if hp <= 0:
		Game.sfx("enemy_die")
		dead = true
		collision_layer = 0  # no more hits; world collision stays so the body lands
		play("death", false)
		died.emit()


func play(anim: String, loop := true) -> void:
	if _anim != anim:
		_anim = anim
		_anim_time = 0.0
	_anim_loop = loop


func anim_done() -> bool:
	return not _anim_loop and _anim_time * anim_fps >= anims[_anim].size()


func _physics_process(delta: float) -> void:
	_invuln -= delta
	_stun -= delta
	if not flying or dead:
		velocity.y += gravity * delta
	var water := water_behavior != WATER_NONE and in_water()
	if water and water_behavior == WATER_DROWN and not dead:
		hp = 0
		dead = true
		collision_layer = 0
		play("death", false)
		died.emit()
	if dead:
		velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
		if water:
			velocity.y = minf(velocity.y, 25.0)  # sink slowly
		move_and_slide()
		_animate(delta)
		if anim_done() and not is_queued_for_deletion() and sprite.modulate.a == 1.0:
			create_tween().tween_property(sprite, "modulate:a", 0.0, 0.5).finished.connect(queue_free)
		return
	if water:  # swim_out: forget the cat, float, paddle back toward its spot on land, hop out at the bank
		velocity.y = clampf(velocity.y - gravity * 1.3 * delta, -40.0, 40.0)
		face(home.x - global_position.x)
		velocity.x = facing * 35.0
		if is_on_wall():
			velocity.y = -200.0
		play("run")
	elif _stun > 0:
		play("hurt")
		velocity.x = move_toward(velocity.x, 0, 200.0 * delta)
	else:
		_ai(delta)
	move_and_slide()
	_touch_cat()
	_animate(delta)
	sprite.visible = _invuln <= 0 or int(_invuln * 20) % 2 == 0


func _ai(_delta: float) -> void:
	pass


func _animate(delta: float) -> void:
	if not anims.has(_anim):
		return
	_anim_time += delta
	var frames: Array = anims[_anim]
	var i := int(_anim_time * anim_fps)
	sprite.frame = frames[i % frames.size()] if _anim_loop else frames[mini(i, frames.size() - 1)]
	sprite.flip_h = facing < 0


# --- helpers for subclasses ---

func to_cat() -> Vector2:  # vector to the cat, or far away if there is none
	var cat := find_cat()
	return cat.global_position - global_position if cat else Vector2(INF, INF)


func face(dir_x: float) -> void:
	if dir_x:
		facing = signf(dir_x)


# ground enemies: walk, turning at walls, edges and the patrol radius around home
func patrol_walk(speed: float, radius: float) -> void:
	var blocked := is_on_wall() or (is_on_floor() and not ground_ahead()) or (global_position.x - home.x) * facing > radius
	if blocked:
		facing = -facing
	velocity.x = facing * speed


# flying enemies: head for a point
func fly_to(target: Vector2, speed: float) -> void:
	var d := target - global_position
	velocity = d.normalized() * speed if d.length() > 2 else Vector2.ZERO
	if absf(d.x) > 1:
		facing = signf(d.x)


func in_water() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(0, -4)
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return not get_world_2d().direct_space_state.intersect_point(query).is_empty()


func ground_ahead() -> bool:
	var from := global_position + Vector2(facing * 8, -4)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 12), 1, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


# damage the cat if it's inside `rect` (local, facing right; mirrored when facing left)
func hit_cat_in(rect: Rect2, damage: int) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var centre := rect.get_center()
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position + Vector2(centre.x * facing, centre.y))
	query.collision_mask = 1
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		if result.collider.is_in_group("player"):
			result.collider.take_damage(damage, global_position)
			return true
	return false


func _touch_cat() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_shape.shape
	query.transform = body_shape.global_transform
	query.collision_mask = 1
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		var cat: Node2D = result.collider
		if not cat.is_in_group("player"):
			continue
		# stomp: it was falling and its feet were above our middle before its last move (it may have landed since)
		var feet_before: float = cat.global_position.y - cat.fall_speed * get_physics_process_delta_time()
		if stompable and cat.fall_speed > 0 and feet_before <= body_shape.global_position.y:
			hurt(stomp_damage, cat.global_position)
			cat.bounce()
		else:
			cat.take_damage(contact_damage, global_position)
		return
