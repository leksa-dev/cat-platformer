extends "res://scenes/enemies/enemy.gd"
# Beach crab. Scuttles sideways around its spot, closes in on the cat, raises a claw and snaps.
# Shelled: jumping on it hurts the cat instead.

@export var patrol_speed := 25.0
@export var chase_speed := 50.0
@export var detect_range := 64.0
@export var snap_range := 14.0
@export var snap_damage := 1
@export var cooldown := 1.2
@export var patrol_radius := 24.0

enum { PATROL, SNAP }
var _state := PATROL
var _cooldown := 0.0
var _bit := false


func _ready() -> void:
	super._ready()
	anims = {"idle": [0, 1, 2, 3, 4], "run": [5, 6, 7, 8, 9, 10, 11, 12], "attack": [13, 14, 15, 16, 17, 18, 19, 20],
		"hurt": [21, 22, 23, 24, 25, 26], "death": [27, 28, 29, 30, 31, 32]}
	play("run")


func _ai(delta: float) -> void:
	_cooldown -= delta
	var d := to_cat()
	if _state == SNAP:
		velocity.x = 0
		# frames 3-5 of the attack: the claw comes down
		var f := int(_anim_time * anim_fps)
		if not _bit and f >= 3 and f <= 5 and hit_cat_in(Rect2(0, -7, 10, 7), snap_damage):
			_bit = true
		if anim_done():
			_state = PATROL
			_cooldown = cooldown
		return
	var sees := absf(d.x) < detect_range and absf(d.y) < 24
	if sees:
		face(d.x)
		if absf(d.x) < snap_range and _cooldown <= 0 and is_on_floor():
			_state = SNAP
			_bit = false
			play("attack", false)
			return
		var blocked := is_on_wall() or (is_on_floor() and not ground_ahead()) or absf(d.x) < snap_range * 0.7
		velocity.x = 0.0 if blocked else facing * chase_speed
	else:
		patrol_walk(patrol_speed, patrol_radius)
	play("run" if velocity.x else "idle")
