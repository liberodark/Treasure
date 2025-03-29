class_name Warp
extends Area2D
## Teleportation point that moves the player to another location.
##
## When the player enters a warp point, they will be instantly
## teleported to the linked destination warp point.

## Emitted when the player uses this warp
signal used(by_player)

## ID of this warp point (must match with destination's target_warp_id)
@export var warp_id: int = 0

## ID of the destination warp point
@export var target_warp_id: int = 0

## How long to wait before the player can move after teleporting (in seconds)
@export var cooldown_duration: float = 0.5

## Path to the sound effect played when warping
const WARP_SOUND_PATH: String = "res://assets/sounds/beeb.ogg"

## Sound player for effects
var sound_player: AudioStreamPlayer = null
## Flag to prevent warp feedback loops
var is_active: bool = true

func _ready() -> void:
	add_to_group("warps")

	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

	# Create audio player for sound effects
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)

	if ResourceLoader.exists(WARP_SOUND_PATH):
		sound_player.stream = load(WARP_SOUND_PATH)
		sound_player.volume_db = -5.0

## Handle player entering the warp area
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not is_active:
		return

	# Find destination warp point
	var destination = _find_destination_warp()
	if not destination:
		push_warning("Warp destination with ID %d not found!" % target_warp_id)
		return

	# Temporarily disable the destination warp to prevent loops
	destination.is_active = false

	# Play warp sound
	if sound_player and sound_player.stream:
		sound_player.play()

	# Emit signal that warp was used
	used.emit(body)

	# Create a brief flash effect
	_create_flash_effect()

	# Calculate grid-aligned position for the destination
	var aligned_position = Vector2(
		round(destination.position.x / Global.GRID_SIZE) * Global.GRID_SIZE,
		round(destination.position.y / Global.GRID_SIZE) * Global.GRID_SIZE
	)

	# Teleport player to destination warp
	if body is Player:
		# Disable player movement during teleportation
		body.set_physics_process(false)

		# Move player to destination
		body.position = aligned_position
		body.target_position = aligned_position

		# Give player a moment to orient themselves
		await get_tree().create_timer(cooldown_duration).timeout

		# Re-enable player movement
		body.set_physics_process(true)

		# Re-enable destination warp after a brief delay
		await get_tree().create_timer(0.2).timeout
		destination.is_active = true

## Find the destination warp point with the matching target_warp_id
func _find_destination_warp() -> Warp:
	var warps = get_tree().get_nodes_in_group("warps")
	for warp in warps:
		if warp != self and warp.warp_id == target_warp_id:
			return warp
	return null

## Create a visual flash effect for the teleportation
func _create_flash_effect() -> void:
	var screen_flash = ColorRect.new()
	screen_flash.color = Color(0.5, 0.9, 1.0, 0.3)  # Light blue flash
	screen_flash.anchors_preset = Control.PRESET_FULL_RECT

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(screen_flash)

	# Animate flash fade-out
	var tween = create_tween()
	tween.tween_property(screen_flash, "color", Color(0.5, 0.9, 1.0, 0), 0.4)

	# Remove canvas layer after animation
	await tween.finished
	canvas_layer.queue_free()
