extends StaticBody2D
# Breakable crate (solid; sits on the enemy layer too, so claws "hurt" it): scratching smashes it and a coin or a gem pops out.
# Farts and yarn balls (they come with a stun) do nothing to it, a thrown ball just bounces off. A falling crusher smashes it too
# (crusher.gd looks the "breakable" group up). The crate's name decides what the level counts it as: "CoinCrate..." = a coin,
# "DiamondCrate..." = a diamond, anything else holds nothing. Once its item is taken it stays gone after a lost life.

const COIN := preload("res://scenes/objects/coin.tscn")
const DIAMOND := preload("res://scenes/objects/diamond.tscn")

@export_enum("none", "coin", "diamond") var contents := 0
@export_enum("Red", "Blue", "Green", "Purple") var gem := 0

var _broken := false


func _ready() -> void:
	add_to_group("breakable")
	if contents != 0 and Game.is_collected(item_name()):
		queue_free()   # already smashed and its item taken


func item_name() -> String:
	return str(name) + "Item"


func hurt(_amount: int, from: Vector2, stun := 0.0) -> void:
	if stun > 0.0:
		return   # fart cloud (stun 1) and yarn ball (stun 2) don't break it
	smash(from)


func smash(from := Vector2.INF) -> void:
	if _broken:
		return
	_broken = true
	Game.sfx("enemy_hit", 0.1, -2.0)
	Game.rumble(0.2, 0.3, 0.08)
	_spray()
	if contents != 0:
		var item: Area2D = (COIN if contents == 1 else DIAMOND).instantiate()
		item.name = item_name()
		if contents == 2:
			item.gem = gem
		item.position = position + Vector2(0, -8)
		get_parent().add_child.call_deferred(item)
		var away := signf(global_position.x - from.x) if from.x != INF and from.x != global_position.x else 1.0
		var tween := item.create_tween()
		tween.tween_property(item, "position:y", position.y - 26, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(item, "position:y", position.y - 8, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		item.create_tween().tween_property(item, "position:x", position.x + away * 6.0, 0.34)
	queue_free()


# wooden splinters
func _spray() -> void:
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 12
	sparks.lifetime = 0.5
	sparks.spread = 180.0
	sparks.initial_velocity_min = 40.0
	sparks.initial_velocity_max = 90.0
	sparks.gravity = Vector2(0, 260)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	sparks.color = Color(0.62, 0.42, 0.22)
	sparks.position = position + Vector2(0, -8)
	get_parent().add_child.call_deferred(sparks)
	sparks.emitting = true
	get_tree().create_timer(0.8).timeout.connect(sparks.queue_free)
