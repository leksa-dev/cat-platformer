extends Node2D
# Sign in the world (test level, hints): `text` on a dark plate, bottom-centre at the node. `width` is the plate width in px.

@export_multiline var text := ""
@export var width := 120.0
@export var title := false  # bigger, for a station name


func _ready() -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(width - 8, 0)
	label.size = Vector2(width - 8, 0)
	label.add_theme_font_size_override("font_size", 10 if title else 8)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.5) if title else Color(0.95, 0.95, 0.95))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	await get_tree().process_frame
	var h := label.get_combined_minimum_size().y + 6.0
	var plate := ColorRect.new()
	plate.color = Color(0.1, 0.11, 0.15, 0.82)
	plate.size = Vector2(width, h)
	plate.position = Vector2(-width / 2, -h)
	plate.z_index = -1
	add_child(plate)
	label.position = Vector2(-width / 2 + 4, -h + 3)
