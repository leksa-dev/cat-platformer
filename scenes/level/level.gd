extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var cat: CharacterBody2D = $Cat

@export var background_scroll := 0.2  # background moves slower than the level -> depth
@export var music := "forest"  # assets/game/audio/music_<name>.wav

var _death_y := 0.0
var _bg_time := 0.0
var _bg_base_y := 0.0  # camera centre y with the cat on the ground (bottom limit): vertical parallax is measured from it
var _cam: Camera2D


func _ready() -> void:
	# Camera bounds and the death line come from the painted tiles, so repainting the level needs no config.
	var rect := ground.get_used_rect()
	var tile := ground.tile_set.tile_size
	var cam: Camera2D = cat.get_node("Camera2D")
	_cam = cam
	cam.limit_left = rect.position.x * tile.x
	cam.limit_right = rect.end.x * tile.x
	# no top limit: the sky is open, and the cat can climb/jump above the highest tile
	cam.limit_bottom = rect.end.y * tile.y
	_death_y = cam.limit_bottom + 32
	_add_edge_walls(cam.limit_left, cam.limit_right)
	_bg_base_y = cam.limit_bottom - get_viewport().get_visible_rect().size.y / 2
	for layer in $Background.get_children():
		layer.set_meta("y0", layer.position.y)
	cat.position = $Spawn.position if Game.checkpoint == Vector2.INF else Game.checkpoint
	Game.play_music(music)
	cam.reset_smoothing()  # otherwise the camera glides in from the map origin after every respawn


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
	var center := _cam.get_screen_center_position()
	_bg_time += delta
	# parallax: each background sprite scrolls at its own rate (metadata "scroll"), clouds may also "drift" on their own
	for layer in $Background.get_children():
		if layer is Sprite2D:
			layer.region_rect.position.x = center.x * layer.get_meta("scroll", background_scroll) + _bg_time * layer.get_meta("drift", 0.0)
			# vertical: "vscroll" 1 = stays on the world's horizon when the camera climbs (islands), 0 = fixed on screen (sky)
			layer.position.y = layer.get_meta("y0") - (center.y - _bg_base_y) * layer.get_meta("vscroll", 0.0)
	$Leaves.position = center + Vector2(40, -100)  # emit above the screen, drift left-down


func _physics_process(_delta: float) -> void:
	if cat.position.y > _death_y and not Game.fly_mode:
		if Game.god_mode:
			cat.position = $Spawn.position if Game.checkpoint == Vector2.INF else Game.checkpoint
			cat.velocity = Vector2.ZERO
			return
		set_physics_process(false)
		Game.lose_life()
