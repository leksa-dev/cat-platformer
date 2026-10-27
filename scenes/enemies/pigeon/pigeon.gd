extends "res://scenes/enemies/enemy.gd"
# City pigeon. Struts around its spot (stopping now and then), and when the cat comes close it lowers its head,
# then flaps at the cat in a short low hop, wings out. Can be stomped.

@export var patrol_speed := 26.0
@export var run_speed := 60.0
@export var detect_range := 80.0
@export var lunge_range := 44.0
@export var lunge_velocity := Vector2(95, -105)
@export var windup := 0.3
@export var cooldown := 1.6
@export var peck_damage := 1
@export var patrol_radius := 40.0

enum { PATROL, WINDUP, LUNGE }
var _state := PATROL
var _timer := 0.0
var _cooldown := 0.0
var _rest := 0.0   # standing still for this long (pecking at the cobbles)
var _walk := 2.0   # strutting for this long before the next rest
var _hit := false


func _ready() -> void:
	super._ready()
	anim_fps = 12.0
	anims = {"idle": [0, 1, 2, 3, 4, 5, 6, 7, 8], "run": [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
		"attack": [19, 20, 21, 22, 23, 24, 25, 26, 27], "hurt": [28, 29, 30, 31], "death": [36, 37, 38, 39, 40, 41, 42, 43, 44]}
	_walk = randf_range(1.0, 3.0)
	play("idle")


func _ai(delta: float) -> void:
	_cooldown -= delta
	var d := to_cat()
	match _state:
		WINDUP:
			velocity.x = 0
			_timer -= delta
			if _timer <= 0:
				_state = LUNGE
				_hit = false
				velocity = Vector2(facing * lunge_velocity.x, lunge_velocity.y)
				play("attack", false)
		LUNGE:
			# the wings are out in the middle frames of the attack
			var f := int(_anim_time * anim_fps)
			if not _hit and f >= 1 and f <= 7 and hit_cat_in(Rect2(0, -15, 18, 15), peck_damage):
				_hit = true
			if is_on_floor() and velocity.y >= 0 and _anim_time > 0.1:
				_state = PATROL
				_cooldown = cooldown
		_:
			var sees := absf(d.x) < detect_range and absf(d.y) < 28
			if sees:
				face(d.x)
				if absf(d.x) < lunge_range and _cooldown <= 0 and is_on_floor():
					_state = WINDUP
					_timer = windup
					play("idle")
					return
				var blocked := is_on_wall() or (is_on_floor() and not ground_ahead()) or absf(d.x) < lunge_range * 0.5
				velocity.x = 0.0 if blocked else facing * run_speed
			elif _rest > 0:
				_rest -= delta
				velocity.x = 0
			else:
				_walk -= delta
				if _walk <= 0:
					_rest = randf_range(0.8, 1.8)
					_walk = randf_range(1.5, 3.5)
				patrol_walk(patrol_speed, patrol_radius)
			play("run" if velocity.x else "idle")
