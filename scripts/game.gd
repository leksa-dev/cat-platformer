extends Node

signal message(text: String)  # empty text hides the message
signal hp_changed(hp: int, max_hp: int)  # cat health bar

const START_LIVES := 3
const MENU := "res://scenes/ui/main_menu.tscn"
const LEVELS := ["res://scenes/level/level_01.tscn", "res://scenes/level/level_02.tscn"]

var lives := START_LIVES
# dev menu toggles (persist across level reloads)
var god_mode := false
var fly_mode := false
var music_on := false  # off by default; OPCJE > MUZYKA turns it on
var checkpoint := Vector2.INF  # respawn point in the current level; INF = level start

const AUDIO := "res://assets/game/audio/%s.wav"
var _players: Array[AudioStreamPlayer] = []
var _music := AudioStreamPlayer.new()
var _music_track := ""
var level_index := 0
var _on_confirm := Callable()  # set while a message is shown; Space runs it


# Input map in code instead of project.godot: serialized InputEvents there are verbose and fragile to hand-edit.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # must read Space while the game is paused
	for i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music.volume_db = -9.0
	add_child(_music)
	_music.finished.connect(_music.play)  # loop the track
	_fit_window.call_deferred()
	# Pad buttons use Godot's Xbox-style names: A = Cross, B = Circle, X = Square (DualShock 4 / DualSense).
	_bind("left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_bind("right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_bind("up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_bind("down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_bind("jump", [KEY_SPACE], [JOY_BUTTON_A])
	_bind("dash", [KEY_SHIFT], [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER])
	_bind("attack", [KEY_J, KEY_X], [JOY_BUTTON_X])
	_bind("fart", [KEY_K, KEY_C], [JOY_BUTTON_Y])  # Y = Triangle
	_bind("fullscreen", [KEY_F, KEY_F11])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])  # Start = Options on a DualShock
	_bind("dev", [KEY_F1])
	_bind("back", [KEY_BACKSPACE], [JOY_BUTTON_B])  # menus only: B = Circle (in game Circle is dash)


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
		get_tree().reload_current_scene.call_deferred()
	else:
		sfx("game_over", 0.0)
		_show("GAME OVER\nSpacja / ✕ - od nowa", _restart)


func level_complete() -> void:
	level_index += 1
	sfx("level_complete", 0.0)
	if level_index < LEVELS.size():
		_show("Poziom ukończony!\nSpacja / ✕ - dalej", _load_level)
	else:
		_show("Wygrana!\nSpacja / ✕ - menu", go_to_menu)


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
	_music.stream = load(AUDIO % ("music_" + track))
	if music_on:
		_music.play()


func toggle_music() -> void:
	music_on = not music_on
	if music_on and _music.stream:
		_music.play()
	else:
		_music.stop()


func message_open() -> bool:
	return _on_confirm.is_valid()


# The game renders at 320x180 and scales by whole numbers. The window takes the largest multiple that fits ~90%
# of the screen (sizes are physical pixels: on a Retina Mac 1920x1080 px is only half the screen), centred.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless" or DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var usable := DisplayServer.screen_get_usable_rect()
	var k := mini(int(usable.size.x * 0.9) / 320, int(usable.size.y * 0.9) / 180)
	var size := Vector2i(320, 180) * maxi(k, 1)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)


func toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func load_level(index: int) -> void:
	get_tree().paused = false
	level_index = index
	_load_level()


func start_game() -> void:
	_restart()


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


func _restart() -> void:
	lives = START_LIVES
	level_index = 0
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
