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


# sets the text, shrinking the font just enough for a long one ("WIBRACJE: TAK", Spanish...) to fit its plank
func fit_text(label: Label, text: String) -> void:
	if not label.has_meta("plank_width"):  # a too long text widens the label past the plank: remember the real width
		label.set_meta("plank_width", label.size.x)
		label.set_meta("base_size", label.get_theme_font_size("font_size"))  # the scene's own size, before any shrinking
	var room: float = label.get_meta("plank_width")
	var size: int = label.get_meta("base_size")
	label.add_theme_font_size_override("font_size", size)
	label.text = text
	while size > 9 and label.get_minimum_size().x > room - 8:  # the label's own measure; 4 px clear of the plank's edges
		size -= 1
		label.add_theme_font_size_override("font_size", size)
	label.size.x = room


func volume_text(bus: String) -> String:
	return (tr("MUZYKA") if bus == "Music" else tr("EFEKTY")) + ": %d%%" % (Game.volume[bus] * 10)


# left/right on a volume row: one step of 10 %; returns true when it changed something
func nudge_volume(bus: String) -> bool:
	var step := int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left"))
	if step == 0 or Game.volume[bus] + step < 0 or Game.volume[bus] + step > 10:
		return false
	Game.set_volume(bus, Game.volume[bus] + step)
	Game.sfx("menu_move", 0.0)
	return true


func fullscreen_text() -> String:
	return tr("PEŁNY EKRAN") if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else tr("OKNO")  # longer labels overflow the plank


func vibration_text() -> String:
	return tr("WIBRACJE") + ": " + tr("TAK" if Game.vibration_on else "NIE")


func language_text() -> String:
	return Game.LANGUAGE_NAMES[Game.language()]
