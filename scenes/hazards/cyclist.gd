extends "res://scenes/hazards/hazard.gd"
# Cyclist riding back and forth along a lane `lane` px long to the right of where it is placed, braking into each turn.
# Not killable: an obstacle to jump over (or wait out). Three kinds, set by the scene (bike_city / bike_mtb / bike_road):
#   CITY: slow and steady, a light touch.  MTB: faster, bounces along, a light touch.  ROAD: fast, a heavy hit, whooshes by.
# The numbers of each kind live here, not in the scenes: a value an instance sets to the script's default would be
# dropped when the level is saved.

enum { CITY, MTB, ROAD }
const SPEED := [52.0, 82.0, 150.0]
const FPS := [7.0, 10.0, 15.0]     # pedalling frames per second at full speed
const DAMAGE := [1, 1, 2]
const HOP := 10.0                  # MTB bounce height, px
const HOP_PERIOD := 1.1            # seconds between MTB bounces
const HOP_TIME := 0.42

@export_enum("City", "MTB", "Road") var kind := 0
@export var lane := 192.0
@export var phase := 0.0           # 0..1 along its first lap, so neighbours don't ride in step

var _start := 0.0
var _x := 0.0
var _dir := 1.0
var _t := 0.0
var _pedal := 0.0
var _lift := 0.0
var _sprite_y := 0.0
var _was_fast := false


func _ready() -> void:
	_start = position.x
	_x = phase * lane
	_t = phase * 3.1
	damage = DAMAGE[kind]
	hit_size = Vector2(26, 16)
	_sprite_y = $Sprite.position.y


func _move(delta: float) -> void:
	_t += delta
	var ease_ := clampf(minf(_x, lane - _x) / 24.0, 0.35, 1.0)   # brakes into the turn, speeds up out of it
	_x += _dir * SPEED[kind] * ease_ * delta
	if _x >= lane:
		_x = lane
		_dir = -1.0
	elif _x <= 0.0:
		_x = 0.0
		_dir = 1.0
	position.x = _start + _x
	_pedal += delta * FPS[kind] * ease_
	$Sprite.frame = int(_pedal) % 8
	$Sprite.flip_h = _dir < 0
	_lift = 0.0
	if kind == MTB:
		var c := fmod(_t, HOP_PERIOD)
		if c < HOP_TIME:
			var u := c / HOP_TIME
			_lift = HOP * 4.0 * u * (1.0 - u)
	$Sprite.position.y = _sprite_y - _lift
	hit_offset = Vector2(0, -hit_size.y / 2 - _lift)
	var fast := ease_ > 0.9
	if kind == ROAD and fast and not _was_fast:   # a road bike sets off again: whoosh, if the cat is near
		var cat := get_tree().get_first_node_in_group("player")
		if cat and absf(cat.global_position.x - global_position.x) < 240:
			Game.sfx("dash", 0.1, -8.0)
	_was_fast = fast
