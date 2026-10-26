extends "res://scenes/enemies/enemy.gd"
# Hovers around its flowers. Spotting the cat it closes in to a short distance, winds up and darts in with
# a sting, then backs off. Short, fast attack instead of the crow's long dive.

@export var fly_speed := 60.0
@export var sting_speed := 140.0
@export var detect_range := 80.0
@export var keep_distance := 22.0  # where it hovers before stinging
@export var windup := 0.3
@export var sting_time := 0.2
@export var cooldown := 1.3
@export var sting_damage := 2

enum { PATROL, APPROACH, WINDUP, STING, RETREAT }
var _state := PATROL
var _timer := 0.0
var _cooldown := 0.0
var _t := 0.0


func _ready() -> void:
	super._ready()
	# frame 15 in wasp.png is only the slash effect, skipped
	anims = {"idle": [0, 1, 2, 3], "fly": [4, 5, 6, 7, 8], "approach": [9, 10, 11], "sting": [12, 13, 14, 16, 17],
		"hurt": [18, 19, 20], "death": [21, 22, 23, 24]}
	anim_fps = 12.0  # buzzing wings
	play("fly")


func _ai(delta: float) -> void:
	_cooldown -= delta
	_t += delta
	var d := to_cat()
	match _state:
		PATROL:
			fly_to(home + Vector2(sin(_t) * 20, sin(_t * 2.3) * 6), fly_speed * 0.5)
			play("fly")
			if d.length() < detect_range and _cooldown <= 0:
				_state = APPROACH
		APPROACH:
			var side := -signf(d.x) if d.x else 1.0
			fly_to(global_position + d + Vector2(side * keep_distance, -8), fly_speed)
			face(d.x)
			play("approach")
			if d.length() > detect_range * 1.6:
				_state = PATROL
			elif absf(absf(d.x) - keep_distance) < 4 and absf(d.y - 8) < 6:  # hovering 8 px above the cat
				_state = WINDUP
				_timer = windup
		WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			face(d.x)
			play("idle")
			_timer -= delta
			if _timer <= 0:
				_state = STING
				_timer = sting_time
				Game.sfx("sting", 0.1, -3.0)
				velocity = (d + Vector2(0, -6)).normalized() * sting_speed
				play("sting", false)
		STING:
			hit_cat_in(Rect2(2, -12, 10, 8), sting_damage)
			_timer -= delta
			if _timer <= 0:
				_state = RETREAT
				_timer = 0.4
				_cooldown = cooldown
				velocity = -velocity.normalized() * fly_speed
		RETREAT:
			play("fly")
			_timer -= delta
			if _timer <= 0:
				_state = PATROL
