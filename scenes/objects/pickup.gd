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
		$Sprite.scale = Vector2.ONE * (1.0 + 0.06 * sin(_t * 6.0)) * 0.4  # pulsing orb


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Game.collect(name)
	if kind == 0:
		Game.sfx("coin", 0.03, -4.0)
	elif kind == 2:
		Game.sfx("gem", 0.0, -3.0)
	else:
		Game.gain_life()
		_burst()
	queue_free()


# 1up: a flash ring, sparks, and "+1 ŻYCIE" floating up; they live in the level so they outlast the pickup
func _burst() -> void:
	var at := global_position + Vector2(0, -8)
	var fx := Node2D.new()
	fx.z_index = 5
	get_parent().add_child(fx)
	fx.global_position = at
	var ring := Sprite2D.new()
	ring.texture = $Sprite.texture
	ring.scale = Vector2.ONE * 0.4
	ring.material = CanvasItemMaterial.new()
	ring.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.add_child(ring)
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 16
	sparks.lifetime = 0.6
	sparks.spread = 180.0
	sparks.initial_velocity_min = 40.0
	sparks.initial_velocity_max = 80.0
	sparks.gravity = Vector2(0, 60)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	sparks.color = Color(0.75, 1.0, 0.35)
	fx.add_child(sparks)
	sparks.emitting = true
	var label := Label.new()
	label.text = tr("+1 ŻYCIE")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.4))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.05))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-30, -22)
	label.size = Vector2(60, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fx.add_child(label)
	var tween := fx.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector2.ONE * 1.6, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_property(label, "position:y", -44.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.7)
	tween.chain().tween_callback(fx.queue_free)
