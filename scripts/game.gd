extends Node

signal message(text: String)  # empty text hides the message
signal hp_changed(hp: int, max_hp: int)  # cat health bar
signal hint(text: String)  # tip in the dialog box at the bottom, fades on its own
signal pickups_changed  # coin collected or life gained: the HUD redraws its counters
signal level_done(stats: Dictionary)  # end-of-level board: counts and grade
signal device_changed  # the player switched between keyboard and pad: on-screen key names change

const START_LIVES := 3
const MENU := "res://scenes/ui/main_menu.tscn"
const VICTORY := "res://scenes/ui/victory.tscn"
const COINS_PER_LEVEL := 10
const DIAMONDS_PER_LEVEL := 4
const LIVES_PER_LEVEL := 2  # 1ups hidden in each level
const LEVELS := ["res://scenes/level/level_01.tscn", "res://scenes/level/level_02.tscn", "res://scenes/level/level_03.tscn"]

var lives := START_LIVES
# dev menu toggles (persist across level reloads)
var god_mode := false
var fly_mode := false
var volume := {"Music": 8, "SFX": 8}  # bus -> 0..10 (OPCJE > MUZYKA / EFEKTY), 0 = muted
const LANGUAGES := ["pl", "en", "es"]  # Polish texts are the translation keys (assets/i18n/strings.csv)
const LANGUAGE_NAMES := {"pl": "POLSKI", "en": "ENGLISH", "es": "ESPAÑOL"}
const SETTINGS := "user://settings.cfg"
const SAVE := "user://save.cfg"  # progress written after each finished level (checkpoints are not saved)
var checkpoint := Vector2.INF  # respawn point in the current level; INF = level start
var collected := {}  # level index -> names of the coins / 1ups taken there (they stay taken after a lost life)
var run_time := 0.0  # seconds spent in levels this game, for the victory screen
var killed := {}  # level index -> names of the enemies killed there
var enemies := {}  # level index -> how many enemies the level has

const AUDIO := "res://assets/game/audio/%s.wav"
var _players: Array[AudioStreamPlayer] = []
var _music := AudioStreamPlayer.new()
var _music_track := ""
var level_index := 0
var pad := false  # last input came from a gamepad: texts name pad buttons instead of keys
var _pad_device := 0  # the pad that sent the last input: it is the one that rumbles
var vibration_on := true  # OPCJE > WIBRACJE
# key names in the (translated) texts -> [keyboard, pad]; the font has ✕ but no ○ or arrows
const KEY_NAMES := {
	"pl": [["Spacja / ✕", "Spacja", "✕"], ["Esc - ", "Esc - ", "O - "], ["wciśnij W", "wciśnij W", "wychyl gałkę w górę"], ["W w górę, S w dół", "W w górę, S w dół", "gałka w górę i w dół"]],
	"en": [["Space / ✕", "Space", "✕"], ["Esc - ", "Esc - ", "O - "], ["Press W", "Press W", "Push the stick up"], ["W up, S down", "W up, S down", "stick up and down"]],
	"es": [["Espacio / ✕", "Espacio", "✕"], ["Esc - ", "Esc - ", "O - "], ["Pulsa W", "Pulsa W", "Empuja el stick arriba"], ["W sube, S baja", "W sube, S baja", "stick arriba y abajo"]],
}
var _on_confirm := Callable()  # set while a message is shown; Space runs it


# Input map in code instead of project.godot: serialized InputEvents there are verbose and fragile to hand-edit.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # must read Space while the game is paused
	for i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		player.bus = "SFX"
		_players.append(player)
	_music.volume_db = -9.0
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(_music.play)  # loop the track
	_fit_window.call_deferred()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	TranslationServer.set_locale(cfg.get_value("game", "language", "pl"))
	for bus in volume:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		set_volume(bus, cfg.get_value("audio", bus, volume[bus]), false)
	vibration_on = cfg.get_value("input", "vibration", true)
	# Pad buttons use Godot's Xbox-style names: A = Cross, B = Circle, X = Square (DualShock 4 / DualSense).
	_bind("left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_bind("right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_bind("up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_bind("down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_bind("jump", [KEY_SPACE], [JOY_BUTTON_A])
	_bind("dash", [KEY_SHIFT], [JOY_BUTTON_B])
	_bind("attack", [KEY_J, KEY_X], [JOY_BUTTON_X])
	_bind("fart", [KEY_K, KEY_C], [JOY_BUTTON_Y])  # Y = Triangle
	_bind("throw", [KEY_L, KEY_V], [JOY_BUTTON_RIGHT_SHOULDER])  # yarn ball: R1
	_bind("fullscreen", [KEY_F, KEY_F11])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])  # Start = Options on a DualShock
	_bind("dev", [KEY_F1])
	_bind("back", [KEY_BACKSPACE], [JOY_BUTTON_B])  # menus only: B = Circle (in game Circle is dash)


func _input(event: InputEvent) -> void:
	var now := pad
	if event is InputEventKey or event is InputEventMouseButton:
		now = false
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		now = true
		_pad_device = event.device
	if now != pad:
		pad = now
		device_changed.emit()


# pad rumble: weak = fast buzz motor, strong = deep rumble motor (0-1). Only while playing on a pad.
func rumble(weak: float, strong: float, duration: float) -> void:
	if vibration_on and pad:
		Input.start_joy_vibration(_pad_device, weak, strong, duration)


func toggle_vibration() -> void:
	vibration_on = not vibration_on
	_store_setting("input", "vibration", vibration_on)
	rumble(0.3, 0.3, 0.15)  # a taste of it when switched on


# a translated text with the key names of the device in use ("Spacja / ✕" -> "Spacja" or "✕")
func keys(text: String) -> String:
	for k in KEY_NAMES[language()]:
		text = text.replace(k[0], k[2] if pad else k[1])
	return text


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		toggle_fullscreen()
	if _on_confirm.is_valid() and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")):
		var callback := _on_confirm
		_on_confirm = Callable()
		message.emit("")
		get_tree().paused = false
		callback.call()


func lose_life() -> void:
	lives -= 1
	if lives > 0:
		sfx("lose_life", 0.0)
		rumble(0.6, 1.0, 0.5)
		get_tree().reload_current_scene.call_deferred()
	else:
		sfx("game_over", 0.0)
		rumble(0.5, 1.0, 0.8)
		_show("GAME OVER\n" + tr("Spacja / ✕ - od nowa"), _restart)


func level_complete() -> void:
	var stats := level_stats(level_index)
	level_index += 1
	sfx("level_complete", 0.0)
	rumble(0.3, 0.6, 0.4)
	get_tree().paused = true
	level_done.emit(stats)
	if level_index < LEVELS.size():
		_save()
	else:
		DirAccess.remove_absolute(SAVE)  # game finished: the next one starts from scratch
	_on_confirm = _load_level if level_index < LEVELS.size() else func(): get_tree().change_scene_to_file(VICTORY)


# Grade: the share of pickups taken (coins, 1ups, diamonds); kills are shown on the summary but not graded.
# S from 95 %, then a step down every 10 %.
func level_stats(level: int) -> Dictionary:
	var items: Array = collected.get(level, [])
	var c := items.filter(func(i): return i.begins_with("Coin")).size()
	var l := items.filter(func(i): return i.begins_with("Life")).size()
	var d := items.filter(func(i): return i.begins_with("Diamond")).size()
	var pickups := float(c + l + d) / (COINS_PER_LEVEL + LIVES_PER_LEVEL + DIAMONDS_PER_LEVEL)
	var total: int = enemies.get(level, 0)
	var k := mini(killed.get(level, []).size(), total)
	var score := pickups * 100.0
	var grade := "S" if score >= 95 else "A" if score >= 85 else "B" if score >= 75 else "C" if score >= 65 else "D"
	return {"level": level, "coins": c, "lives": l, "diamonds": d, "kills": k, "enemies": total, "score": score, "grade": grade}


func enemy_killed(enemy: String) -> void:
	if not killed.has(level_index):
		killed[level_index] = []
	rumble(0.3, 0.5, 0.15)
	if not killed[level_index].has(enemy):  # enemies come back after a lost life: count each one once
		killed[level_index].append(enemy)


func is_collected(item: String) -> bool:
	return collected.get(level_index, []).has(item)


func collect(item: String) -> void:
	if not collected.has(level_index):
		collected[level_index] = []
	collected[level_index].append(item)
	pickups_changed.emit()


func coins(level := -1, prefix := "Coin") -> int:  # coins (or other pickups) taken in one level, or in all of them
	var n := 0
	for i in collected:
		if level < 0 or i == level:
			n += collected[i].filter(func(item): return item.begins_with(prefix)).size()
	return n


func gain_life() -> void:
	lives += 1
	sfx("oneup", 0.0)
	rumble(0.3, 0.3, 0.08)  # a double pulse
	get_tree().create_timer(0.16).timeout.connect(rumble.bind(0.3, 0.3, 0.08))
	pickups_changed.emit()


func _show(text: String, callback: Callable) -> void:
	get_tree().paused = true
	message.emit(text)
	_on_confirm = callback


# one-shot sound effect; slight random pitch so repeats don't sound identical
func sfx(sound: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	var player := _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = load(AUDIO % sound)  # load() caches
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.volume_db = volume_db
	player.play()


func play_music(track: String) -> void:
	if track == _music_track and _music.playing:
		return
	_music_track = track
	var path := AUDIO % ("music_" + track)
	var mp3 := path.get_basename() + ".mp3"  # full-length tracks come as mp3, generated chiptunes as wav
	_music.stream = load(mp3 if ResourceLoader.exists(mp3) else path)
	_music.play()


func set_volume(bus: String, value: int, store := true) -> void:
	volume[bus] = clampi(value, 0, 10)
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(i, linear_to_db(volume[bus] / 10.0))
	AudioServer.set_bus_mute(i, volume[bus] == 0)
	if store:
		_store_setting("audio", bus, volume[bus])


func message_open() -> bool:
	return _on_confirm.is_valid()


# The game renders at 320x180 and scales by whole numbers. The window takes the largest multiple that fits ~90%
# of the screen (sizes are physical pixels: on a Retina Mac 1920x1080 px is only half the screen), centred.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless" or DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	if Engine.is_embedded_in_editor():  # the editor's Game tab owns the window size
		return
	var usable := DisplayServer.screen_get_usable_rect()
	var k := mini(int(usable.size.x * 0.9) / 320, int(usable.size.y * 0.9) / 180)
	var size := Vector2i(320, 180) * maxi(k, 1)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)


func language() -> String:
	var lang := TranslationServer.get_locale().substr(0, 2)
	return lang if LANGUAGES.has(lang) else "pl"


func next_language() -> void:  # options menus cycle POLSKI -> ENGLISH -> ESPAÑOL; remembered between runs
	var lang: String = LANGUAGES[(LANGUAGES.find(language()) + 1) % LANGUAGES.size()]
	TranslationServer.set_locale(lang)
	_store_setting("game", "language", lang)


func _store_setting(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS)


func toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func load_level(index: int) -> void:
	get_tree().paused = false
	level_index = index
	collected.erase(index)  # jumping to a level replays it from scratch
	killed.erase(index)
	_load_level()


func start_game() -> void:
	_restart()


func saved_level() -> int:  # level the save continues from, -1 = no save
	var cfg := ConfigFile.new()
	return cfg.get_value("save", "level_index", -1) if cfg.load(SAVE) == OK else -1


func continue_game() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	for key in SAVED:
		set(key, cfg.get_value("save", key, get(key)))
	_load_level()


const SAVED := ["level_index", "lives", "collected", "killed", "enemies", "run_time"]


func _save() -> void:
	var cfg := ConfigFile.new()
	for key in SAVED:
		cfg.set_value("save", key, get(key))
	cfg.save(SAVE)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


func _restart() -> void:
	lives = START_LIVES
	level_index = 0
	collected.clear()
	killed.clear()
	run_time = 0.0
	DirAccess.remove_absolute(SAVE)  # new game or game over: the old progress is gone
	_load_level()


func _load_level() -> void:
	checkpoint = Vector2.INF  # a new level (or a restart) starts at its beginning
	get_tree().change_scene_to_file(LEVELS[level_index])


func _bind(action: StringName, keys: Array, buttons: Array = [], axis := -1, axis_dir := 0.0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		ev.device = -1  # any connected pad
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axis
		ev.axis_value = axis_dir
		ev.device = -1
		InputMap.action_add_event(action, ev)
