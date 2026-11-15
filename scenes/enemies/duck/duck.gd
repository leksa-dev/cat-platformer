extends "res://scenes/enemies/enemy.gd"
# Mallard: paddles back and forth on water, or waddles along the bank; pecks the cat when it comes close. Mild: 1 damage, two
# scratches, can be stomped. Placed in water it floats on the surface (the node's y = the water's top) and never leaves it.

@export var speed := 18.0
@export var patrol_radius := 40.0
@export var peck_range := 12.0
@export var cooldown := 1.2

var _swims := false
var _peck := -1.0
var _cool := 0.0
var _bob := 0.0


func _ready() -> void:
	super._ready()
	# frames in assets/game/enemies/duck.png
	anims = {"float": [0, 1, 2, 3], "swim": [4, 5, 6, 7, 8, 9], "walk": [10, 11, 12, 13, 14, 15], "peck": [16, 17, 18, 19],
		"hurt": [20, 21, 22], "death": [23, 24, 25, 26]}
	play("walk")
	await get_tree().physics_frame   # the water's area isn't in the physics space until the first physics frame
	_swims = _on_water()
	if _swims:
		flying = true   # stays on the surface: no gravity
		water_behavior = WATER_NONE
	play("swim" if _swims else "walk")


func _on_water() -> bool:   # placed on the surface: the water is just below the node
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(0, 4)
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return not get_world_2d().direct_space_state.intersect_point(query).is_empty()


func _ai(delta: float) -> void:
	_cool -= delta
	if _swims:
		_bob += delta
		velocity.y = (home.y + sin(_bob * 2.5) * 0.8 - global_position.y) * 8.0
	if _peck >= 0:
		_peck += delta
		velocity.x = 0
		if _peck > 0.15 and _peck < 0.3:
			hit_cat_in(Rect2(2, -6, 8, 5), contact_damage)
		if _peck > 0.45:
			_peck = -1.0
			_cool = cooldown
		return
	var d := to_cat()
	if absf(d.x) < peck_range and absf(d.y) < 14 and _cool <= 0:
		face(d.x)
		_peck = 0.0
		play("peck", false)
		return
	if _swims:
		if absf(global_position.x - home.x) > patrol_radius:
			facing = -signf(global_position.x - home.x)
		velocity.x = facing * speed
		play("swim")
	else:
		patrol_walk(speed, patrol_radius)
		play("walk")
