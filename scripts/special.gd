class_name Special
extends Area2D
## Special power-up that makes monsters afraid of the player.
##
## When collected, this item makes all monsters in the scene afraid for
## a limited time, allowing the player to defeat them.

## Emitted when the special item is collected
signal collected

## How long monsters will be scared (in seconds)
@export var scared_duration: float = 10.0
## Path to the sound effect played when collected
const BEEP_SOUND_PATH: String = "res://assets/sounds/bonus.ogg"

## Sound player for effects
var sound_player: AudioStreamPlayer = null

func _ready() -> void:
	add_to_group("specials")
	
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
	# Create audio player for sound effects
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	
	if ResourceLoader.exists(BEEP_SOUND_PATH):
		sound_player.stream = load(BEEP_SOUND_PATH)
		sound_player.volume_db = -8.0

## Handle player collecting the special item
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	# Play collection sound
	if sound_player and sound_player.stream:
		sound_player.play()
	
	# Make all monsters afraid
	scare_monsters()
	
	# Emit collection signal
	collected.emit()
	
	# Hide the item immediately but keep sound playing
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Remove the item after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

## Make all monsters in the scene afraid of the player
func scare_monsters() -> void:
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		if monster.has_method("make_afraid"):
			monster.make_afraid()
	
	# Create a visual flash effect
	_create_flash_effect()

## Create a screen flash effect to indicate power activation
func _create_flash_effect() -> void:
	var screen_flash = ColorRect.new()
	screen_flash.color = Color(1, 1, 1, 0.3)
	screen_flash.anchors_preset = Control.PRESET_FULL_RECT
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(screen_flash)
	
	# Animate flash fade-out
	var tween = create_tween()
	tween.tween_property(screen_flash, "color", Color(1, 1, 1, 0), 0.5)
	
	# Remove canvas layer after animation
	await tween.finished
	canvas_layer.queue_free()
