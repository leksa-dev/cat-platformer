extends Area2D
# Coin, 1up or diamond. Once taken it stays taken for the rest of the game (the level reloads after a lost life),
# so names must be unique within a level.

@export_enum("Coin", "Life", "Diamond") var kind := 0
@export_enum("Red", "Blue", "Green", "Purple") var gem := 0

var _t := 0.0


func _ready() -> void:
	if Game.is_collected(name):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	_t = position.x * 0.05  # coins next to each other don't spin in sync
	if kind == 2:
		$Sprite.texture = load("res://assets/game/diamond_%s.png" % ["red", "blue", "green", "purple"][gem])


func _process(delta: float) -> void:
	_t += delta
	if kind == 0:
		$Sprite.scale.x = $Sprite.scale.y * maxf(absf(cos(_t * 3.0)), 0.15)  # spinning coin
	elif kind == 2:
		$Sprite.position.y = -8 + sin(_t * 2.0) * 1.5
		$Sprite.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.6, 1.6), maxf(sin(_t * 4.0), 0.0) ** 8)  # glint
	else:
		$Sprite.position.y = -8 + sin(_t * 3.0)
		$Sprite.scale = Vector2.ONE * (1.0 + 0.08 * sin(_t * 6.0)) / 3.0  # beating heart


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Game.collect(name)
	if kind == 0:
		Game.sfx("coin", 0.03, -4.0)
	elif kind == 2:
		Game.sfx("oneup", 0.0, -2.0)
	else:
		Game.gain_life()
	queue_free()
