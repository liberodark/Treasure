extends CharacterBody2D

enum State {CHASE, AFRAID, RANDOM}

# Movement configuration
var grid_size = 32
var speed = 2      # Slower than the player
#var speed = 4      # Speed as in the original GameMaker
var current_state = State.CHASE
var target_position = Vector2.ZERO
var is_moving = false
#var is_aligned_with_grid = true
var afraid_timer = 0
var player_ref = null
var move_cooldown = 0
var direction_change_timer = 0

func _ready():
	target_position = position
	add_to_group("monsters")
	# Find the player at startup
	call_deferred("find_player")
	$CollisionShape2D.shape.size = Vector2(30, 30)

	# Ensure collision layer and mask are set correctly
	collision_layer = 1  # Layer the monster is on
	collision_mask = 1   # Layers the monster collides with

	print("Monster ready in state: ", current_state)

func find_player():
	# Wait until all nodes are loaded
	await get_tree().process_frame
	player_ref = get_tree().get_first_node_in_group("player")
	if player_ref:
		print("Player found by monster")
	else:
		print("Player not found by monster")

func _physics_process(delta):
	# Handle timer for "afraid" state
	if current_state == State.AFRAID:
		afraid_timer -= delta
		if afraid_timer <= 0:
			current_state = State.CHASE
			$AnimatedSprite2D.play("normal")

	# Movement cooldown
	if move_cooldown > 0:
		move_cooldown -= delta

	# Timer for periodic direction change
	direction_change_timer -= delta
	if direction_change_timer <= 0 and not is_moving:
		direction_change_timer = 1.0  # Check every second
		adapt_direction()

	# If the monster is not moving, decide the next action
	if not is_moving and move_cooldown <= 0:
		match current_state:
			State.CHASE:
				if player_ref:
					chase_player()
				else:
					move_randomly()
			State.AFRAID:
				flee_from_player()
			State.RANDOM:
				move_randomly()

		# Add a small delay between movements
		move_cooldown = 0.2

	# If the monster is moving
	if is_moving:
		var move_vector = target_position - position
		var movement_length = move_vector.length()

		if movement_length < 1:
			position = target_position
			is_moving = false
		else:
			var move_speed = speed * grid_size * delta
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

func chase_player():
	if player_ref:
		# Simple path calculation to the player
		var direction = Vector2.ZERO

		# Decide whether to move on x or y
		if randi() % 2 == 0:
			# Choose X axis first
			if player_ref.position.x > position.x:
				direction = Vector2.RIGHT
			elif player_ref.position.x < position.x:
				direction = Vector2.LEFT
			else:
				# If same X, move on Y
				if player_ref.position.y > position.y:
					direction = Vector2.DOWN
				else:
					direction = Vector2.UP
		else:
			# Choose Y axis first
			if player_ref.position.y > position.y:
				direction = Vector2.DOWN
			elif player_ref.position.y < position.y:
				direction = Vector2.UP
			else:
				# If same Y, move on X
				if player_ref.position.x > position.x:
					direction = Vector2.RIGHT
				else:
					direction = Vector2.LEFT

		if direction != Vector2.ZERO:
			target_position = position + direction * grid_size
			is_moving = true

func flee_from_player():
	if player_ref:
		# Direction opposite to the player
		var direction = position - player_ref.position
		direction = direction.normalized()

		# Snap to grid (only cardinal movements)
		if abs(direction.x) > abs(direction.y):
			direction.y = 0
			direction.x = sign(direction.x)
		else:
			direction.x = 0
			direction.y = sign(direction.y)

		if direction != Vector2.ZERO:
			target_position = position + direction * grid_size
			is_moving = true
		else:
			move_randomly()

func move_randomly():
	var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	var direction = directions[randi() % directions.size()]
	target_position = position + direction * grid_size
	is_moving = true

func make_afraid():
	current_state = State.AFRAID
	afraid_timer = 10.0  # 10 seconds of afraid state by default
	$AnimatedSprite2D.play("afraid")

# Function to handle monster death
func die():
	# Play death animation if you have one
	if $AnimatedSprite2D.sprite_frames.has_animation("die"):
		$AnimatedSprite2D.play("die")
		await $AnimatedSprite2D.animation_finished

	# Disable collisions and AI
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	# Make monster flash and disappear
	for i in range(2):
		visible = false
		await get_tree().create_timer(0.1).timeout
		visible = true
		await get_tree().create_timer(0.1).timeout

	# Remove the monster
	queue_free()

# Adaptation of the adapt_direction.gml script
func adapt_direction():
	# If the monster is moving vertically (no horizontal movement)
	if velocity.x == 0:
		# With 1/3 probability, try to turn left
		if randf() < 0.33 and is_place_free(Vector2(-grid_size, 0)):
			velocity = Vector2(-speed, 0) * grid_size
		# With 1/3 probability, try to turn right
		elif randf() < 0.33 and is_place_free(Vector2(grid_size, 0)):
			velocity = Vector2(speed, 0) * grid_size
	# If the monster is moving horizontally
	else:
		# With 1/3 probability, try to turn up
		if randf() < 0.33 and is_place_free(Vector2(0, -grid_size)):
			velocity = Vector2(0, -speed) * grid_size
		# With 1/3 probability, try to turn down
		elif randf() < 0.33 and is_place_free(Vector2(0, grid_size)):
			velocity = Vector2(0, speed) * grid_size

	# Update target position based on the new direction
	if velocity != Vector2.ZERO:
		target_position = position + velocity.normalized() * grid_size
		is_moving = true

# Helper function to check if a position is free
# Similar to place_free() in GameMaker
func is_place_free(offset):
	# Create a temporary raycast to check for collision
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, position + offset)
	# Exclude the monster itself from detection
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	# If the ray didn't hit anything, the space is free
	return result.is_empty()
