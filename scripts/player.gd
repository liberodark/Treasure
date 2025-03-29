extends CharacterBody2D

# Grid-based movement configuration
var grid_size = 32  # Cell size in pixels
var speed = 3      # Cells per second
var input_direction = Vector2.ZERO
var target_position = Vector2.ZERO
var is_moving = false
var collision_area = null

# Called when the node enters the scene tree
func _ready():
	target_position = position
	add_to_group("player")
	$CollisionShape2D.shape.size = Vector2(30, 30)
	
	# Create an Area2D for collision detection
	collision_area = Area2D.new()
	collision_area.name = "CollisionDetector"
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = $CollisionShape2D.shape.duplicate()
	collision_area.add_child(collision_shape)
	add_child(collision_area)
	
	# Connect signals from the Area2D
	collision_area.area_entered.connect(_on_area_entered)
	collision_area.body_entered.connect(_on_body_entered)
	
	print("Player ready, collision detector setup")

# Input handling and movement
func _physics_process(delta):
	# If the player is not moving, check for input
	if not is_moving:
		# Input detection
		input_direction = Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			input_direction = Vector2.RIGHT
			$AnimatedSprite2D.play("right")
		elif Input.is_action_pressed("ui_left"):
			input_direction = Vector2.LEFT
			$AnimatedSprite2D.play("left")
		elif Input.is_action_pressed("ui_down"):
			input_direction = Vector2.DOWN
			$AnimatedSprite2D.play("down")
		elif Input.is_action_pressed("ui_up"):
			input_direction = Vector2.UP
			$AnimatedSprite2D.play("up")
		
		# If we have a direction, calculate the target position
		if input_direction != Vector2.ZERO:
			# Convert the target position to the cell center
			target_position = position + input_direction * grid_size
			is_moving = true
	
	# If the player is moving
	if is_moving:
		# Calculate the vector to the target
		var move_vector = target_position - position
		var movement_length = move_vector.length()
		
		# If we're almost at the destination
		if movement_length < 1:
			# Snap to the exact position and stop
			position = target_position
			is_moving = false
		else:
			# Otherwise, continue moving
			var move_speed = speed * grid_size * delta
			# Don't exceed the remaining distance
			if movement_length <= move_speed:
				position = target_position
				is_moving = false
			else:
				velocity = move_vector.normalized() * move_speed
				var test_collision = move_and_collide(velocity, true)
				if not test_collision:
					position += velocity
				else:
					is_moving = false
					
					# Check if we collided with a monster
					if test_collision.get_collider() and test_collision.get_collider().is_in_group("monsters"):
						_on_body_entered(test_collision.get_collider())

# Collision handling with Area2D objects
func _on_area_entered(area):
	print("Area entered: ", area.name)
	if area.is_in_group("treasures"):
		# Treasure collision is handled by the treasure itself
		pass
	
# Collision handling with CharacterBody2D objects (like monsters)
func _on_body_entered(body):
	print("Body entered: ", body.name)
	if body.is_in_group("monsters"):
		print("Monster detected!")
		# Check if monster is afraid
		if "current_state" in body and body.current_state == body.State.AFRAID:
			print("Killing afraid monster")
			# Kill the monster
			body.die()
			
			# Add points for killing a monster
			if has_node("/root/Global"):
				Global.add_score(25)  # 25 points for killing a monster
				
			# Play defeat monster sound
			var defeat_sound = AudioStreamPlayer.new()
			add_child(defeat_sound)
			defeat_sound.stream = load("res://assets/sounds/beeb.wav")
			defeat_sound.volume_db = -5.0
			defeat_sound.play()
			await defeat_sound.finished
			defeat_sound.queue_free()
		else:
			# Monster kills player
			print("Player killed by monster!")
			
			# Lose a life through the global system
			if has_node("/root/Global"):
				Global.lose_life()
			
			# Play death sound
			var death_sound = AudioStreamPlayer.new()
			add_child(death_sound)
			death_sound.stream = load("res://assets/sounds/dead.wav")
			death_sound.volume_db = -5.0
			death_sound.play()
			
			# Disable player controls
			set_physics_process(false)
			
			# Make player flash and disappear
			for i in range(3):
				visible = false
				await get_tree().create_timer(0.1).timeout
				visible = true
				await get_tree().create_timer(0.1).timeout
			
			# Wait for sound to finish before potentially restarting level
			await death_sound.finished
			death_sound.queue_free()
