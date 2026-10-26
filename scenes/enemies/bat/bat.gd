extends "res://scenes/enemies/enemy.gd"
# Hangs folded at its spot. When the cat enters its zone (the room around it) it swoops at the cat in wavy loops,
# bites when close, flutters off to a random spot in the zone, and goes back to sleep when the cat leaves.

@export var zone := Vector2(256, 128)  # zone size, centred on home horizontally, hanging down from it
@export var fly_speed := 75.0
@export var bite_damage := 2
@export var cooldown := 1.2

enum { SLEEP, CHASE, FLEE, HOME }
var _state := SLEEP
var _timer := 0.0
var _t := 0.0
var _flee_to := Vector2.ZERO


func _ready() -> void:
	super._ready()
	anims = {"sleep": [0], "fly": [1, 2], "hurt": [3], "death": [3]}
	play("sleep")


func _in_zone(p: Vector2) -> bool:
	return Rect2(home + Vector2(-zone.x / 2, -8), zone).has_point(p)


func _ai(delta: float) -> void:
	_t += delta
	_timer -= delta
	var cat := find_cat()
	var cat_in := cat != null and _in_zone(cat.global_position)
	match _state:
		SLEEP:
			velocity = Vector2.ZERO
			play("sleep")
			if cat_in:
				_state = CHASE
				Game.sfx("caw", 0.2, -8.0)
		CHASE:
			play("fly")
			# wavy swoop: aim a little above the cat's middle, bobbing up and down
			fly_to(cat.global_position + Vector2(0, -8 + sin(_t * 7.0) * 10.0), fly_speed)
			if not cat_in:
				_state = HOME
			elif hit_cat_in(Rect2(-8, -14, 16, 14), bite_damage):
				_state = FLEE
				_timer = cooldown
				_flee_to = home + Vector2(randf_range(-zone.x, zone.x) * 0.4, randf_range(8, zone.y * 0.5))
		FLEE:
			play("fly")
			fly_to(_flee_to, fly_speed)
			if _timer <= 0:
				_state = CHASE if cat_in else HOME
		HOME:
			play("fly")
			fly_to(home, fly_speed * 0.7)
			if global_position.distance_to(home) < 3:
				_state = SLEEP
			elif cat_in:
				_state = CHASE
