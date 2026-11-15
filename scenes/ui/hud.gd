extends CanvasLayer

const HEART := preload("res://assets/game/heart.png")


func _ready() -> void:
	Game.message.connect(_on_message)
	Game.hp_changed.connect(_on_hp_changed)
	Game.hint.connect(_on_hint)
	Game.pickups_changed.connect(refresh_hearts)
	Game.level_done.connect(_on_level_done)
	refresh_hearts()
	update_dev_badge()
	_show_banner(tr("POZIOM %d") % (Game.level_index + 1))


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


var _hint_tween: Tween


func _on_hint(text: String) -> void:
	$HintBox/Text.text = Game.keys(tr(text))
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property($HintBox, "modulate:a", 1.0, 0.3)
	_hint_tween.tween_interval(4.0)
	_hint_tween.tween_property($HintBox, "modulate:a", 0.0, 0.6)


func refresh_hearts() -> void:
	while $Lives.get_child_count() < maxi(Game.START_LIVES, Game.lives):  # 1ups add hearts
		var heart := TextureRect.new()
		heart.texture = HEART
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # 3x texture drawn at the logical 9x8
		heart.custom_minimum_size = Vector2(9, 8)
		$Lives.add_child(heart)
		if Game.lives > Game.START_LIVES:  # a 1up: the new heart pops in
			heart.pivot_offset = Vector2(4.5, 4)
			heart.scale = Vector2.ONE * 2.5
			heart.create_tween().tween_property(heart, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	$Coins/Count.text = "%d/%d" % [Game.coins(Game.level_index), Game.total(Game.level_index, "Coin")]
	for i in $Lives.get_child_count():
		# lost lives stay as dark hearts
		$Lives.get_child(i).modulate = Color.WHITE if i < Game.lives else Color(0.2, 0.2, 0.2, 0.6)


func _on_hp_changed(hp: int, max_hp: int) -> void:
	$HP.max_value = max_hp
	$HP.value = hp


func _on_level_done(stats: Dictionary) -> void:
	$Summary/Panel/Hint.text = Game.keys(tr("Spacja / ✕ - dalej"))
	$Summary/Panel/Title.text = tr("POZIOM %d") % (stats.level + 1)
	$Summary/Panel/Row0/Count.text = "%d/%d" % [stats.coins, Game.total(stats.level, "Coin")]
	$Summary/Panel/Row1/Count.text = "%d/%d" % [stats.lives, Game.total(stats.level, "Life")]
	$Summary/Panel/Row2/Count.text = "%d/%d" % [stats.diamonds, Game.total(stats.level, "Diamond")]
	$Summary/Panel/Grade.text = tr("OCENA: %s") % stats.grade
	# hidden badge: nobody died on this level
	var peace: Label = $Summary/Peace
	peace.text = tr("BEZ PRZEMOCY")
	peace.visible = stats.kills == 0
	$Summary.visible = true
	var grade: Label = $Summary/Panel/Grade
	grade.scale = Vector2.ONE * 2.5  # stamped on
	grade.modulate.a = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.5)
	tween.tween_property(grade, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(grade, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if peace.visible:
		peace.modulate.a = 0.0
		tween.tween_interval(0.3)
		tween.tween_callback(Game.sfx.bind("oneup", 0.0))
		tween.tween_property(peace, "modulate:a", 1.0, 0.3)


func _on_message(text: String) -> void:  # "title\nhint"; empty hides
	if text == "":
		$Summary.visible = false
	refresh_hearts()  # game over never reloads the level, so hearts must update here
	var lines := text.split("\n")
	$Message/Title.text = lines[0]
	$Message/Hint.text = Game.keys(lines[1]) if lines.size() > 1 else ""
	$Message/Title.modulate = Color(1, 0.35, 0.3) if lines[0] == "GAME OVER" else Color.WHITE
	$Message.visible = text != ""
