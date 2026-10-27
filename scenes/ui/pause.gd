extends "res://scenes/ui/menu_list.gd"
# Pause menu (Esc / P / Options): WZNÓW, OPCJE, OD NOWA, DEV, MENU. The orange plank marks the choice.

const BUTTONS_Y := [42, 63, 82, 102, 123]  # button centres in pause_panel5.png (4-plank art + one copied plank)

var _in_options := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # it runs while the game is paused
	visible = false
	chosen.connect(_on_chosen)


func _process(delta: float) -> void:
	if $"../Dev".visible:
		return  # the dev menu has the input
	if Input.is_action_just_pressed("dev") and not Game.message_open():
		_open()
		_open_dev()
		return
	if visible and Input.is_action_just_pressed("back"):  # Circle: one step back
		Game.sfx("menu_move", 0.0)
		if _in_options:
			_show_main()
		else:
			_close()
		return
	if Input.is_action_just_pressed("pause") and not Game.message_open():
		if not visible:
			_open()
		elif _in_options:
			_show_main()
		else:
			_close()
		return
	if visible and _in_options and selected in [1, 2] and nudge_volume("Music" if selected == 1 else "SFX"):
		fit_text(items[selected], volume_text("Music" if selected == 1 else "SFX"))
	super._process(delta)


func _open() -> void:
	visible = true
	get_tree().paused = true
	_show_main()


func _close() -> void:
	visible = false
	get_tree().paused = false


func _open_dev() -> void:
	visible = false
	$"../Dev".open(self)


func back_from_dev() -> void:
	visible = true
	_show_main()
	select(3)


func _show_main() -> void:
	_in_options = false
	_set_items(["WZNÓW", "OPCJE", "OD NOWA", "DEV", "MENU"].map(tr))  # "MENU GŁÓWNE" doesn't fit the plank


func _show_options() -> void:
	_in_options = true
	_set_items([fullscreen_text(), volume_text("Music"), volume_text("SFX"), vibration_text(), tr("WRÓĆ")])  # language: main menu only (5 planks)


func _set_items(texts: Array) -> void:
	var labels := [$Panel/Item0, $Panel/Item1, $Panel/Item2, $Panel/Item3, $Panel/Item4]
	items.clear()
	for i in labels.size():
		fit_text(labels[i], texts[i] if i < texts.size() else "")
		if i < texts.size():
			items.append(labels[i])
	select(0)


func _on_select(index: int) -> void:
	$Panel/Highlight.position.y = BUTTONS_Y[index] - $Panel/Highlight.size.y / 2
	items[index].modulate = Color(0.35, 0.18, 0.05)  # dark text on the orange plank


func _on_chosen(index: int) -> void:
	if _in_options:
		match index:
			0:
				Game.toggle_fullscreen()
				fit_text($Panel/Item0, fullscreen_text())
				select(0)
			1, 2:  # Space steps the volume up, wrapping to 0; left/right in _process
				var bus := "Music" if index == 1 else "SFX"
				Game.set_volume(bus, (Game.volume[bus] + 1) % 11)
				fit_text(items[index], volume_text(bus))
			3:
				Game.toggle_vibration()
				fit_text(items[3], vibration_text())
			4: _show_main()
		return
	match index:
		0: _close()
		1: _show_options()
		2:
			_close()
			get_tree().reload_current_scene()
		3: _open_dev()
		4:
			visible = false
			Game.go_to_menu()
