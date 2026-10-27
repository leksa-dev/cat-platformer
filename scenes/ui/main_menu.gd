extends "res://scenes/ui/menu_list.gd"
# Title screen: GRAJ / OPCJE / WYJŚCIE on the beach signpost. Options replace the items in place.

var _page := "main"  # main / play (DALEJ, NOWA GRA) / options / sound (MUZYKA, EFEKTY, WIBRACJE)
const BUSES := ["Music", "SFX"]


func _ready() -> void:
	chosen.connect(_on_chosen)
	Game.device_changed.connect(_back_hint)
	Game.play_music("forest")
	_show_main()


func _show_page(page: String, texts: Array, index := 0) -> void:  # sub-pages reuse the 3 planks; back is Esc / ○ (hint under the sign)
	_page = page
	_set_items(texts)
	_back_hint()
	$BackHint.visible = page != "main"
	select(index)


func _back_hint() -> void:  # keyboard or pad key names, whichever was used last
	$BackHint.text = Game.keys(tr("Esc - wróć"))


func _show_main(index := 0) -> void:
	_show_page("main", ["GRAJ", "OPCJE", "WYJŚCIE"].map(tr), index)


func _show_options(index := 0) -> void:
	_show_page("options", [fullscreen_text(), tr("DŹWIĘK"), language_text()], index)


func _show_sound(index := 0) -> void:
	_show_page("sound", BUSES.map(volume_text) + [vibration_text()], index)


func _set_items(texts: Array) -> void:
	var labels := [$Item0, $Item1, $Item2]
	items.clear()
	for i in labels.size():
		fit_text(labels[i], texts[i] if i < texts.size() else "")
		if i < texts.size():
			items.append(labels[i])


const PLANK_Y := [36.3, 59.7, 81.3]  # the glow ring's top for each plank pair of the signpost (title_screen3.png)


func _on_select(index: int) -> void:  # the glow ring moves around the chosen pair of planks
	$Plank.position.y = PLANK_Y[index]
	for i in items.size():
		items[i].modulate = Color(1.15, 1.1, 0.9) if i == index else Color(0.8, 0.72, 0.6)


func _process(delta: float) -> void:
	super._process(delta)
	if _page == "sound" and selected < BUSES.size() and nudge_volume(BUSES[selected]):
		_show_sound(selected)
	if _page != "main" and (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("back")):
		Game.sfx("menu_move", 0.0)
		if _page == "sound":
			_show_options(1)
		else:
			_show_main(0 if _page == "play" else 1)


func _on_chosen(index: int) -> void:
	match _page:
		"play":
			if index == 0:
				Game.continue_game()
			else:
				Game.start_game()
		"sound":  # Space steps the volume up, wrapping to 0; the last row switches the pad rumble
			if index < BUSES.size():
				Game.set_volume(BUSES[index], (Game.volume[BUSES[index]] + 1) % 11)
			else:
				Game.toggle_vibration()
			_show_sound(index)
		"options":
			match index:
				0: Game.toggle_fullscreen()
				1:
					_show_sound()
					return
				2: Game.next_language()
			_show_options(index)
		"main":
			match index:
				0:
					var level := Game.saved_level()
					if level < 0:
						Game.start_game()
					else:
						_show_page("play", [tr("DALEJ: POZIOM %d") % (level + 1), tr("NOWA GRA")])
				1: _show_options()
				2: get_tree().quit()
