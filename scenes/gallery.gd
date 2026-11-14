extends Node2D
# Asset gallery ("storybook"): every PNG under res://assets/game laid out in bands by folder, each with its file name, size and whether
# any scene or script uses it (green = used, orange = unused). The cat flies (god mode + noclip) over it, zoom with L1 + right stick
# (or = / -). PageDown / PageUp (or Q / E) jump to the next / previous band. Open it from the dev menu (GALERIA ASSETÓW) or run
# `godot --path . scenes/gallery.tscn`.
# Sprites are drawn at 1/3 (the size they have in the game: the art is made at 3x), bigger images are shrunk to fit and say so.

const ROOT := "res://assets/game"
const ROW_W := 3000.0
const MAX_SHOW := 700.0
const USED := Color(0.62, 1.0, 0.62)
const UNUSED := Color(1.0, 0.68, 0.35)

var bands := []   # {name, y0, y1, x0}
var _cat: CharacterBody2D
var _info: Label
var _usage_text := ""


func level_objects() -> Array:   # the dev menu asks every level for this
	return []


func _ready() -> void:
	Game.god_mode = true
	Game.fly_mode = true   # set directly: not saved to the settings
	_usage_text = _read_sources()
	_build()
	_cat = load("res://scenes/player/cat.tscn").instantiate()
	_cat.position = Vector2(120, -80)
	add_child(_cat)
	var hud: Node = load("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var layer := CanvasLayer.new()
	layer.layer = 5
	_info = Label.new()
	_info.position = Vector2(4, 150)
	_info.add_theme_font_size_override("font_size", 8)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 3)
	layer.add_child(_info)
	add_child(layer)
	RenderingServer.set_default_clear_color(Color(0.12, 0.13, 0.16))


func _process(_delta: float) -> void:
	var here: Variant = _band_at(_cat.global_position)
	_info.text = "%s  |  PgDn/PgUp lub Q/E: następny/poprzedni dział  |  zielone = użyte, pomarańczowe = nieużyte" % (here.name if here != null else "start")
	if Input.is_physical_key_pressed(KEY_PAGEDOWN) or Input.is_physical_key_pressed(KEY_E):
		if not _held:
			_held = true
			_jump(1)
	elif Input.is_physical_key_pressed(KEY_PAGEUP) or Input.is_physical_key_pressed(KEY_Q):
		if not _held:
			_held = true
			_jump(-1)
	else:
		_held = false


var _held := false


func _band_at(p: Vector2) -> Variant:
	for b in bands:
		if p.y >= b.y0 - 60 and p.y < b.y1:
			return b
	return null


func _jump(dir: int) -> void:
	var cur: int = bands.find(_band_at(_cat.global_position))
	var next: int = clampi(cur + dir, 0, bands.size() - 1) if cur >= 0 else 0
	_cat.global_position = Vector2(bands[next].x0 + 60, bands[next].y0 - 20)
	_cat.velocity = Vector2.ZERO
	_cat.get_node("Camera2D").reset_smoothing()


func _read_sources() -> String:
	var text := ""
	for dir in ["res://scenes", "res://scripts"]:
		text += _read_dir(dir)
	return text


func _read_dir(dir: String) -> String:
	var text := ""
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tscn") or f.ends_with(".gd") or f.ends_with(".tres"):
			text += FileAccess.get_file_as_string(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		text += _read_dir(dir + "/" + d)
	return text


func _folders(dir: String, out: Array) -> void:   # every folder with PNGs, in order
	var has := false
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png") or f.ends_with(".png.import"):
			has = true
			break
	if has:
		out.append(dir)
	var subs := Array(DirAccess.get_directories_at(dir))
	subs.sort()
	for d in subs:
		_folders(dir + "/" + d, out)


func _pngs(dir: String) -> Array:
	var list := []
	for f in DirAccess.get_files_at(dir):
		var name := f.trim_suffix(".import")
		if name.ends_with(".png") and not list.has(name):
			list.append(name)
	list.sort()
	return list


func _shown_height(path: String) -> float:
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if tex == null:
		return 0.0
	var size := tex.get_size()
	return size.y * minf(1.0 / 3.0, MAX_SHOW / maxf(size.x, size.y))


func _build() -> void:
	var folders := []
	_folders(ROOT, folders)
	var y := 0.0
	for dir: String in folders:
		var files: Array = _pngs(dir)
		files.sort_custom(func(a, b): return _shown_height(dir + "/" + str(a)) < _shown_height(dir + "/" + str(b)))   # small first, backdrops last
		var title: String = dir.trim_prefix("res://assets/")
		var band: Dictionary = {"name": "", "y0": y, "y1": 0.0, "x0": 40.0}
		var holder := Node2D.new()
		holder.name = title.replace("/", "_")
		add_child(holder)
		var panel := ColorRect.new()
		panel.color = Color(0.2, 0.22, 0.26)
		panel.z_index = -10
		holder.add_child(panel)
		var head := Label.new()
		head.text = "%s   (%d)" % [title, files.size()]
		head.add_theme_font_size_override("font_size", 16)
		head.position = Vector2(20, y + 6)
		holder.add_child(head)
		var x := 40.0
		var row_y := y + 40.0
		var row_h := 0.0
		var used_n := 0
		for f in files:
			var path: String = dir + "/" + str(f)
			var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
			if tex == null:
				continue
			var size := tex.get_size()
			var scale: float = 1.0 / 3.0
			if maxf(size.x, size.y) * scale > MAX_SHOW:
				scale = MAX_SHOW / maxf(size.x, size.y)
			var shown: Vector2 = size * scale
			var cell: float = maxf(shown.x, 100.0) + 14.0
			if x + cell > ROW_W:
				x = 40.0
				row_y += row_h + 30.0
				row_h = 0.0
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.scale = Vector2(scale, scale)
			spr.position = Vector2(x + (cell - 14.0 - shown.x) / 2.0, row_y + 4.0)
			holder.add_child(spr)
			var used := _usage_text.contains(path)
			used_n += 1 if used else 0
			var label := Label.new()
			label.text = "%s\n%dx%d%s" % [f.trim_suffix(".png"), size.x, size.y, "" if scale == 1.0 / 3.0 else " (podgląd x%.2f)" % scale]
			label.add_theme_font_size_override("font_size", 9)
			label.add_theme_color_override("font_color", USED if used else UNUSED)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 2)
			label.position = Vector2(x - 2, row_y + 8.0 + shown.y)
			label.size = Vector2(cell, 24)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.clip_text = false
			holder.add_child(label)
			row_h = maxf(row_h, shown.y + 28.0)
			x += cell
		y = row_y + row_h + 40.0
		band.y1 = y
		band.name = "%s  –  %d plików, użyte: %d" % [title, files.size(), used_n]
		head.text = band.name
		panel.position = Vector2(0, band.y0)
		panel.size = Vector2(ROW_W + 40.0, y - band.y0 - 10.0)
		bands.append(band)
		y += 30.0
