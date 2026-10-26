extends Node2D
# Hangs in a palm. When the cat walks underneath it shakes and falls. Hitting the cat it breaks on its head
# and is gone; dodged, it breaks on the ground and the half stays there as a snack that heals a bit.

enum { HANG, SHAKE, FALL, BREAK, ITEM }

# coconut.png (from assets/new_coconut.png): 0 hanging, 1-2 falling, 3-6 impact, 7-14 cracking open, 14 = drink with a straw
const IMPACT := 3
const CRACK := 7
const ITEM_FRAME := 14
const BREAK_FPS := 20.0

@export var damage := 1
@export var heal := 1
@export var trigger_range := 14.0
@export var gravity := 500.0

var _state := HANG
var _t := 0.0
var _vy := 0.0
var _hit_cat := false

@onready var sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	_t += delta
	var cat: Node2D = get_tree().get_first_node_in_group("player")
	match _state:
		HANG:
			sprite.frame = 0
			if cat and absf(cat.global_position.x - global_position.x) < trigger_range and cat.global_position.y > global_position.y:
				_state = SHAKE
				_t = 0.0
				Game.sfx("coconut_shake", 0.1, -4.0)
		SHAKE:
			sprite.frame = 0
			sprite.position.x = sin(_t * 60.0)  # wobble
			if _t > 0.5:
				sprite.position.x = 0
				_state = FALL
		FALL:
			sprite.frame = 1 + int(_t * 10) % 2
			_vy += gravity * delta
			position.y += _vy * delta
			if _touching_cat(cat):
				cat.take_damage(damage, global_position)
				Game.sfx("coconut_hit")
				_hit_cat = true
				_state = BREAK
				_t = 0.0
			elif _on_ground(cat):
				Game.sfx("coconut_hit", 0.06, -4.0)
				_state = BREAK
				_t = 0.0
		BREAK:
			var f := int(_t * BREAK_FPS)
			if _hit_cat:  # smashed on the cat's head: it bursts and is gone, no snack
				sprite.frame = CRACK + 2 + f
				if f >= 3:
					queue_free()
			else:  # hits the sand, then cracks open into a drink
				sprite.frame = mini(IMPACT + f, ITEM_FRAME)
				if IMPACT + f >= ITEM_FRAME:
					_state = ITEM
		ITEM:
			sprite.frame = ITEM_FRAME
			if _touching_cat(cat) and cat.hp < cat.max_hp:
				cat.heal(heal)
				queue_free()


func _touching_cat(cat: Node2D) -> bool:
	return cat and absf(cat.global_position.x - global_position.x) < 8 and absf(cat.global_position.y - 6 - global_position.y) < 9


func _on_ground(cat: Node2D) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(0, 1)
	query.collision_mask = 1
	if cat:
		query.exclude = [cat.get_rid()]
	return not get_world_2d().direct_space_state.intersect_point(query).is_empty()
