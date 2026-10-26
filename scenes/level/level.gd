extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var cat: CharacterBody2D = $Cat

@export var background_scroll := 0.2  # background moves slower than the level -> depth
@export var music := "forest"  # assets/game/audio/music_<name>.wav
@export var backdrop: Texture2D  # dark earth tiled below backdrop_top, so pits don't show the sky/forest layers
@export var backdrop_top := 236.0

var _death_y := 0.0
var _bg_time := 0.0
var _bg_base_y := 0.0  # camera centre y with the cat on the ground (bottom limit): vertical parallax is measured from it
var _cam: Camera2D


func _ready() -> void:
	# Camera bounds and the death line come from the painted tiles, so repainting the level needs no config.
	var rect := ground.get_used_rect()
	var tile := Vector2(ground.tile_set.tile_size) * ground.scale  # tiles are 48 px textures drawn at 1/3
	var cam: Camera2D = cat.get_node("Camera2D")
	_cam = cam
	cam.limit_left = int(rect.position.x * tile.x)
	cam.limit_right = int(rect.end.x * tile.x)
	# no top limit: the sky is open, and the cat can climb/jump above the highest tile
	cam.limit_bottom = int(rect.end.y * tile.y)
	_death_y = cam.limit_bottom + 32
	_add_edge_walls(cam.limit_left, cam.limit_right)
	if backdrop:
		_add_backdrop(cam.limit_left, cam.limit_right, _death_y)
	_bg_base_y = cam.limit_bottom - get_viewport().get_visible_rect().size.y / 2
	for layer in $Background.get_children():
		layer.set_meta("y0", layer.position.y)
	cat.position = $Spawn.position if Game.checkpoint == Vector2.INF else Game.checkpoint
	Game.play_music(music)
	var count := 0
	for n in get_children():
		if n is Enemy:
			count += 1
			n.died.connect(Game.enemy_killed.bind(n.name))
	Game.enemies[Game.level_index] = count
	cam.reset_smoothing()  # otherwise the camera glides in from the map origin after every respawn


func _add_backdrop(left: float, right: float, bottom: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = backdrop
	sprite.centered = false
	sprite.scale = Vector2.ONE / 3  # 48 px tile texture drawn at 16
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, (right - left) * 3, (bottom - backdrop_top) * 3)
	sprite.position = Vector2(left, backdrop_top)
	add_child(sprite)
	move_child(sprite, ground.get_index())  # behind the tiles, in front of the parallax layers


# invisible walls at the map's left/right edges, so the cat can't walk or swim off the map
func _add_edge_walls(left: float, right: float) -> void:
	var walls := StaticBody2D.new()
	for side in [[Vector2.RIGHT, left], [Vector2.LEFT, right]]:
		var boundary := WorldBoundaryShape2D.new()
		boundary.normal = side[0]  # solid behind the normal
		var shape := CollisionShape2D.new()
		shape.shape = boundary
		shape.position.x = side[1]
		walls.add_child(shape)
	add_child(walls)


func _process(delta: float) -> void:
	Game.run_time += delta  # the level doesn't process while paused
	var center := _cam.get_screen_center_position()
	_bg_time += delta
	# parallax: each background sprite scrolls at its own rate (metadata "scroll"), clouds may also "drift" on their own
	for layer in $Background.get_children():
		if layer is Sprite2D:
			# region is in texture px: hi-res layers drawn scaled down move proportionally more texture per logical px
			layer.region_rect.position.x = (center.x * layer.get_meta("scroll", background_scroll) + _bg_time * layer.get_meta("drift", 0.0)) / layer.scale.x
			# vertical: "vscroll" 1 = stays on the world's horizon when the camera climbs (islands), 0 = fixed on screen (sky)
			layer.position.y = layer.get_meta("y0") - (center.y - _bg_base_y) * layer.get_meta("vscroll", 0.0)
	if has_node("Leaves"):
		$Leaves.position = center + Vector2(40, -100)  # emit above the screen, drift left-down


# secret rooms sit far above the level: the camera is boxed into the room while the cat is in it
var _limits := []
var in_room := false


func enter_room(room: Rect2) -> void:
	if not in_room:
		_limits = [_cam.limit_left, _cam.limit_top, _cam.limit_right, _cam.limit_bottom]
	in_room = true
	_cam.limit_left = int(room.position.x)
	_cam.limit_top = int(room.position.y)
	_cam.limit_right = int(room.end.x)
	_cam.limit_bottom = int(room.end.y)
	_cam.reset_smoothing.call_deferred()


func leave_room() -> void:
	if in_room:
		in_room = false
		_cam.limit_left = _limits[0]
		_cam.limit_top = _limits[1]
		_cam.limit_right = _limits[2]
		_cam.limit_bottom = _limits[3]
	_cam.reset_smoothing.call_deferred()


func _physics_process(_delta: float) -> void:
	if cat.position.y > _death_y and not Game.fly_mode:
		if Game.god_mode:
			cat.position = $Spawn.position if Game.checkpoint == Vector2.INF else Game.checkpoint
			cat.velocity = Vector2.ZERO
			return
		set_physics_process(false)
		Game.hurt_taken(cat.hp)  # a fall costs the rest of the bar
		Game.lose_life()
