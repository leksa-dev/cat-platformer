extends "res://scenes/enemies/enemy.gd"
# Hangs on a thread from where it's placed. When the cat walks underneath it drops fast, bites at the bottom,
# then climbs back up slowly. The thread is a line from the anchor to the body.

@export var max_drop := 140.0
@export var drop_speed := 150.0
@export var climb_speed := 35.0
@export var trigger_width := 20.0
@export var bite_damage := 2
@export var hold_time := 0.6
@export var redrop_after := 0.4  # seconds of climbing before it can drop on the cat again

enum { WAIT, DROP, HOLD, CLIMB }
var _state := WAIT
var _timer := 0.0
var _thread: Line2D


func _ready() -> void:
	super._ready()
	anims = {"hang": [0, 2], "drop": [1], "hurt": [3], "death": [3]}
	play("hang")
	_thread = Line2D.new()
	_thread.width = 1.0
	_thread.default_color = Color(0.8, 0.8, 0.75, 0.8)
	_thread.points = [Vector2.ZERO, Vector2.ZERO]
	add_child(_thread)
	move_child(_thread, 0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_thread.visible = not dead
	_thread.points = [home - global_position, Vector2(0, -12)]


func _ai(delta: float) -> void:
	var d := to_cat()
	match _state:
		WAIT:
			velocity = Vector2.ZERO
			play("hang")
			if absf(d.x) < trigger_width and d.y > 0 and d.y < max_drop + 20:
				_state = DROP
		DROP:
			play("drop")
			velocity = Vector2(0, drop_speed)
			hit_cat_in(Rect2(-8, -16, 16, 16), bite_damage)
			if global_position.y - home.y >= max_drop or is_on_floor() or absf(d.y) < 4:
				_state = HOLD
				_timer = hold_time
		HOLD:
			velocity = Vector2.ZERO
			hit_cat_in(Rect2(-8, -16, 16, 16), bite_damage)
			_timer -= delta
			if _timer <= 0:
				_state = CLIMB
				_timer = 0.0
		CLIMB:
			play("hang")
			velocity = Vector2(0, -climb_speed)
			_timer += delta
			var reach := home.y + max_drop - global_position.y  # thread left below it
			if _timer > redrop_after and absf(d.x) < trigger_width and d.y > 0 and d.y < reach + 20:
				_state = DROP  # the cat is underneath again: drop at once, no need to get home first
				return
			# back at the anchor; it hangs right under the ceiling, which can stop it a hair short of home.y
			if global_position.y <= home.y + 1 or is_on_ceiling():
				global_position.y = home.y
				_state = WAIT
