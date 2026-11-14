extends Camera2D
# Zoom: hold L1 and push the right stick up (closer) or down (farther); L1 + a click of the right stick resets it.
# Keyboard: = closer, - farther, 0 reset. The zoom is kept from level to level (Game.cam_zoom).

@export var min_zoom := 0.5
@export var max_zoom := 2.5
@export var speed := 1.1  # doublings per second at full stick
@export var deadzone := 0.25


func _ready() -> void:
	zoom = Vector2.ONE * Game.cam_zoom


func _process(delta: float) -> void:
	var change := 0.0
	var reset := Input.is_physical_key_pressed(KEY_0)
	for id in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(id, JOY_BUTTON_LEFT_SHOULDER):
			var y := -Input.get_joy_axis(id, JOY_AXIS_RIGHT_Y)  # stick up = closer
			if absf(y) > deadzone:
				change += y
			reset = reset or Input.is_joy_button_pressed(id, JOY_BUTTON_RIGHT_STICK)
	if Input.is_physical_key_pressed(KEY_EQUAL):
		change += 1.0
	if Input.is_physical_key_pressed(KEY_MINUS):
		change -= 1.0
	apply(change, reset, delta)


func apply(change: float, reset: bool, delta: float) -> void:
	if reset:
		Game.cam_zoom = 1.0
	elif change != 0.0:
		Game.cam_zoom = clampf(Game.cam_zoom * pow(2.0, change * speed * delta), min_zoom, max_zoom)
	zoom = zoom.lerp(Vector2.ONE * Game.cam_zoom, 1.0 - exp(-12.0 * delta))  # glides to the target
