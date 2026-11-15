extends Node2D
# Stall in a level where coins are spent (Game.wallet / Game.buy): stand in front of it and press down. Up/down picks, jump buys,
# back (Backspace / Circle) or WYJDŹ leaves. The game is paused while the shop is open. Bottom-centre at the node.
# Placeholder art: a market stall drawn in code.

const ITEMS := {
	"double_jump": ["PODWÓJNY SKOK", 40],
	"hp": ["+1 SERCE", 30],
	"life": ["ŻYCIE", 20],
	"catnip": ["KOCIMIĘTKA", 8],
}
const MAX_HP_BONUS := 2

@export var items: PackedStringArray = ["double_jump", "hp", "life", "catnip"]

var _open := false
var _opened_frame := -1
var _sel := 0
var _ui: CanvasLayer
var _rows: Array[Label] = []
var _wallet: Label
var _note: Label
var _prompt: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # the shop runs while the game is paused
	_prompt = _label("DÓŁ: SKLEPIK", 8, Color(1, 0.9, 0.5))
	_prompt.position = Vector2(-40, -58)
	_prompt.size = Vector2(80, 12)
	_prompt.visible = false
	add_child(_prompt)
	_build_ui()


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	_ui.visible = false
	add_child(_ui)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.size = Vector2(320, 180)
	_ui.add_child(dim)
	var panel := ColorRect.new()
	panel.color = Color(0.22, 0.13, 0.08, 0.96)
	panel.position = Vector2(70, 24)
	panel.size = Vector2(180, 132)
	_ui.add_child(panel)
	var title := _label("SKLEPIK", 12, Color(1, 0.85, 0.4))
	title.position = Vector2(70, 28)
	title.size = Vector2(180, 14)
	_ui.add_child(title)
	_wallet = _label("", 9, Color(1, 0.9, 0.3))
	_wallet.position = Vector2(70, 44)
	_wallet.size = Vector2(180, 12)
	_ui.add_child(_wallet)
	for i in items.size() + 1:
		var row := _label("", 9)
		row.position = Vector2(76, 62 + i * 14)
		row.size = Vector2(168, 12)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_ui.add_child(row)
		_rows.append(row)
	_note = _label("", 8, Color(0.85, 0.85, 0.85))
	_note.position = Vector2(70, 140)
	_note.size = Vector2(180, 12)
	_ui.add_child(_note)


func _cat() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player") as CharacterBody2D


func _available(id: String) -> bool:
	match id:
		"double_jump": return not Game.upgrades.get("double_jump", false)
		"hp": return int(Game.upgrades.get("hp_bonus", 0)) < MAX_HP_BONUS
	return true


func _refresh() -> void:
	_wallet.text = "monety: %d" % Game.wallet()
	for i in _rows.size():
		var mark := "> " if i == _sel else "  "
		if i < items.size():
			var id: String = items[i]
			var item: Array = ITEMS[id]
			var ok := _available(id)
			_rows[i].text = mark + ("%s  %d" % [item[0], item[1]] if ok else "%s  (masz)" % item[0])
			_rows[i].modulate = Color.WHITE if ok and Game.wallet() >= item[1] else Color(0.6, 0.55, 0.5)
		else:
			_rows[i].text = mark + "WYJDŹ"
			_rows[i].modulate = Color.WHITE


func _process(_delta: float) -> void:
	var cat := _cat()
	var near := cat != null and cat.visible and absf(cat.global_position.x - global_position.x) < 28 and absf(cat.global_position.y - global_position.y) < 10
	_prompt.visible = near and not _open
	if not _open:
		if near and cat.is_on_floor() and Input.is_action_just_pressed("down") and not get_tree().paused:
			_set_open(true)
		return
	if Engine.get_process_frames() == _opened_frame:
		return
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		_sel = wrapi(_sel - 1, 0, _rows.size())
		Game.sfx("menu_move", 0.0)
		_refresh()
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		_sel = wrapi(_sel + 1, 0, _rows.size())
		Game.sfx("menu_move", 0.0)
		_refresh()
	elif Input.is_action_just_pressed("back"):
		_set_open(false)
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		if _sel >= items.size():
			_set_open(false)
		else:
			_buy(items[_sel])


func _set_open(open: bool) -> void:
	_open = open
	_ui.visible = open
	get_tree().paused = open
	_opened_frame = Engine.get_process_frames()
	_note.text = ""
	if open:
		_sel = 0
		_refresh()
	Game.sfx("menu_select", 0.0)


func _buy(id: String) -> void:
	var item: Array = ITEMS[id]
	if not _available(id):
		_note.text = "Już to masz."
		return
	if not Game.buy(item[1]):
		_note.text = "Za mało monet."
		return
	var cat := _cat()
	match id:
		"double_jump":
			Game.upgrades["double_jump"] = true
			_note.text = "Skok w powietrzu: jeszcze raz Spacja / ✕"
		"hp":
			Game.upgrades["hp_bonus"] = int(Game.upgrades.get("hp_bonus", 0)) + 1
			if cat:
				cat.max_hp += 1
				cat.heal(cat.max_hp)
			_note.text = "Więcej serc!"
		"life":
			Game.gain_life()
			_note.text = "+1 życie"
		"catnip":
			if cat:
				cat.eat_catnip()
			_note.text = "Mniam."
	_refresh()


func _draw() -> void:
	draw_rect(Rect2(-26, -20, 52, 20), Color(0.52, 0.34, 0.2))          # counter
	draw_rect(Rect2(-26, -20, 52, 3), Color(0.68, 0.48, 0.3))
	draw_rect(Rect2(-24, -46, 2, 26), Color(0.4, 0.26, 0.15))           # posts
	draw_rect(Rect2(22, -46, 2, 26), Color(0.4, 0.26, 0.15))
	for i in 7:                                                          # striped awning
		draw_rect(Rect2(-28 + i * 8, -52, 8, 8), Color(0.85, 0.2, 0.2) if i % 2 == 0 else Color(0.95, 0.92, 0.85))
	draw_circle(Vector2(-14, -24), 3.0, Color(1, 0.85, 0.2))             # coins on the counter
	draw_circle(Vector2(-8, -24), 3.0, Color(1, 0.85, 0.2))
	draw_rect(Rect2(6, -27, 10, 7), Color(0.3, 0.7, 0.35))               # a catnip pot
