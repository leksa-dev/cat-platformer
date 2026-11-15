extends Node
# Quest build: when an OpenXR headset is running, the whole game is drawn into a SubViewport (1280x720, the game's 320x180 at 4x)
# that hangs in front of the player like a cinema screen. Levels are loaded into that viewport (Game.goto / Game.scene).
# BACKGROUND off (OPCJE > TŁO) = AR: the room is shown through the headset cameras and only the game floats in it.
# On a desktop (no headset) initialize() fails and nothing here does anything.
signal passthrough_changed

const SCREEN_SIZE := Vector2(3.2, 1.8)  # metres, 16:9
const SCREEN_DISTANCE := 3.0
const DEAD := 0.35  # thumbstick dead zone

var active := false
var content: Node  # the current game scene (menu or level) inside the screen's viewport
var path := ""
var _xr: XRInterface
var _sub: SubViewport
var _env: Environment
var _screen: MeshInstance3D
var _cam: XRCamera3D


func _ready() -> void:
	_setup.call_deferred()  # the Game autoload comes after this one: wait until it exists


func _setup() -> void:
	_xr = XRServer.find_interface("OpenXR")
	if _xr == null or not (_xr.is_initialized() or _xr.initialize()):
		return
	active = true
	var root := get_tree().root
	root.use_xr = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)  # the headset sets the pace
	_sub = SubViewport.new()
	_sub.size = Vector2i(1280, 720)
	_sub.size_2d_override = Vector2i(320, 180)
	_sub.size_2d_override_stretch = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub)
	var origin := XROrigin3D.new()
	add_child(origin)
	_cam = XRCamera3D.new()
	origin.add_child(_cam)
	for hand in ["left_hand", "right_hand"]:
		var c := XRController3D.new()
		c.tracker = hand
		c.button_pressed.connect(_button.bind(hand, true))
		c.button_released.connect(_button.bind(hand, false))
		c.input_vector2_changed.connect(_stick.bind(hand))
		origin.add_child(c)
	var screen := MeshInstance3D.new()
	_screen = screen
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	screen.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _sub.get_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	screen.material_override = mat
	add_child(screen)
	for sig in ["session_focussed", "pose_recentered"]:  # the tracking space starts at an arbitrary heading: put the screen where the player looks
		if _xr.has_signal(sig):
			_xr.connect(sig, _place_screen_soon)
	_place_screen_soon()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	Game.background_changed.connect(_apply_passthrough)
	_apply_passthrough()
	_adopt_first_scene.call_deferred()


func _place_screen_soon() -> void:
	for delay in [0.2, 1.0]:  # the head pose is not valid right at the start
		get_tree().create_timer(delay).timeout.connect(_place_screen)


# straight ahead of where the headset points now, at eye height, facing the player
func _place_screen() -> void:
	var head := _cam.global_transform
	var forward := -head.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	_screen.global_position = head.origin + forward.normalized() * SCREEN_DISTANCE
	_screen.look_at(head.origin, Vector3.UP, true)


# the engine already put the main scene (title screen) under the root; move it into the screen
func _adopt_first_scene() -> void:
	await get_tree().process_frame
	var scene := get_tree().current_scene
	if scene == null:
		return
	path = scene.scene_file_path
	scene.get_parent().remove_child(scene)
	_sub.add_child(scene)
	content = scene


func load_scene(scene_path: String) -> void:
	if content:
		_sub.remove_child(content)  # out of the tree now, so the new scene keeps its name
		content.queue_free()
	path = scene_path
	content = load(scene_path).instantiate()
	_sub.add_child(content)


func _input(event: InputEvent) -> void:
	if active:
		_sub.push_input(event, true)  # nodes inside the SubViewport get the keys / pad too


func _apply_passthrough() -> void:
	var ar: bool = not Game.show_background
	print("Vr: want AR=", ar, " passthrough supported=", _xr.is_passthrough_supported(), " blend modes=", _xr.get_supported_environment_blend_modes())
	if ar and _xr.is_passthrough_supported():
		ar = _xr.start_passthrough()
		print("Vr: start_passthrough -> ", ar, " enabled=", _xr.is_passthrough_enabled())
	elif ar and _xr.get_supported_environment_blend_modes().has(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND):
		_xr.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
	else:
		if _xr.is_passthrough_enabled():
			_xr.stop_passthrough()
		_xr.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		ar = false
	print("Vr: passthrough=", ar, " supported=", _xr.is_passthrough_supported(), " blend modes=", _xr.get_supported_environment_blend_modes())
	get_tree().root.transparent_bg = ar
	_sub.transparent_bg = ar
	_env.background_color = Color(0, 0, 0, 0) if ar else Color(0.03, 0.04, 0.07)
	passthrough_changed.emit()


# Touch controllers -> the game's own actions (the pad mapping in game.gd stays as it is)
const BUTTONS := {
	"right_hand": {"ax_button": ["jump"], "by_button": ["dash", "back"], "trigger_click": ["throw"], "grip_click": ["attack"]},
	"left_hand": {"ax_button": ["attack"], "by_button": ["fart"], "menu_button": ["pause"], "grip_click": ["fart"]},
}


func _button(button: String, hand: String, pressed: bool) -> void:
	for action in BUTTONS[hand].get(button, []):
		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)


func _stick(button: String, value: Vector2, hand: String) -> void:
	if hand != "left_hand" or button != "primary":
		return
	_axis("left", maxf(-value.x, 0.0))
	_axis("right", maxf(value.x, 0.0))
	_axis("up", maxf(value.y, 0.0))
	_axis("down", maxf(-value.y, 0.0))


func _axis(action: String, strength: float) -> void:
	if strength > DEAD:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
