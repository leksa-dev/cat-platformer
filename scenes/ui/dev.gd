extends "res://scenes/ui/menu_list.gd"
# Developer menu (Pause > OPCJE > DEV, or F1): jump to a level or - for level 4 - to one of its sub-levels (a sub-menu), god mode, noclip
# flight, refill, warp to the goal... God mode, flight and the last sub-level are remembered between runs.

# level 4 sub-levels: [name, column to start on (a few columns in; Fort 1 starts earlier, its first pit is at 195)]
const SECTIONS := [["KOPIEC 1", 0], ["KOPIEC 2 - LAS", 64], ["KOPIEC 3 - RÓWNINA", 128], ["FORT 1", 190], ["FORT 2", 259], ["FORT 3", 323],
		["STADION", 387], ["PARK", 483], ["RYNEK", 556], ["BULWARY", 620], ["KŁADKA BERNATKA", 748]]
const LEVEL4 := 3

var _page := 0  # 0 = main, 1 = level 4 sub-levels

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
	_page = 0
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
	if _page == 1:
		for sec in SECTIONS:
			t.append(("▸ " if SECTIONS.find(sec) == Game.dev_sub else "") + sec[0])
		t.append(tr("WRÓĆ"))
		return t
	for i in Game.LEVELS.size():
		t.append(tr("POZIOM %d") % (i + 1) + (" ▸" if i == LEVEL4 else ""))
	t.append("GOD MODE: " + tr("TAK" if Game.god_mode else "NIE"))
	t.append(tr("LATANIE") + ": " + tr("TAK" if Game.fly_mode else "NIE"))
	t += ["PEŁNE HP + ŻYCIA", "DO METY", "BEZ WROGÓW", "KOCIMIĘTKA", "+50 MONET", "GALERIA ASSETÓW", "WRÓĆ"].map(tr)
	return t


func _refresh() -> void:
	var texts := _texts()
	var list: VBoxContainer = $Panel/List
	while list.get_child_count() < texts.size():
		var label := Label.new()
		label.custom_minimum_size = Vector2(150, 11)
		label.add_theme_font_size_override("font_size", 12)  # 11 rows have to fit on screen
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(label)
	items.clear()
	for i in texts.size():
		list.get_child(i).text = texts[i]
		list.get_child(i).visible = true
		items.append(list.get_child(i))
	for i in range(texts.size(), list.get_child_count()):
		list.get_child(i).visible = false
	select.call_deferred(selected)  # labels need a layout pass before the arrow can be placed


func _process(delta: float) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("dev") or Input.is_action_just_pressed("back"):
		if _page == 1:   # one step back: from the sub-levels to the main page
			_page = 0
			_refresh()
			select(LEVEL4)
			return
		_close_to_pause()
		return
	super._process(delta)


func select(index: int) -> void:
	super.select(index)
	if arrow and not items.is_empty():  # labels sit inside the list container: offset the arrow by it
		arrow.position += $Panel/List.position + $Panel.position - position


func _go_to_section(index: int) -> void:
	var col: int = SECTIONS[index][1]
	var level := get_tree().current_scene
	var cat: Node2D = get_tree().get_first_node_in_group("player")
	var spot := Vector2(72, 160) if index == 0 else _ground_spot(level, col + 3)
	Game.set_dev("sub", index)
	if Game.level_index == LEVEL4 and cat:   # already in level 4: just move the cat and make this its respawn point
		cat.global_position = spot
		cat.velocity = Vector2.ZERO
		Game.checkpoint = spot
		level.get_node("Cat/Camera2D").reset_smoothing()
		_resume()
	else:
		Game.dev_spawn = spot
		visible = false
		Game.load_level(LEVEL4)


# a standing spot on the topmost ground tile of a column
func _ground_spot(level: Node, col: int) -> Vector2:
	var ground: TileMapLayer = level.get_node("Ground")
	for row in range(0, 40):
		if ground.get_cell_source_id(Vector2i(col, row)) != -1:
			return Vector2(col * 16 + 8, row * 16 - 2)
	return Vector2(col * 16 + 8, 100)


func _on_chosen(index: int) -> void:
	if _page == 1:
		if index < SECTIONS.size():
			_go_to_section(index)
		else:
			_page = 0
			_refresh()
			select(LEVEL4)
		return
	var levels := Game.LEVELS.size()
	var level := get_tree().current_scene
	var cat: Node2D = get_tree().get_first_node_in_group("player")
	if index == LEVEL4:   # opens the sub-levels of level 4
		_page = 1
		_refresh()
		select(Game.dev_sub)
		return
	if index < levels:
		visible = false
		Game.load_level(index)
		return
	match index - levels:
		0: Game.set_dev("god", not Game.god_mode)
		1: Game.set_dev("fly", not Game.fly_mode)
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
			for node in level.level_objects():
				if node is Enemy and not node.dead:
					node.hurt(999, node.global_position)
		5:
			if cat:
				cat.eat_catnip()
				_resume()
				return
		6:
			Game.spent -= 50   # dev: money for the shops (spent may go negative)
			Game.pickups_changed.emit()
		7:
			visible = false
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/gallery.tscn")
			return
		8:
			_close_to_pause()
			return
	get_parent().update_dev_badge()
	_refresh()
