extends Control
# After the last level: the beach signpost shows the game's time and coins. Space / ✕ goes back to the menu.

var _ready_at := 0


func _ready() -> void:
	Game.play_music("forest")
	var t := int(Game.run_time)
	$Item0.text = tr("WYGRANA!")
	$Item1.text = tr("CZAS %d:%02d") % [t / 60, t % 60]
	$Item2.text = tr("MONETY %d/%d") % [Game.coins(), Game.COINS_PER_LEVEL * Game.LEVELS.size()]
	$Lives.text = Game.keys(tr("Życia: %d      Spacja / ✕ - menu")) % Game.lives
	_ready_at = Engine.get_process_frames()
	var tween := create_tween().set_loops()  # the title plank glows
	tween.tween_property($Plank, "modulate", Color(1.15, 1.1, 0.9), 0.6)
	tween.tween_property($Plank, "modulate", Color.WHITE, 0.6)


func _process(_delta: float) -> void:
	# ignore the key press that finished the level
	if Engine.get_process_frames() - _ready_at > 30 and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")):
		Game.sfx("menu_select", 0.0)
		Game.go_to_menu()
