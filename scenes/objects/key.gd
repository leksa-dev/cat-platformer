extends Area2D
# Key (art in assets/game/key_<color>.png): taking it is remembered for the rest of the game, like a coin, so the chest or
# door it belongs to (which asks Game.is_collected(name)) stays openable after a lost life. Names must be unique in a level.

@export_enum("gold", "silver", "red", "blue", "green") var color := "gold"
@export_multiline var message := ""  # tip shown in the dialog box when taken

var _t := 0.0


func _ready() -> void:
	if Game.is_collected(name):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	$Sprite.texture = load("res://assets/game/key_%s.png" % color)
	_t = position.x * 0.05


func _process(delta: float) -> void:
	_t += delta
	$Sprite.position.y = -9 + sin(_t * 2.5) * 1.5
	$Sprite.rotation = sin(_t * 1.5) * 0.12


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Game.collect(name)
	Game.sfx("gem", 0.0, -2.0)
	Game.rumble(0.3, 0.0, 0.1)
	if message != "":
		Game.hint.emit(message)
	queue_free()
