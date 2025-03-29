class_name Treasure
extends Area2D
## Collectible treasure item that awards points when collected.
##
## When the player collides with a treasure, it emits a signal with its value,
## plays a sound effect, and then removes itself from the game.

## Emitted when collected by the player, with the treasure's value
signal collected(value: int)

## Point value of this treasure
@export var value: int = 10

## Path to the sound effect played when collected
const CATCH_SOUND_PATH: String = "res://assets/sounds/beeb.ogg"

## Sound player for effects
var sound_player: AudioStreamPlayer = null

func _ready() -> void:
	add_to_group("treasures")
	
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)
	
	# Create audio player for sound effects
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	
	if ResourceLoader.exists(CATCH_SOUND_PATH):
		var sound = load(CATCH_SOUND_PATH)
		sound_player.stream = sound
		sound_player.volume_db = -8.0

## Handle player collecting the treasure
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	# Play collection sound
	if sound_player and sound_player.stream:
		sound_player.play()
	
	# Update global score
	if has_node("/root/Global"):
		Global.add_score(value)
	
	# Emit collection signal for level tracking
	collected.emit(value)
	
	# Hide the sprite immediately but keep sound playing
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Create a timer to remove the node after sound finishes
	var timer = get_tree().create_timer(1.0)
	await timer.timeout
	queue_free()
