extends Node
## Manages input device detection and UI adjustments
##
## Detects the active input device and shows/hides the mouse cursor accordingly.

# Input detection settings
@export var input_switch_delay: float = 1.0  # Delay before switching input modes to prevent flickering

# State tracking
var using_gamepad: bool = false
var gamepad_activity_timer: float = 0.0
var keyboard_mouse_activity_timer: float = 0.0
var debug_mode: bool = false

func _ready() -> void:
	# Handle connected gamepads
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	# Set initial state based on connected controllers
	var connected_joypads = Input.get_connected_joypads()
	if connected_joypads.size() > 0:
		_set_gamepad_mode(true)
	else:
		_set_gamepad_mode(false)

func _process(delta: float) -> void:
	# Update activity timers
	if gamepad_activity_timer > 0:
		gamepad_activity_timer -= delta
		
	if keyboard_mouse_activity_timer > 0:
		keyboard_mouse_activity_timer -= delta
	
	# Process input to detect active device
	_detect_active_input_device()

func _input(event: InputEvent) -> void:
	# Check for keyboard/mouse activity
	if event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		if debug_mode:
			print("Keyboard or mouse activity detected")
		keyboard_mouse_activity_timer = input_switch_delay
		
		if using_gamepad and keyboard_mouse_activity_timer > 0:
			_set_gamepad_mode(false)
			
	# Check for gamepad activity
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Only trigger for significant joystick motion
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.3:
			return
			
		if debug_mode:
			print("Gamepad activity detected")
		gamepad_activity_timer = input_switch_delay
		
		if not using_gamepad and gamepad_activity_timer > 0:
			_set_gamepad_mode(true)

## Called when a joypad is connected or disconnected
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if debug_mode:
		print("Joypad connection changed: device ", device_id, " connected: ", connected)
	
	# If a joypad was connected and we're not in gamepad mode, switch to it
	if connected and not using_gamepad:
		_set_gamepad_mode(true)
	
	# If a joypad was disconnected, check if there are any gamepads still connected
	elif not connected and using_gamepad:
		var connected_joypads = Input.get_connected_joypads()
		if connected_joypads.size() == 0:
			_set_gamepad_mode(false)

## Detects which input device is active based on recent activity
func _detect_active_input_device() -> void:
	# Switch to keyboard/mouse if it's active and we're using gamepad
	if keyboard_mouse_activity_timer > 0 and using_gamepad:
		_set_gamepad_mode(false)
	
	# Switch to gamepad if it's active and we're not using gamepad
	elif gamepad_activity_timer > 0 and not using_gamepad:
		_set_gamepad_mode(true)

## Sets the input mode and updates cursor visibility
func _set_gamepad_mode(gamepad_active: bool) -> void:
	if gamepad_active == using_gamepad:
		return
	
	using_gamepad = gamepad_active
	
	if using_gamepad:
		# Hide cursor when using gamepad
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		if debug_mode:
			print("Input mode: GAMEPAD - cursor hidden")
	else:
		# Show cursor when using keyboard/mouse
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if debug_mode:
			print("Input mode: KEYBOARD/MOUSE - cursor visible")

## Enables or disables debug output
func set_debug(enabled: bool) -> void:
	debug_mode = enabled
