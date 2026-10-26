extends "res://scenes/enemies/enemy.gd"
# Flies around its spot. Spotting the cat below, it moves above it, winds up, then dives at where the cat WAS
# when the dive started (no homing — dodgeable), and climbs back up.

@export var fly_speed := 50.0
@export var dive_speed := 160.0
@export var detect_range := 100.0
@export var hover_height := 60.0  # above the cat before diving
@export var windup := 0.45
@export var cooldown := 1.8
@export var peck_damage := 2

enum { PATROL, STALK, WINDUP, DIVE, RECOVER }
var _state := PATROL
var _timer := 0.0
var _cooldown := 0.0
var _t := 0.0
var _dive_to := Vector2.ZERO


func _ready() -> void:
	super._ready()
	# frame 22 in crow.png is a fragment, skipped
	anims = {"fly": [4, 5, 6, 7, 8], "dive": [9, 10, 11, 12, 13], "recover": [14, 15, 16, 17], "hurt": [18, 19], "death": [20, 21]}
	play("fly")


func _ai(delta: float) -> void:
	_cooldown -= delta
	_t += delta
	var d := to_cat()
	match _state:
		PATROL:
			fly_to(home + Vector2(sin(_t * 0.8) * 30, sin(_t * 1.6) * 4), fly_speed * 0.6)
			play("fly")
			if d.length() < detect_range and d.y > 0 and _cooldown <= 0:
				_state = STALK
		STALK:
			fly_to(global_position + d + Vector2(0, -hover_height), fly_speed)
			play("fly")
			if d.length() > detect_range * 1.5:
				_state = RECOVER
			elif absf(d.x) < 8 and absf(d.y - hover_height) < 12:
				_state = WINDUP
				_timer = windup
		WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			_timer -= delta
			if _timer <= 0:
				_state = DIVE
				Game.sfx("caw", 0.08, -3.0)
				_dive_to = global_position + to_cat() + Vector2(0, -6)  # locked in now
				velocity = (_dive_to - global_position).normalized() * dive_speed
				face(velocity.x)
				play("dive")
		DIVE:
			hit_cat_in(Rect2(-6, -12, 12, 12), peck_damage)
			if global_position.distance_to(_dive_to) < 6 or get_slide_collision_count() > 0:
				_state = RECOVER
				_cooldown = cooldown
		RECOVER:
			fly_to(Vector2(global_position.x, home.y), fly_speed)
			play("recover")
			if absf(global_position.y - home.y) < 6:
				_state = PATROL
