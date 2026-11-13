extends Area2D
# Locked chest: opens when the cat walks up to it carrying the key `key_name` (a Key node's name, see key.gd) and a 1up
# jumps out (named `reward_name`, which counts like any other 1up; level.gd counts every "Chest*" node as one). Once the
# reward is taken the chest stays open after a lost life; until then it can be opened again.

const LIFE := preload("res://scenes/objects/life.tscn")

@export var key_name := ""
@export var reward_name := "LifeChest"
@export_multiline var locked_message := "Zamknięta na klucz. Gdzieś na tym poziomie musi być klucz."

var _open := false
var _cool := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if Game.is_collected(reward_name):
		_open = true
		$Lid.rotation = -1.15


func _process(delta: float) -> void:
	_cool -= delta


func _on_body_entered(body: Node2D) -> void:
	if _open or not body.is_in_group("player"):
		return
	if not Game.is_collected(key_name):
		if _cool <= 0:
			_cool = 5.0
			Game.hint.emit(locked_message)
			var tween := create_tween()
			tween.tween_property($Body, "position:x", 1.5, 0.04)
			tween.tween_property($Body, "position:x", -1.5, 0.08)
			tween.tween_property($Body, "position:x", 0.0, 0.04)
		return
	_open = true
	Game.sfx("gem", 0.0, -2.0)
	create_tween().tween_property($Lid, "rotation", -1.15, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var life := LIFE.instantiate()
	life.name = reward_name
	_pop.call_deferred(life)


# the 1up flies out of the chest in an arc and lands beside it
func _pop(life: Area2D) -> void:
	life.position = position + Vector2(0, -12)
	get_parent().add_child(life)
	var land := position + Vector2(22, 0)
	var tween := life.create_tween()
	tween.tween_property(life, "position:x", land.x, 0.55)
	tween.parallel().tween_property(life, "position:y", position.y - 40, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(life, "position:y", land.y, 0.33).set_delay(0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
