extends "res://scenes/ui/menu_list.gd"
# Developer menu (Pause > OPCJE > DEV, or F1): jump to a level, god mode, noclip flight, refill, warp to the goal...

var _pause: Control
var _opened_frame := -1  # the key that opened the menu is still "just pressed" this frame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	chosen.connect(_on_chosen)


func open(pause: Control) -> void:
	_pause = pause
	_opened_frame = Engine.get_process_frames()
	visible = true
	_refresh()
	select(0)


func _close_to_pause() -> void:
	visible = false
	_pause.back_from_dev()


func _resume() -> void:
	visible = false
	get_tree().paused = false


func _texts() -> Array:
	var t := []
	for i in Game.LEVELS.size():
		t.append(tr("POZIOM %d") % (i + 1))
	t.append("GOD MODE: " + tr("TAK" if Game.god_mode else "NIE"))
	t.append(tr("LATANIE") + ": " + tr("TAK" if Game.fly_mode else "NIE"))
	t += ["PEŁNE HP + ŻYCIA", "DO METY", "BEZ WROGÓW", "KOCIMIĘTKA", "WRÓĆ"].map(tr)
	return t


func _refresh() -> void:
	var texts := _texts()
	var list: VBoxContainer = $Panel/List
	while list.get_child_count() < texts.size():
		var label := Label.new()
		label.custom_minimum_size = Vector2(150, 12)
		label.add_theme_font_size_override("font_size", 12)  # 11 rows have to fit on screen
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(label)
	items.clear()
	for i in texts.size():
		list.get_child(i).text = texts[i]
		items.append(list.get_child(i))
	select.call_deferred(selected)  # labels need a layout pass before the arrow can be placed


func _process(delta: float) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("dev") or Input.is_action_just_pressed("back"):
		_close_to_pause()
		return
	super._process(delta)


func select(index: int) -> void:
	super.select(index)
	if arrow and not items.is_empty():  # labels sit inside the list container: offset the arrow by it
		arrow.position += $Panel/List.position + $Panel.position - position


func _on_chosen(index: int) -> void:
	var levels := Game.LEVELS.size()
	var level := get_tree().current_scene
	var cat: Node2D = get_tree().get_first_node_in_group("player")
	if index < levels:
		visible = false
		Game.load_level(index)
		return
	match index - levels:
		0: Game.god_mode = not Game.god_mode
		1: Game.fly_mode = not Game.fly_mode
		2:
			Game.lives = Game.START_LIVES
			if cat:
				cat.heal(cat.max_hp)
			get_parent().refresh_hearts()
		3:
			if cat and level.has_node("Goal"):
				cat.global_position = level.get_node("Goal").global_position + Vector2(-24, -2)
				cat.velocity = Vector2.ZERO
				_resume()
				return
		4:
			for node in level.get_children():
				if node is Enemy and not node.dead:
					node.hurt(999, node.global_position)
		5:
			if cat:
				cat.eat_catnip()
				_resume()
				return
		6:
			_close_to_pause()
			return
	get_parent().update_dev_badge()
	_refresh()
