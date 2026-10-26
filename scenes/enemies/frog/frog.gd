extends "res://scenes/enemies/enemy.gd"
# Hops around its spot (also in water, where it floats), sits between hops. When the cat is in reach it stops,
# opens its mouth and shoots its tongue — the tongue has its own hitbox, reaching beyond the body. Stompable.

@export var hop_velocity := Vector2(80, -205)  # ~48 px far, ~30 px high
@export var sit_time := 0.8
@export var detect_range := 100.0
@export var tongue_range := 48.0
@export var windup := 0.5
@export var cooldown := 2.0
@export var tongue_damage := 2
@export var patrol_radius := 40.0

const TONGUE_OUT := 0.12
const TONGUE_HOLD := 0.2
const TONGUE_IN := 0.15

enum { SIT, HOP, LAND, WINDUP, TONGUE }
var _state := SIT
var _timer := 0.5
var _cooldown := 0.0
var _air := 0.0
var _tongue := 0.0  # current length

@onready var tongue_line: Line2D = $Tongue


func _ready() -> void:
	super._ready()
	# tongue-only frames (11, 13, 14) skipped: the tongue is drawn by tongue_line
	anims = {"idle": [0, 1, 2, 3], "jump": [4, 5, 6, 7, 8], "tongue": [9, 10, 12], "land": [15, 16], "hurt": [17, 18],
		"death": [19, 20, 21]}
	play("idle")


func _ai(delta: float) -> void:
	_cooldown -= delta
	var d := to_cat()
	var water := in_water()
	if water:  # float: buoyancy beats gravity until the body breaks the surface, then it bobs there
		velocity.y = clampf(velocity.y - gravity * 1.3 * delta, -40.0, 40.0)
	var grounded := is_on_floor() or water
	match _state:
		SIT:
			velocity.x = move_toward(velocity.x, 0, 400.0 * delta)
			play("idle")
			_timer -= delta
			if _timer > 0:
				pass
			elif absf(d.x) < tongue_range + 4 and absf(d.y) < 16 and _cooldown <= 0:
				face(d.x)
				_state = WINDUP
				_timer = windup
				play("tongue", false)
			elif grounded:
				if absf(d.x) < detect_range and absf(d.y) < 60:
					face(d.x)
				if (global_position.x - home.x) * facing > patrol_radius:
					facing = -facing
				_state = HOP
				_air = 0.0
				velocity = Vector2(facing * hop_velocity.x, hop_velocity.y * (0.8 if water else 1.0))
				play("jump", false)
		HOP:
			_air += delta
			if grounded and velocity.y >= 0 and _air > 0.1:
				_state = LAND
				_timer = 0.15
				velocity.x = 0
				play("land", false)
		LAND:
			_timer -= delta
			if _timer <= 0:
				_state = SIT
				_timer = sit_time
		WINDUP:
			velocity.x = 0
			_timer -= delta
			if _timer <= 0:
				_state = TONGUE
				_timer = 0.0
				Game.sfx("tongue")
		TONGUE:
			velocity.x = 0
			_timer += delta
			var t := _timer
			if t < TONGUE_OUT:
				_tongue = tongue_range * t / TONGUE_OUT
			elif t < TONGUE_OUT + TONGUE_HOLD:
				_tongue = tongue_range
			else:
				_tongue = tongue_range * maxf(0.0, 1.0 - (t - TONGUE_OUT - TONGUE_HOLD) / TONGUE_IN)
			if _tongue > 4:
				hit_cat_in(Rect2(6, -8, _tongue, 4), tongue_damage)
			if t >= TONGUE_OUT + TONGUE_HOLD + TONGUE_IN:
				_tongue = 0.0
				_state = SIT
				_timer = sit_time
				_cooldown = cooldown
	if _stun > 0 or dead:
		_tongue = 0.0
	tongue_line.visible = _tongue > 0
	tongue_line.points = PackedVector2Array([Vector2(6 * facing, -6), Vector2((6 + _tongue) * facing, -6)])
