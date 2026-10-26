extends Control
# Vertical text menu: up/down moves, Space/Enter/✕ chooses. Subclasses fill `items` and react to `chosen`.

signal chosen(index: int)

const DIM := Color(0.62, 0.52, 0.42)

var items: Array[Label] = []
var selected := 0

@onready var arrow: TextureRect = get_node_or_null("Arrow")


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or items.is_empty():
		return
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		Game.sfx("menu_move", 0.0)
		select(selected - 1)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		Game.sfx("menu_move", 0.0)
		select(selected + 1)
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		Game.sfx("menu_select", 0.0)
		chosen.emit(selected)


func select(index: int) -> void:
	selected = wrapi(index, 0, items.size())
	for i in items.size():
		items[i].modulate = Color.WHITE if i == selected else DIM
	if arrow:
		var label := items[selected]
		var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		arrow.position = label.position + Vector2((label.size.x - width) / 2 - arrow.size.x - 4, (label.size.y - arrow.size.y) / 2)
	_on_select(selected)


func _on_select(_index: int) -> void:
	pass


func music_text() -> String:
	return "MUZYKA: TAK" if Game.music_on else "MUZYKA: NIE"


func fullscreen_text() -> String:
	return "PEŁNY EKRAN" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "OKNO"  # longer labels overflow the plank
