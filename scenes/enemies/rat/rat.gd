extends "res://scenes/enemies/enemy.gd"
# Small, fast. Patrols a short stretch, runs at the cat, winds up and leaps with a bite, then backs off.
# Can be stomped.

@export var patrol_speed := 40.0
@export var run_speed := 80.0
@export var detect_range := 70.0
@export var jump_range := 48.0
@export var jump_velocity := Vector2(120, -140)  # ~40-50 px leap
@export var windup := 0.2
@export var cooldown := 1.4
@export var bite_damage := 2
@export var patrol_radius := 24.0

enum { PATROL, WINDUP, JUMP, RETREAT }
var _state := PATROL
var _timer := 0.0
var _cooldown := 0.0
var _bit := false


func _ready() -> void:
	super._ready()
	# frames 9 and 22 in rat.png are extraction fragments, skipped
	anims = {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7, 8], "jump": [10, 11, 12, 13], "hurt": [18, 19], "death": [20, 21, 23]}
	play("run")


func _ai(delta: float) -> void:
	_cooldown -= delta
	var d := to_cat()
	match _state:
		WINDUP:
			velocity.x = 0
			_timer -= delta
			if _timer <= 0:
				_state = JUMP
				_bit = false
				velocity = Vector2(facing * jump_velocity.x, jump_velocity.y)
				play("jump", false)
		JUMP:
			if not _bit and hit_cat_in(Rect2(0, -10, 10, 10), bite_damage):
				_bit = true
			if is_on_floor() and velocity.y >= 0:
				_state = RETREAT
				_timer = 0.3
				_cooldown = cooldown
		RETREAT:  # hop back, still facing the cat
			velocity.x = -facing * 60 if ground_behind() else 0.0
			play("run")
			_timer -= delta
			if _timer <= 0:
				_state = PATROL
		_:
			var sees := absf(d.x) < detect_range and absf(d.y) < 24
			if sees:
				face(d.x)
				if absf(d.x) < jump_range and _cooldown <= 0 and is_on_floor():
					_state = WINDUP
					_timer = windup
					play("idle")
					return
				var blocked := is_on_wall() or (is_on_floor() and not ground_ahead())
				velocity.x = 0.0 if blocked else facing * run_speed
			else:
				patrol_walk(patrol_speed, patrol_radius)
			play("run" if velocity.x else "idle")


func ground_behind() -> bool:
	facing = -facing
	var ok := ground_ahead()
	facing = -facing
	return ok
