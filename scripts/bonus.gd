extends Area2D

signal collected(value)
var value = 50  # Bonus value is higher than regular treasure
var sound_player = null

func _ready():
	add_to_group("bonuses")
	body_entered.connect(_on_body_entered)
	
	# Create audio player for sound effects
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	
	# Load the appropriate sound
	var sound = load("res://assets/sounds/bonus.wav")
	sound_player.stream = sound
	sound_player.volume_db = -8.0  # Adjust as needed

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Play sound
		sound_player.play()
		
		# Update global score
		if has_node("/root/Global"):
			Global.add_score(value)
		
		# Emit signal for level tracking
		collected.emit(value)
		
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
		queue_free()  # Remove the bonus once timer finishes
