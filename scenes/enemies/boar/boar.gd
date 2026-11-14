extends "res://scenes/enemies/enemy.gd"
# Wild boar (placeholder art: the dog sheet, recoloured): patrols, and when the cat is level with it paws the ground and then
# charges in a straight line, fast and unable to turn. A wall or an edge stops the charge and leaves it dazed.
# Not stompable; takes a few scratches.

@export var patrol_speed := 22.0
@export var charge_speed := 150.0
@export var detect_range := 96.0
@export var patrol_radius := 40.0
@export var windup := 0.6
@export var charge_time := 1.1
@export var dazed_time := 1.6
@export var cooldown := 2.0
@export var charge_damage := 2

enum { PATROL, WINDUP, CHARGE, DAZED }
var _state := PATROL
var _timer := 0.0
var _cooldown := 0.0
var _home_x := 0.0


func _ready() -> void:
	super._ready()
	_home_x = global_position.x
	# same frame layout as dog.png (frame 9 skipped)
	anims = {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7, 8], "attack": [10, 11, 12, 13], "hurt": [14, 15, 16], "death": [17, 18, 19, 20]}
	play("run")


func _ai(delta: float) -> void:
	_cooldown -= delta
	var d := to_cat()
	match _state:
		WINDUP:
			velocity.x = 0
			play("idle")
			sprite.position.x = sin(_timer * 60.0) * 0.8  # paws the ground, shaking
			_timer -= delta
			if _timer <= 0:
				sprite.position.x = 0.0
				_state = CHARGE
				_timer = charge_time
				play("run")
		CHARGE:
			velocity.x = facing * charge_speed
			anim_fps = 14.0
			hit_cat_in(Rect2(2, -14, 14, 12), charge_damage)
			_timer -= delta
			if is_on_wall() or not ground_ahead():
				_stop_charge(true)
			elif _timer <= 0:
				_stop_charge(false)
		DAZED:
			velocity.x = 0
			play("hurt")
			_timer -= delta
			if _timer <= 0:
				_state = PATROL
				_cooldown = cooldown
		_:
			anim_fps = 8.0
			if absf(d.x) < detect_range and absf(d.y) < 24 and _cooldown <= 0:
				face(d.x)
				_state = WINDUP
				_timer = windup
			else:
				_patrol()


func _stop_charge(hit_something: bool) -> void:
	anim_fps = 8.0
	velocity.x = 0
	if hit_something:
		Game.sfx("enemy_hit", 0.1, -6.0)
		_state = DAZED
		_timer = dazed_time
	else:
		_state = PATROL
		_cooldown = cooldown


func _patrol() -> void:
	var blocked := is_on_wall() or (is_on_floor() and not ground_ahead()) or (global_position.x - _home_x) * facing > patrol_radius
	if blocked:
		facing = -facing
	velocity.x = facing * patrol_speed
	play("run")
