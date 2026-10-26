extends "res://scenes/enemies/enemy.gd"
# Patrols, turns at edges/walls/water, chases the cat on its level, barks under it when the cat is up a tree,
# winds up and bites. Can't climb or swim.

@export var patrol_speed := 30.0
@export var chase_speed := 55.0  # well below the cat (90), so running away works
@export var detect_range := 64.0
@export var patrol_radius := 40.0  # patrols this far either side of where it was placed
@export var attack_range := 14.0
@export var windup := 0.4
@export var bite_time := 0.15
@export var cooldown := 1.8
@export var bite_damage := 1  # lighter than the other enemies' attacks (2)

enum { PATROL, CHASE, BARK, WINDUP, BITE }
var _state := PATROL
var _timer := 0.0
var _cooldown := 0.0
var _home_x := 0.0
var _bark_cd := 0.0


func _ready() -> void:
	super._ready()
	_home_x = global_position.x
	# frame ranges in assets/game/enemies/dog.png (frame 9 has two dogs merged, skipped)
	anims = {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7, 8], "attack": [10, 11, 12, 13], "hurt": [14, 15, 16], "death": [17, 18, 19, 20]}
	play("run")


func _ai(delta: float) -> void:
	_cooldown -= delta
	_bark_cd -= delta
	var cat := find_cat()
	var to_cat := cat.global_position - global_position if cat else Vector2(INF, INF)
	var sees := absf(to_cat.x) < detect_range and absf(to_cat.y) < 100  # tall enough to spot the cat on a tree crown
	match _state:
		WINDUP:
			velocity.x = 0
			_timer -= delta
			if _timer <= 0:
				_state = BITE
				_timer = bite_time
		BITE:
			velocity.x = facing * 60  # small lunge
			if hit_cat_in(Rect2(4, -12, attack_range, 10), bite_damage):
				_timer = 0
			_timer -= delta
			if _timer <= 0:
				_state = CHASE
				_cooldown = cooldown
		_:
			if sees and absf(to_cat.y) > 20:  # cat up a tree / on a ledge: stand under it and bark
				_state = BARK
				facing = signf(to_cat.x) if to_cat.x else facing
				if absf(to_cat.x) > 10:
					_walk(chase_speed, false)  # run under the tree...
				else:
					velocity.x = move_toward(velocity.x, 0, 600.0 * delta)
					play("idle")  # ...and bark (idle frames are the barking pose)
					if _bark_cd <= 0:
						Game.sfx("bark", 0.1, -4.0)
						_bark_cd = 1.2
			elif sees:
				_state = CHASE
				facing = signf(to_cat.x) if to_cat.x else facing
				if absf(to_cat.x) < attack_range + 6 and _cooldown <= 0:
					_state = WINDUP
					_timer = windup
					play("attack", false)
				else:
					_walk(chase_speed, false)
			else:
				_state = PATROL
				_walk(patrol_speed, true)


func _walk(speed: float, turn_at_edge: bool) -> void:
	var blocked := is_on_wall() or (is_on_floor() and not ground_ahead())
	if turn_at_edge and (global_position.x - _home_x) * facing > patrol_radius:
		blocked = true
	if blocked and turn_at_edge:
		facing = -facing
	velocity.x = 0.0 if blocked and not turn_at_edge else facing * speed  # chasing: wait at the edge
	play("run" if velocity.x else "idle")
