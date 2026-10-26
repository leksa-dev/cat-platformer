extends StaticBody2D
# Berry bush: on the enemy layer, so scratches (and farts) "hurt" it. Every hit shakes out a berry (+1 HP);
# the 7th hit drops a 1up instead, and then the bush is bare.

const BERRY := preload("res://scenes/objects/secret/berry.tscn")
const LIFE := preload("res://scenes/objects/life.tscn")

@export var hits_for_life := 7

var _hits := 0
var _cool := 0.0


func _physics_process(delta: float) -> void:
	_cool -= delta


func hurt(_amount: int, from: Vector2, _stun := 0.0) -> void:
	if _cool > 0 or _hits >= hits_for_life or Game.is_collected("LifeBush"):
		return
	_cool = 0.25  # a scratch flurry counts a few times, not every swipe
	_hits += 1
	Game.sfx("enemy_hit", 0.1, -4.0)
	var tween := create_tween()
	tween.tween_property($Sprite, "rotation", 0.12, 0.05)
	tween.tween_property($Sprite, "rotation", -0.1, 0.07)
	tween.tween_property($Sprite, "rotation", 0.0, 0.05)
	var drop: Area2D
	if _hits >= hits_for_life:
		drop = LIFE.instantiate()
		drop.name = "LifeBush"
		$Sprite.modulate = Color(0.75, 0.8, 0.7)  # picked clean
	else:
		drop = BERRY.instantiate()
	_pop.call_deferred(drop, signf(global_position.x - from.x))  # not mid physics query


func _pop(drop: Area2D, away: float) -> void:
	drop.position = position + Vector2(0, -14)
	get_parent().add_child(drop)
	var land := position + Vector2((away if away else 1.0) * randf_range(10, 26), 0)
	var tween := drop.create_tween()
	tween.tween_property(drop, "position:x", land.x, 0.45)
	tween.parallel().tween_property(drop, "position:y", position.y - 26, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(drop, "position:y", land.y, 0.27).set_delay(0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
