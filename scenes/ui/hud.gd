extends CanvasLayer

const HEART := preload("res://assets/game/heart.png")


func _ready() -> void:
	Game.message.connect(_on_message)
	Game.hp_changed.connect(_on_hp_changed)
	for i in Game.START_LIVES:
		var heart := TextureRect.new()
		heart.texture = HEART
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # 3x texture drawn at the logical 9x8
		heart.custom_minimum_size = Vector2(9, 8)
		$Lives.add_child(heart)
	refresh_hearts()
	update_dev_badge()
	_show_banner("POZIOM %d" % (Game.level_index + 1))


func update_dev_badge() -> void:
	var flags := []
	if Game.god_mode:
		flags.append("GOD")
	if Game.fly_mode:
		flags.append("FLY")
	$DevBadge.text = " ".join(flags)


func _show_banner(text: String) -> void:
	$Banner/Text.text = text
	var tween := create_tween()
	tween.tween_property($Banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property($Banner, "modulate:a", 0.0, 0.6)


func refresh_hearts() -> void:
	for i in $Lives.get_child_count():
		# lost lives stay as dark hearts
		$Lives.get_child(i).modulate = Color.WHITE if i < Game.lives else Color(0.2, 0.2, 0.2, 0.6)


func _on_hp_changed(hp: int, max_hp: int) -> void:
	$HP.max_value = max_hp
	$HP.value = hp


func _on_message(text: String) -> void:  # "title\nhint"; empty hides
	refresh_hearts()  # game over never reloads the level, so hearts must update here
	var lines := text.split("\n")
	$Message/Title.text = lines[0]
	$Message/Hint.text = lines[1] if lines.size() > 1 else ""
	$Message/Title.modulate = Color(1, 0.35, 0.3) if lines[0] == "GAME OVER" else Color.WHITE
	$Message.visible = text != ""
