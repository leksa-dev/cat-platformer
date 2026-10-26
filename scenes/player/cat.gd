extends CharacterBody2D

signal hit(body: Node2D)  # a scratch connected; nothing listens until enemies exist

@export var run_speed := 90.0
@export var acceleration := 900.0
@export var friction := 1100.0
@export var jump_velocity := -230.0
@export var gravity := 700.0
@export var fall_gravity_mult := 1.6
@export var jump_cut_mult := 0.4  # releasing jump early cuts upward speed -> variable jump height
@export var max_fall_speed := 300.0
@export var coyote_time := 0.1
@export var jump_buffer := 0.1
@export var wall_slide_speed := 50.0
@export var wall_jump_push := 140.0
@export var wall_jump_lock := 0.15  # ignore left/right briefly so the cat actually leaves the wall
@export var climb_speed := 50.0
@export var regrab_delay := 0.3  # seconds before the cat can grab the tree it just jumped/dashed off
@export var climb_top_hop := 0.6  # fraction of jump_velocity when climbing off the top
@export var dash_speed := 220.0
@export var dash_time := 0.15
@export var dash_cooldown := 0.3
@export var catnip_time := 4.0
@export var catnip_speed_mult := 1.6
@export var catnip_jump_mult := 1.1
@export var scratch_interval := 0.12  # holding attack = one swipe per interval
@export var scratch_lunge := 40.0
@export var fart_cloud_speed := 70.0
@export var max_hp := 6
@export var hurt_invuln_time := 1.0
@export var hurt_knockback := Vector2(120, -150)
@export var scratch_damage := 1
@export var surf_speed := 110.0  # top speed on the board, either way
@export var surf_accel := 300.0
@export var surf_drift := 25.0  # with no input the wave drifts the cat gently right
@export var surf_jump_mult := 0.65  # lower jumps from the board (~1 tile)
@export var water_speed_mult := 0.5
@export var water_gravity_mult := 0.25
@export var water_max_fall := 40.0
@export var swim_stroke := -110.0  # jump in water: one paddle upward, repeatable
@export var swim_speed := 45.0  # up/down held in water
@export var water_exit_hop := 0.8  # fraction of jump_velocity when breaking the surface upward, to climb out

var _coyote := 0.0
var _buffer := 0.0
var _lock := 0.0
var _anim_time := 0.0
var _climbing := false
var _top_hopped := false  # no re-grab after hopping off the top until "up" is released, or it loops
var _released := []  # climbables jumped/dashed off: no re-grab until regrab_delay passes, the cat lands/swims or leaves them
var _released_time := 0.0
var _dash_left := -1.0  # > 0 while dashing, then counts down through the cooldown
var _can_dash := true  # one dash per air time; refilled on floor, wall or climbable
var _catnip_left := 0.0
var _scratch_cd := 0.0
var _shake := 0.0
var _fart_time := -1.0  # seconds into the fart attack, < 0 when not farting
var _farted := false  # cloud already released this attack
var _in_water := false
var hp := 0
var fall_speed := 0.0  # vertical speed before the last move (landing zeroes velocity; enemies need it for stomps)
var _hurt_invuln := 0.0
var _dying := false
var _fart_dir := 1.0  # facing when the attack started: the target side
var _surfing := false
var _surf_air := false
var _surf_time := 0.0
var _drink_time := -1.0  # seconds into the drink at the bar, < 0 when not drinking
var _drank := false
var _land_time := 1.0  # since touching the ground
var _turn_time := 1.0  # since turning around on the ground
var _idle_time := 0.0
var _hurt_time := 1.0
var _die_time := 0.0
var _was_on_floor := true
var _climb_time := 0.0  # since grabbing the climbable
var _jump_off_time := 1.0  # since leaping off a climbable
var _climb_fall := false  # slid off the end of a climbable: falling pose until landing
var _scratch_time := 1.0  # since the flurry started

# frames in cat.png (cut from assets/new_cat.png): first frame, count, fps
const ANIMS := {"idle": [0, 4, 5.0], "yarn": [5, 6, 6.0], "walk": [11, 8, 12.0], "run": [19, 8, 14.0],
	"fall": [33, 4, 10.0], "land": [37, 4, 20.0], "hurt": [58, 4, 10.0],
	# from assets/cat_scratch_climb.png
	"climb_up": [82, 8, 12.0], "climb_down": [90, 8, 12.0], "climb_idle": [98, 4, 5.0], "fall_climb": [115, 4, 10.0]}
const SCRATCH_GROUND := 68  # 8 frames: ready, wind-up, 4 swipes, recover x2
const SCRATCH_AIR := 76  # 6 frames: ready, wind-up, 3 swipes, recover
const REACH_UP := 102  # 4 frames grabbing a climbable, then REACH_DOWN (4) when grabbing it going down
const JUMP_OFF := 110  # 5 frames leaping off a climbable, to the right
const JUMP := 27  # 6 frames: crouch, take-off, rising, apex, descending, touch-down
const DASH := [41, 5]
const WALL := 53  # cat against a post on its right
const DEAD := [62, 4, 5.0]
const TURN := 66  # 2 frames
const YARN_AFTER := 6.0  # seconds standing still before the cat plays with its yarn
const DIE_TIME := 1.0  # death animation before the life is lost
# fart attack: [sheet frame, duration in 1/30 s, faces away from the target?]
# ready -> back view, shaking -> butt pose with the spark (butt to the target) -> recover
const FART_SEQ := [[46, 2, false], [47, 3, false], [48, 3, false], [49, 4, false], [50, 6, true], [51, 3, false], [52, 3, false]]
const FART_RELEASE := 9  # 1/30 s ticks in: the squint frame, when the cloud comes out
const FART_CLOUD := preload("res://scenes/objects/fart_cloud.tscn")
# sprite sheets: [texture, frames, sprite y so the feet stay on the ground]
const SHEET_CAT := [preload("res://assets/game/cat.png"), 119, -70.0 / 6]
const SHEET_SURF := [preload("res://assets/game/beach/cat_surf.png"), 6, -8.0]  # idle, get on, surf 1-2, jump, land
const SHEET_DRINK := [preload("res://assets/game/beach/cat_drink.png"), 6, -40.0 / 6]  # stand, coconut, sip x2, put down, happy (healed)
const DRINK_FPS := 6.0

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var claws: Node2D = $Visual/Claws
@onready var hitbox: Area2D = $Visual/Claws/Hitbox
@onready var hitbox_shape: CollisionShape2D = $Visual/Claws/Hitbox/CollisionShape2D
@onready var cam: Camera2D = $Camera2D
@onready var climb_sensor: Area2D = $ClimbSensor
@onready var water_sensor: Area2D = $WaterSensor
@onready var surf_sensor: Area2D = $SurfSensor

const CROWN_LAYER := 3  # tree crowns: one-way platforms the cat must pass through while climbing


func _ready() -> void:
	hp = max_hp
	Game.hp_changed.emit.call_deferred(hp, max_hp)  # deferred: the HUD is ready after the cat


func take_damage(amount: int, from: Vector2) -> void:
	if _hurt_invuln > 0 or _dying or Game.god_mode:
		return
	hp = maxi(hp - amount, 0)
	Game.hp_changed.emit(hp, max_hp)
	Game.sfx("hurt")
	_hurt_invuln = hurt_invuln_time
	_climbing = false
	_fart_time = -1.0
	_dash_left = minf(_dash_left, 0.0)
	velocity = Vector2(signf(global_position.x - from.x) * hurt_knockback.x, hurt_knockback.y)
	_lock = 0.25  # knocked back: no steering for a moment
	if _surfing:
		_surf_air = true  # knocked up off the wave, lands back on the board
	_shake = 0.2
	_hurt_time = 0.0
	if hp <= 0:
		_die()


func sting(amount: int) -> void:  # toxic sludge: hurts without knockback, the invulnerability paces it
	if _hurt_invuln > 0 or _dying or Game.god_mode:
		return
	hp = maxi(hp - amount, 0)
	Game.hp_changed.emit(hp, max_hp)
	Game.sfx("hurt", 0.06, -6.0)
	_hurt_invuln = hurt_invuln_time
	_hurt_time = 0.0
	if hp <= 0:
		_die()


func _die() -> void:  # the death animation plays, then the life goes
	_dying = true
	_die_time = 0.0
	_climbing = false
	_fart_time = -1.0
	_drink_time = -1.0
	_set_sheet(SHEET_CAT)


func bounce() -> void:  # after stomping an enemy
	velocity.y = jump_velocity * 0.8
	_can_dash = true


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	Game.sfx("heal", 0.0)
	Game.hp_changed.emit(hp, max_hp)


func drink() -> void:  # at the beach bar: sit, drink, full HP
	if _drink_time >= 0 or _surfing:
		return
	_drink_time = 0.0
	_drank = false
	Game.sfx("drink", 0.0)
	_climbing = false
	_fart_time = -1.0
	_set_sheet(SHEET_DRINK)


func _set_sheet(sheet: Array) -> void:
	sprite.texture = sheet[0]
	sprite.hframes = sheet[1]
	sprite.position.y = sheet[2]
	sprite.frame = 0


func eat_catnip() -> void:
	_catnip_left = catnip_time  # eating again refreshes, doesn't stack
	Game.sfx("catnip", 0.0)


func _physics_process(delta: float) -> void:
	$CollisionShape2D.disabled = Game.fly_mode
	if Game.fly_mode:  # dev: noclip flight, Shift = faster
		var dir := Input.get_vector("left", "right", "up", "down")
		velocity = dir * (320.0 if Input.is_action_pressed("dash") else 140.0)
		global_position += velocity * delta
		if dir.x:
			visual.scale.x = signf(dir.x)
		sprite.frame = JUMP + 2
		return
	if _dying:
		_die_time += delta
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		move_and_slide()
		sprite.frame = DEAD[0] + mini(int(_die_time * DEAD[2]), DEAD[1] - 1)
		if _die_time >= DIE_TIME and _die_time - delta < DIE_TIME:
			Game.lose_life()
		return
	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_buffer = jump_buffer if Input.is_action_just_pressed("jump") else _buffer - delta
	_update_effects(delta)
	_dash_left -= delta  # ticks while climbing too, or tree-to-tree dashes stay on cooldown
	if _drink_time >= 0:
		_update_drink(delta)
		return
	var waves := surf_sensor.get_overlapping_areas()
	if not waves.is_empty():
		_surf(delta, waves[0])
		return
	if _surfing:  # reached the shore
		_surfing = false
		_set_sheet(SHEET_CAT)

	var v_in := Input.get_axis("up", "down")
	# climbables the cat just jumped/dashed off can't be re-grabbed until it has left them; others can
	var areas := climb_sensor.get_overlapping_areas()
	_released_time += delta
	if _released_time >= regrab_delay or is_on_floor() or water_sensor.has_overlapping_areas():
		_released.clear()
	_released = _released.filter(func(a): return areas.has(a))
	var can_climb := areas.any(func(a): return not _released.has(a))
	if v_in >= 0:
		_top_hopped = false
	# "down" only grabs in the air or on a crown; on the ground it would re-grab every frame and pin the cat
	var grab := v_in < 0 or (v_in > 0 and (not is_on_floor() or _on_crown()))
	if not _climbing and can_climb and grab and not _top_hopped and _fart_time < 0:
		_climbing = true
		_climb_time = 0.0
		_climb_fall = false
	if _climbing:
		_can_dash = true
		if not can_climb:  # climbed past an end
			_climbing = false
			_climb_fall = v_in >= 0  # off the bottom of a vine: fall pose
			_climb_time = 0.0
			if v_in < 0:
				velocity.y = jump_velocity * climb_top_hop
				_top_hopped = true
		elif _buffer > 0:
			_climbing = false  # jump off; the normal jump code below sees the buffer, coyote lets it fire
			_coyote = coyote_time
			_jump_off_time = 0.0
			_released = areas
			_released_time = 0.0
		elif Input.is_action_just_pressed("dash"):
			_climbing = false  # dash off the tree; the dash code below fires it
			_released = areas
			_released_time = 0.0
		else:
			set_collision_mask_value(CROWN_LAYER, false)
			velocity = Vector2(0, v_in * climb_speed)  # ladder-style: no sideways drift off a narrow vine
			for a in areas:
				if a.is_in_group("ladder"):  # ladders: climb the rungs in the middle, not an edge
					velocity.x = clampf((a.global_position.x - global_position.x) / delta, -120.0, 120.0)
			fall_speed = velocity.y
			move_and_slide()
			if is_on_floor() and (v_in > 0 or Input.get_axis("left", "right")):
				_climbing = false  # reached the ground: walk off
			_anim_time += delta
			_climb_time += delta
			if _climb_time < 0.2:  # reaching for the trunk
				sprite.frame = (REACH_UP if v_in <= 0 else REACH_UP + 4) + int(_climb_time * 20)
			else:
				_play("climb_up" if velocity.y < 0 else "climb_down" if velocity.y > 0 else "climb_idle")
			return
	set_collision_mask_value(CROWN_LAYER, true)

	var was_in_water := _in_water
	_in_water = water_sensor.has_overlapping_areas()
	if _in_water and not was_in_water:
		Game.sfx("splash")
	if was_in_water and not _in_water and velocity.y < 0:
		velocity.y = minf(velocity.y, jump_velocity * water_exit_hop)  # pop out onto the bank

	if is_on_floor() or is_on_wall():
		_can_dash = true
	if Input.is_action_just_pressed("dash") and _can_dash and _dash_left <= -dash_cooldown and _fart_time < 0 and not _in_water:
		_can_dash = false
		_dash_left = dash_time
		Game.sfx("dash")
		var dash_dir := Input.get_axis("left", "right")
		if dash_dir:
			visual.scale.x = signf(dash_dir)
	if _dash_left > 0:
		velocity = Vector2(visual.scale.x * dash_speed, 0)  # no gravity mid-dash
		fall_speed = velocity.y
		move_and_slide()
		sprite.frame = DASH[0] + clampi(int((1.0 - _dash_left / dash_time) * DASH[1]), 0, DASH[1] - 1)
		_spawn_ghost()
		return

	var g := gravity * (fall_gravity_mult if velocity.y > 0 else 1.0)
	if _in_water:
		g *= water_gravity_mult
	velocity.y = minf(velocity.y + g * delta, water_max_fall if _in_water else max_fall_speed)
	if _in_water and v_in:
		velocity.y = move_toward(velocity.y, v_in * swim_speed, 300.0 * delta)

	var on_wall := is_on_wall_only() and not _in_water
	if on_wall and velocity.y > 0:
		velocity.y = minf(velocity.y, wall_slide_speed)

	if _fart_time >= 0:
		pass  # committed to the fart: no jumping
	elif _in_water and _buffer > 0:
		velocity.y = swim_stroke
		_buffer = 0
		Game.sfx("swim")
	elif _buffer > 0 and _coyote > 0:
		velocity.y = jump_velocity * _boost(catnip_jump_mult)
		Game.sfx("jump")
		_buffer = 0
		_coyote = 0
	elif _buffer > 0 and on_wall:
		velocity = Vector2(get_wall_normal().x * wall_jump_push, jump_velocity)
		Game.sfx("jump", 0.06, -2.0)
		_buffer = 0
		_lock = wall_jump_lock
		visual.scale.x = get_wall_normal().x
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_mult

	if Input.is_action_just_pressed("fart") and _fart_time < 0 and is_on_floor():
		_fart_time = 0.0
		_farted = false
		_fart_dir = visual.scale.x

	_lock -= delta
	if _lock <= 0:
		var dir := Input.get_axis("left", "right") if _fart_time < 0 else 0.0
		if dir:
			velocity.x = move_toward(velocity.x, dir * run_speed * _boost(catnip_speed_mult) * (water_speed_mult if _in_water else 1.0), acceleration * delta)
			if signf(dir) != visual.scale.x and is_on_floor():
				_turn_time = 0.0
			visual.scale.x = signf(dir)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	if Input.is_action_pressed("attack") and _scratch_cd <= 0 and _fart_time < 0:
		_scratch()
	if _fart_time >= 0:
		_update_fart(delta)

	fall_speed = velocity.y
	move_and_slide()
	_animate(delta, on_wall and velocity.y > 0)


func _surf(delta: float, wave: Area2D) -> void:
	if not _surfing:
		_surfing = true
		_surf_air = false
		Game.sfx("splash")
		_surf_time = 0.0
		_climbing = false
		_fart_time = -1.0
		_set_sheet(SHEET_SURF)
	_surf_time += delta
	var surface := wave.global_position.y - 1  # 1 px above the shore's top edge, or the board snags on its corner
	var dir := Input.get_axis("left", "right")
	velocity.x = move_toward(velocity.x, dir * surf_speed if dir else surf_drift, surf_accel * delta)
	if dir:
		visual.scale.x = signf(dir)
	if _surf_air:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= jump_cut_mult
		if velocity.y > 0 and global_position.y + velocity.y * delta >= surface:
			_surf_air = false
			velocity.y = 0
			global_position.y = surface
	else:
		velocity.y = 0
		global_position.y = surface  # riding the surface
		if _buffer > 0:
			_buffer = 0
			_surf_air = true
			velocity.y = jump_velocity * surf_jump_mult
			Game.sfx("jump", 0.06, -3.0)
	fall_speed = velocity.y
	move_and_slide()
	sprite.frame = 4 if _surf_air else (1 if _surf_time < 0.25 else 2 + int(_surf_time * 6) % 2)


func _update_drink(delta: float) -> void:
	_drink_time += delta
	velocity.x = 0
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	fall_speed = velocity.y
	move_and_slide()
	var frame := int(_drink_time * DRINK_FPS)
	if frame >= 5 and not _drank:  # the happy frame
		_drank = true
		heal(max_hp)
	if frame >= 6 + 2:  # hold the happy pose a moment
		_drink_time = -1.0
		_set_sheet(SHEET_CAT)
		return
	sprite.frame = mini(frame, 5)


func _on_crown() -> bool:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is CollisionObject2D and collider.get_collision_layer_value(CROWN_LAYER):
			return true
	return false


func _update_fart(delta: float) -> void:
	_fart_time += delta
	var tick := _fart_time * 30.0
	if not _farted and tick >= FART_RELEASE:
		_farted = true
		Game.sfx("fart", 0.1)
		var cloud := FART_CLOUD.instantiate()
		cloud.velocity = Vector2(_fart_dir * fart_cloud_speed, 0)  # the cat has turned: its butt points at the target
		get_parent().add_child(cloud)
		cloud.global_position = global_position + Vector2(_fart_dir * 8, -6)
		cloud.hit.connect(hit.emit)
		_shake = 0.15
	var t := 0
	for step in FART_SEQ:
		t += step[1]
		if tick < t:
			sprite.frame = step[0]
			visual.scale.x = -_fart_dir if step[2] else _fart_dir
			return
	visual.scale.x = _fart_dir
	_fart_time = -1.0  # sequence over


func _boost(mult: float) -> float:
	return mult if _catnip_left > 0 else 1.0


func _scratch() -> void:
	if _scratch_cd < -0.1:  # a new flurry, not the next swipe of a held one
		_scratch_time = 0.0
	_scratch_cd = scratch_interval
	Game.sfx("scratch", 0.15, -3.0)
	claws.scale.y = -claws.scale.y  # alternate paws
	_shake = 0.08
	if is_on_floor():
		velocity.x += visual.scale.x * scratch_lunge
	# query the claw shape directly: Area2D overlap lists lag and missed freshly placed bodies in tests
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox_shape.shape
	query.transform = hitbox_shape.global_transform
	query.collision_mask = hitbox.collision_mask
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		if result.collider.has_method("hurt"):
			result.collider.hurt(scratch_damage, global_position)
		hit.emit(result.collider)


func _update_effects(delta: float) -> void:
	_catnip_left -= delta
	if _catnip_left > 0:
		# green pulse, faster in the last second as a warning
		var hz := 3.0 if _catnip_left > 1.0 else 10.0
		sprite.modulate = Color.WHITE.lerp(Color(0.85, 1.25, 0.85), 0.5 + 0.5 * sin(_catnip_left * hz * TAU))
	else:
		sprite.modulate = Color.WHITE
	_hurt_invuln -= delta
	visual.visible = _hurt_invuln <= 0 or int(_hurt_invuln * 15) % 2 == 0  # blink while invulnerable
	_scratch_cd -= delta
	claws.visible = _scratch_cd > scratch_interval * 0.5
	_shake -= delta
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) if _shake > 0 else Vector2.ZERO


func _spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.modulate = Color(1, 0.8, 0.5, 0.5)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	ghost.global_transform = sprite.global_transform
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)


func _animate(delta: float, sliding: bool) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_land_time = 0.0
	_was_on_floor = on_floor
	_land_time += delta
	_turn_time += delta
	_hurt_time += delta
	_jump_off_time += delta
	_scratch_time += delta
	_anim_time += delta
	if on_floor:
		_climb_fall = false
	_idle_time = _idle_time + delta if on_floor and absf(velocity.x) <= 5 and _fart_time < 0 else 0.0
	if _fart_time >= 0:
		return  # _update_fart drives the frames
	if _hurt_time < 0.4:
		_play("hurt")
	elif _scratch_cd > -0.1:  # wind-up once, then swipes while the attack is held
		var first := SCRATCH_GROUND if on_floor else SCRATCH_AIR
		var swipes := 4 if on_floor else 3
		sprite.frame = first + 1 if _scratch_time < 0.05 else first + 2 + int(_scratch_time * 30) % swipes
	elif _in_water and not on_floor:
		_play("walk", 0.5)  # paddling
	elif sliding:
		visual.scale.x = -get_wall_normal().x  # the wall frame has the post on the cat's right
		sprite.frame = WALL
	elif not on_floor and _jump_off_time < 0.35:
		sprite.frame = JUMP_OFF + mini(int(_jump_off_time * 14), 4)
	elif not on_floor and _climb_fall:
		_climb_time += delta
		sprite.frame = ANIMS["fall_climb"][0] + mini(int(_climb_time * 10), 3)
	elif not on_floor:
		# jump frames picked by vertical speed: take-off, rising, apex, then the falling loop
		if velocity.y < 100:
			sprite.frame = JUMP + (1 if velocity.y < -100 else 2 if velocity.y < 0 else 3)
		else:
			_play("fall")
	elif _turn_time < 0.12:
		sprite.frame = TURN + int(_turn_time / 0.06)
	elif absf(velocity.x) > 5:
		_play("run" if absf(velocity.x) > run_speed * 0.7 else "walk")
	elif _land_time < 0.2:
		sprite.frame = ANIMS["land"][0] + mini(int(_land_time * ANIMS["land"][2]), 3)
	elif _idle_time > YARN_AFTER + 0.3:
		_play("yarn")  # loops the playing frames
	elif _idle_time > YARN_AFTER:
		sprite.frame = ANIMS["yarn"][0] - 1  # lies down once
	else:
		_play("idle")


func _play(anim: String, speed := 1.0) -> void:
	var a: Array = ANIMS[anim]
	sprite.frame = a[0] + int(_anim_time * a[2] * speed) % a[1]
