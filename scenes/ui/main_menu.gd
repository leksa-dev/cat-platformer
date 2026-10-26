extends "res://scenes/ui/menu_list.gd"
# Title screen: GRAJ / OPCJE / WYJŚCIE on the beach signpost. Options replace the items in place.

var _in_options := false


func _ready() -> void:
	chosen.connect(_on_chosen)
	Game.play_music("forest")
	_show_main()


func _show_main() -> void:
	_in_options = false
	_set_items(["GRAJ", "OPCJE", "WYJŚCIE"])


func _show_options() -> void:
	_in_options = true
	_set_items([fullscreen_text(), music_text(), "WRÓĆ"])


func _set_items(texts: Array) -> void:
	var labels := [$Item0, $Item1, $Item2]
	items.clear()
	for i in labels.size():
		labels[i].text = texts[i] if i < texts.size() else ""
		if i < texts.size():
			items.append(labels[i])
	select(0)


func _on_select(index: int) -> void:
	# the top plank is orange in the art: golden text is unreadable on it, use dark wood colours
	if not items.is_empty():
		items[0].modulate = Color(0.3, 0.15, 0.04) if index == 0 else Color(0.5, 0.3, 0.12)


func _process(delta: float) -> void:
	super._process(delta)
	if _in_options and (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("back")):
		Game.sfx("menu_move", 0.0)
		_show_main()


func _on_chosen(index: int) -> void:
	if _in_options:
		match index:
			0:
				Game.toggle_fullscreen()
				$Item0.text = fullscreen_text()
			1:
				Game.toggle_music()
				$Item1.text = music_text()
			2:
				_show_main()
				return
		select(index)
		return
	match index:
		0: Game.start_game()
		1: _show_options()
		2: get_tree().quit()
