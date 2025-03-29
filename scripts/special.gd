extends Area2D

signal collected
var sound_player = null
var scared_duration = 10.0  # Time in seconds monsters will be scared

func _ready():
	add_to_group("specials")
	body_entered.connect(_on_body_entered)
	
	# Create audio player for sound effects
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	
	# Load the appropriate sound
	var sound = load("res://assets/sounds/beeb.wav")
	sound_player.stream = sound
	sound_player.volume_db = -8.0  # Adjust as needed

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Play sound
		sound_player.play()
		
		# Make all monsters afraid
		scare_monsters()
		
		# Emit signal for level tracking
		collected.emit()
		
		# Hide the sprite immediately
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Create a timer to remove the node after sound finishes
		var timer = Timer.new()
		timer.wait_time = 1.0  # just enough time for the sound
		timer.one_shot = true
		add_child(timer)
		timer.start()
		await timer.timeout
		queue_free()  # Remove the special once timer finishes

func scare_monsters():
	# Find all monsters in the scene and make them afraid
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		if monster.has_method("make_afraid"):
			monster.make_afraid()
			
	# Add visual effect to indicate monsters are scared (optional)
	var screen_flash = ColorRect.new()
	screen_flash.color = Color(1, 1, 1, 0.3)  # Semi-transparent white
	screen_flash.anchors_preset = Control.PRESET_FULL_RECT
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Make sure it's on top
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(screen_flash)
	
	# Create a tween for the flash effect
	var tween = create_tween()
	tween.tween_property(screen_flash, "color", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	
	canvas_layer.queue_free()  # Remove the flash effect
