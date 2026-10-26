@tool
extends Node2D
# Pipe the cat can crawl through: open ends on both sides, bottom-left at the node. Walking into an end (or
# pressing down at it) sends the cat through, hidden, with the camera gliding along, and pops it out of the other end.

const MOUTH := 21.0  # logical width of an open end
@export var width_tiles := 20:
	set(value):
		width_tiles = maxi(value, 4)
		_build()
@export var speed := 240.0

var _busy := false
var _push := 0.0  # how long the cat has been walking into an end


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	var w := width_tiles * 16.0
	$Run.position = Vector2(MOUTH - 2, 0)
	$Run.region_rect = Rect2(0, 0, (w - 2 * MOUTH + 4) * 3, 47)
	$Left.position = Vector2(0, 0)
	$Right.position = Vector2(w - MOUTH, 0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _busy:
		return
	var cat := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if cat == null or not cat.visible or not cat.is_on_floor():
		_push = 0.0
		return
	var w := width_tiles * 16.0
	var local := cat.global_position - global_position
	if absf(local.y) > 4:
		_push = 0.0
		return
	var side := 0  # -1: at the left end, 1: at the right end
	if local.x > -14 and local.x < MOUTH + 2:
		side = -1
	elif local.x > w - MOUTH - 2 and local.x < w + 14:
		side = 1
	if side == 0:
		_push = 0.0
		return
	var into := Input.get_axis("left", "right") == -side  # walking toward the pipe's inside
	_push = _push + delta if into else 0.0
	if _push > 0.15 or Input.is_action_just_pressed("down"):
		_push = 0.0
		_travel(cat, side)


func _travel(cat: CharacterBody2D, side: int) -> void:
	_busy = true
	var w := width_tiles * 16.0
	var y := global_position.y - 6
	var out_x: float = global_position.x + (w + 6 if side == -1 else -6)
	Game.sfx("splash", 0.0)
	cat.visible = false
	cat.set_physics_process(false)
	cat.velocity = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(cat, "global_position", Vector2(global_position.x + (MOUTH if side == -1 else w - MOUTH), y), 0.12)
	tween.tween_property(cat, "global_position", Vector2(out_x, y), (w - MOUTH) / speed)
	await tween.finished
	cat.global_position = Vector2(out_x, global_position.y)
	cat.visible = true
	cat.set_physics_process(true)
	cat.velocity = Vector2(-side * 60.0, cat.jump_velocity * 0.5)  # tumbles out of the far end
	Game.sfx("jump", 0.0)
	await get_tree().create_timer(0.4).timeout  # don't get sucked straight back in
	_busy = false
