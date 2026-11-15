extends "res://scenes/enemies/enemy.gd"
# Beaver boss at the end of level 4: waits in its arena (two banks round a pool); once the cat walks in, the camera locks to
# the arena, a wall shuts the way back and a boss HP bar shows.
# On a bank: throws a branch in an arc at the cat (three when below half HP) -> paws the ground and charges (a wall leaves it
# dazed) -> dives into the pool. Landing back on a bank it is dazed for a moment, then tail-slams close by and starts over.
# In the pool it swims under the surface where claws can't reach it, follows the cat from below and leaps out at it (twice
# at most, then onto a bank, where it lands dazed). A cat that falls in is chased and bitten.
# Beaten, the camera and wall free up and the nodes in group "boss_reward" appear.

const STICK := preload("res://scenes/enemies/beaver/stick.gd")

@export var arena_left := 0.0
@export var arena_right := 0.0
@export var pool_left := 0.0
@export var pool_right := 0.0
@export var water_top := 296.0
@export var charge_speed := 150.0
@export var charge_damage := 2
@export var bite_damage := 2

enum { WAIT, IDLE, THROW, WINDUP, CHARGE, DAZED, TAIL, DIVE, SWIM, LEAP }
var _state := WAIT
var _timer := 0.0
var _next := THROW
var _thrown := 0
var _leaps := 0
var _bite_cd := 0.0
var _leap_vx := 0.0  # kept through the leap: scraping the pool wall on the way up must not stop it short of the bank
var _wall: StaticBody2D
var _bar: ProgressBar
var _ui: CanvasLayer


func _ready() -> void:
	super._ready()
	anims = {"idle": [0, 1, 2, 3, 4, 5], "run": [6, 7, 8, 9, 10, 11], "throw": [12, 13, 14, 15, 16, 17, 18, 19, 20],
		"charge": [21, 22, 23, 24, 25, 26, 27, 28], "tail": [29, 30, 31, 32, 33, 34, 35, 36, 37],
		"hurt": [38, 39, 40, 41, 42, 43, 44], "death": [45, 46, 47, 48, 49, 50]}
	facing = -1.0
	play("idle")
	died.connect(_on_defeated)
	if Game.killed.get(Game.level_index, []).has(name):  # beaten before the cat lost a life: the level removes it, the reward stays out
		_reward.call_deferred()


func _ai(delta: float) -> void:
	var cat := find_cat()
	if cat == null:
		return
	var d := cat.global_position - global_position
	_timer -= delta
	_bite_cd -= delta
	var angry := hp <= max_hp / 2
	if _state != WAIT and _state != SWIM and in_water() and not (_state == LEAP and velocity.y < 0):
		_begin(SWIM)  # knocked into the pool (or landed short): swim, never walk the bed like a bank
	match _state:
		WAIT:
			velocity.x = 0
			if cat.global_position.x > arena_left + 40 and cat.global_position.x < arena_right:
				_start_fight()
		IDLE:
			velocity.x = 0
			face(d.x)
			play("idle")
			if _timer <= 0:
				_begin(_next)
		THROW:
			velocity.x = 0
			play("throw", false)
			var at := (9.0 / anim_fps - _timer) * anim_fps  # frame of the throw animation
			if at >= 5 + _thrown * 1.5 and _thrown < (3 if angry else 1):
				_throw(cat.global_position, _thrown)
				_thrown += 1
			if _timer <= 0:
				_rest(WINDUP)
		WINDUP:
			velocity.x = 0
			play("idle")
			sprite.position.x = sin(_timer * 60.0) * 1.0
			if _timer <= 0:
				sprite.position.x = 0.0
				_begin(CHARGE)
		CHARGE:
			velocity.x = facing * charge_speed * (1.3 if angry else 1.0)
			play("charge")
			hit_cat_in(Rect2(4, -22, 26, 20), charge_damage)
			var x := global_position.x
			if is_on_wall() or (facing < 0 and x < arena_left + 24) or (facing > 0 and x > arena_right - 24):
				Game.sfx("enemy_hit", 0.1, -6.0)
				_begin(DAZED)
				_next = DIVE
			elif not ground_ahead() or _timer <= 0:
				_begin(DIVE)
		DAZED:
			velocity.x = 0
			play("hurt")
			if _timer <= 0:
				_rest(_next)
		TAIL:
			velocity.x = 0
			play("tail", false)
			var at := (9.0 / anim_fps - _timer) * anim_fps
			if at >= 3 and at < 5:
				hit_cat_in(Rect2(-40, -16, 80, 16), 1)  # the slam reaches both sides
			if _timer <= 0:
				_rest(THROW)
		DIVE:  # run off the bank into the pool
			play("run")
			face((pool_left + pool_right) / 2.0 - global_position.x)
			velocity.x = facing * 90.0
			if in_water():
				_begin(SWIM)
		SWIM:
			_swim(cat)
		LEAP:
			play("charge")
			velocity.x = _leap_vx
			hit_cat_in(Rect2(-14, -26, 30, 26), bite_damage)
			if is_on_floor():
				_leaps = 0
				_begin(DAZED)
				_timer = 1.0
				_next = TAIL
			elif (in_water() and velocity.y > 0) or _timer <= 0:
				_leaps += 1
				_begin(SWIM)


func _swim(cat: Node2D) -> void:
	var cat_wet: bool = cat.get("_in_water") == true
	var target := Vector2(clampf(cat.global_position.x, pool_left + 18, pool_right - 18), water_top + 18)
	var speed := 70.0
	if cat_wet:  # a cat in the water is easy prey
		target = cat.global_position + Vector2(0, 6)
		speed = 110.0
		if _bite_cd <= 0 and hit_cat_in(Rect2(-6, -22, 30, 22), bite_damage):
			_bite_cd = 1.0
			play("throw", false)
	velocity = (target - global_position).normalized() * minf(speed, (target - global_position).length() * 4.0)
	face(cat.global_position.x - global_position.x)
	if _bite_cd <= 0.6:
		play("run")
	if _timer <= 0 and not cat_wet:
		_leap(cat)


func _leap(cat: Node2D) -> void:
	var to: Vector2 = cat.global_position
	var over_pool := to.x > pool_left and to.x < pool_right
	if _leaps >= 2 or not over_pool:  # out onto the bank nearest the cat
		var left_bank := to.x < (pool_left + pool_right) / 2.0
		to = Vector2(clampf(to.x, arena_left + 30, pool_left - 20) if left_bank else clampf(to.x, pool_right + 20, arena_right - 30), water_top - 24)
	var t := 0.8
	velocity = Vector2((to.x - global_position.x) / t, (to.y - global_position.y - 0.5 * gravity * t * t) / t)
	_leap_vx = velocity.x
	face(velocity.x)
	_begin(LEAP)


func _begin(state: int) -> void:
	_state = state
	flying = state == SWIM
	sprite.modulate = Color(0.5, 0.65, 0.85, 0.7) if state == SWIM else Color.WHITE  # under the surface
	match state:
		THROW:
			_timer = 9.0 / anim_fps
			_thrown = 0
		WINDUP:
			_timer = 0.5
			face(find_cat().global_position.x - global_position.x)
		CHARGE:
			_timer = 3.0
		DAZED:
			_timer = 1.6
		TAIL:
			_timer = 9.0 / anim_fps
		SWIM:
			_timer = 1.6 if hp <= max_hp / 2 else 2.2
		LEAP:
			_timer = 2.0


func _rest(next: int) -> void:
	_state = IDLE
	_next = next
	_timer = 0.7 if hp <= max_hp / 2 else 1.1


func _throw(target: Vector2, i: int) -> void:
	var stick := Node2D.new()
	stick.set_script(STICK)
	var from := global_position + Vector2(facing * 12, -26)
	var t := 0.9 + i * 0.25  # several branches land spread out around the cat
	var to := target + Vector2((i - 1) * 28 * facing if i > 0 else 0, 0)
	stick.velocity = Vector2((to.x - from.x) / t, (to.y - 8 - from.y - 0.5 * STICK.GRAVITY * t * t) / t)
	get_parent().add_child(stick)
	stick.global_position = from
	Game.sfx("swim", 0.2, -4.0)


func _start_fight() -> void:
	var level := Game.scene()
	_rest(THROW)
	_timer = 1.0
	if level.has_method("enter_room"):
		level.enter_room(Rect2(arena_left, -1000, arena_right - arena_left, 1000 + level._default_bottom))
	for n in level.level_objects():  # the arena's ledges are the cat's refuge: the beaver leaps through them, never lands on one
		if n is StaticBody2D and n.get_script() and n.get_script().resource_path.ends_with("float_platform.gd") \
				and n.global_position.x > arena_left and n.global_position.x < arena_right:
			add_collision_exception_with(n)
	_wall = StaticBody2D.new()  # shuts the way back
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(16, 400)
	_wall.add_child(shape)
	get_parent().add_child(_wall)
	_wall.global_position = Vector2(arena_left - 8, global_position.y - 200)
	_ui = CanvasLayer.new()
	var label := Label.new()
	label.text = tr("BÓBR")
	label.position = Vector2(110, 158)
	label.add_theme_font_size_override("font_size", 8)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = max_hp
	_bar.value = hp
	_bar.position = Vector2(135, 162)
	_bar.size = Vector2(80, 5)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.08, 0.8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.35, 0.15)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	_ui.add_child(label)
	_ui.add_child(_bar)
	add_child(_ui)
	Game.hint.emit("Bóbr broni kładki! Pod wodą jest nietykalny. Nie wpadaj do wody, drap go, gdy jest oszołomiony.")


func hurt(amount: int, from: Vector2, stun := 0.0) -> void:
	if _state == WAIT or _state == SWIM:
		return
	super.hurt(amount, from, stun)
	if _bar:
		_bar.value = hp


func _on_defeated() -> void:
	flying = false
	sprite.modulate = Color.WHITE
	var level := Game.scene()
	if level.has_method("leave_room"):
		level.leave_room()
	if _wall:
		_wall.queue_free()
	if _ui:
		_ui.queue_free()
	Game.hint.emit("Bóbr pokonany! Drabinka prowadzi do legowiska.")
	_reward()


func _reward() -> void:
	for n in get_tree().get_nodes_in_group("boss_reward"):
		n.visible = true
		if n is Area2D:
			n.set_deferred("monitorable", true)
			n.set_deferred("monitoring", true)
