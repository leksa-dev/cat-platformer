extends "res://scenes/enemies/enemy.gd"
# Beaver boss at the end of level 4: waits in its arena; once the cat walks in, the camera locks to the arena, a wall shuts
# the way back and a boss HP bar shows. Cycles: throws a branch in an arc at the cat -> paws the ground and charges across
# the arena (dazed against the wall, an opening to scratch it) -> tail slam that hurts close by. Below half HP it throws
# three branches and charges faster. Beaten, the camera and wall free up and the nodes in group "boss_reward" appear.

const STICK := preload("res://scenes/enemies/beaver/stick.gd")

@export var arena_left := 0.0
@export var arena_right := 0.0
@export var charge_speed := 150.0
@export var charge_damage := 2

enum { WAIT, IDLE, THROW, WINDUP, CHARGE, DAZED, TAIL }
var _state := WAIT
var _timer := 0.0
var _next := THROW
var _thrown := 0
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
	var angry := hp <= max_hp / 2
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
				_state = _next
				_timer = 9.0 / anim_fps
				_thrown = 0
				if _state == WINDUP:
					_timer = 0.5
				play("throw" if _state == THROW else "tail" if _state == TAIL else "idle", false)
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
			face(d.x)
			sprite.position.x = sin(_timer * 60.0) * 1.0
			if _timer <= 0:
				sprite.position.x = 0.0
				_state = CHARGE
				_timer = 3.0
				play("charge")
				anim_fps = 14.0
		CHARGE:
			velocity.x = facing * charge_speed * (1.3 if angry else 1.0)
			play("charge")
			hit_cat_in(Rect2(4, -22, 26, 20), charge_damage)
			var x := global_position.x
			if is_on_wall() or _timer <= 0 or (facing < 0 and x < arena_left + 24) or (facing > 0 and x > arena_right - 24):
				anim_fps = 8.0
				Game.sfx("enemy_hit", 0.1, -6.0)
				_state = DAZED
				_timer = 1.6
				play("hurt")
		DAZED:
			velocity.x = 0
			play("hurt")
			if _timer <= 0:
				_rest(TAIL)
		TAIL:
			velocity.x = 0
			play("tail", false)
			var at := (9.0 / anim_fps - _timer) * anim_fps
			if at >= 3 and at < 5:
				hit_cat_in(Rect2(-40, -16, 80, 16), 1)  # the slam reaches both sides
			if _timer <= 0:
				_rest(THROW)


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
	var level := get_tree().current_scene
	_state = IDLE
	_next = THROW
	_timer = 1.0
	if level.has_method("enter_room"):
		level.enter_room(Rect2(arena_left, -1000, arena_right - arena_left, 1000 + level._default_bottom))
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
	Game.hint.emit("Bóbr broni kładki! Uważaj na gałęzie i szarżę, drap go, gdy jest oszołomiony.")


func hurt(amount: int, from: Vector2, stun := 0.0) -> void:
	if _state == WAIT:
		return
	super.hurt(amount, from, stun)
	if _bar:
		_bar.value = hp


func _on_defeated() -> void:
	var level := get_tree().current_scene
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
