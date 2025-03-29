class_name Monster
extends CharacterBody2D
## Monster AI that chases the player in a grid-based game.
##
## Features multiple states (chase, afraid, random) and implements
## grid-based movement similar to the original GameMaker game.

enum State {CHASE, AFRAID, RANDOM}

# Movement configuration
@export var move_speed: float = 2.0
@export var afraid_duration: float = 10.0
@export var direction_change_interval: float = 1.0
@export var move_cooldown_duration: float = 0.2
@export var respawn_time: float = 3.0  # Time before monster respawns

# State variables
var current_state: State = State.CHASE
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var afraid_timer: float = 0.0
var player_ref: Node2D = null
var move_cooldown: float = 0.0
var direction_change_timer: float = 0.0
var last_collision_time: float = 0.0 # Track when last player collision occurred
var original_position: Vector2 = Vector2.ZERO  # Store the original spawn position
var is_dead: bool = false  # Track if monster is "dead" (waiting to respawn)

func _ready() -> void:
	original_position = position  # Store the original position
	target_position = position
	add_to_group("monsters")

	# Set up collision shape
	if has_node("CollisionShape2D"):
		$CollisionShape2D.shape.size = Vector2(30, 30)

	# Set collision properties
	collision_layer = 1
	collision_mask = 1

	# Find the player when all nodes are loaded
	call_deferred("find_player")

## Find and store a reference to the player
func find_player() -> void:
	await get_tree().process_frame
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		return  # Skip processing if this monster is dead

	_update_timers(delta)
	_process_movement(delta)

## Update all timing variables
func _update_timers(delta: float) -> void:
	# Update afraid state timer
	if current_state == State.AFRAID:
		afraid_timer -= delta
		if afraid_timer <= 0:
			current_state = State.CHASE
			$AnimatedSprite2D.play("normal")

	# Update movement cooldown
	if move_cooldown > 0:
		move_cooldown -= delta

	# Update direction change timer
	direction_change_timer -= delta
	if direction_change_timer <= 0 and not is_moving:
		direction_change_timer = direction_change_interval
		adapt_direction()

## Process monster movement
func _process_movement(delta: float) -> void:
	# Decide next action if not moving
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

		# Add cooldown between movements
		move_cooldown = move_cooldown_duration

	# Handle movement toward target position
	if is_moving:
		var move_vector: Vector2 = target_position - position
		var movement_length: float = move_vector.length()

		if movement_length < 1:
			position = target_position
			is_moving = false
		else:
			var move_step: float = move_speed * Global.GRID_SIZE * delta
			if movement_length <= move_step:
				position = target_position
				is_moving = false
			else:
				velocity = move_vector.normalized() * move_step
				var test_collision = move_and_collide(velocity, true)
				if not test_collision:
					position += velocity
				else:
					is_moving = false

					# Check collision with player - Add cooldown to prevent multiple rapid collisions
					var current_time = Time.get_ticks_msec() / 1000.0
					if test_collision.get_collider() and test_collision.get_collider().is_in_group("player"):
						if current_time - last_collision_time > 0.5: # Only process collision every 0.5 seconds
							last_collision_time = current_time
							var player = test_collision.get_collider()
							if player.has_method("_handle_monster_collision"):
								player._handle_monster_collision(self)

## Chase the player using a simple algorithm
func chase_player() -> void:
	if not player_ref:
		return

	var direction: Vector2 = Vector2.ZERO

	# Decide whether to move on x or y first (randomized)
	if randi() % 2 == 0:
		# Try X axis first, then Y if needed
		if player_ref.position.x > position.x:
			direction = Vector2.RIGHT
		elif player_ref.position.x < position.x:
			direction = Vector2.LEFT
		else:
			# Same X, move on Y
			if player_ref.position.y > position.y:
				direction = Vector2.DOWN
			else:
				direction = Vector2.UP
	else:
		# Try Y axis first, then X if needed
		if player_ref.position.y > position.y:
			direction = Vector2.DOWN
		elif player_ref.position.y < position.y:
			direction = Vector2.UP
		else:
			# Same Y, move on X
			if player_ref.position.x > position.x:
				direction = Vector2.RIGHT
			else:
				direction = Vector2.LEFT

	if direction != Vector2.ZERO:
		target_position = position + direction * Global.GRID_SIZE
		is_moving = true

## Run away from the player
func flee_from_player() -> void:
	if not player_ref:
		return

	# Get direction away from player
	var direction: Vector2 = position - player_ref.position
	direction = direction.normalized()

	# Convert to cardinal direction (grid-based)
	if abs(direction.x) > abs(direction.y):
		direction.y = 0
		direction.x = sign(direction.x)
	else:
		direction.x = 0
		direction.y = sign(direction.y)

	if direction != Vector2.ZERO:
		target_position = position + direction * Global.GRID_SIZE
		is_moving = true
	else:
		move_randomly()

## Move in a random direction
func move_randomly() -> void:
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	var direction: Vector2 = directions[randi() % directions.size()]
	target_position = position + direction * Global.GRID_SIZE
	is_moving = true

## Make the monster afraid of the player
func make_afraid() -> void:
	current_state = State.AFRAID
	afraid_timer = afraid_duration
	$AnimatedSprite2D.play("afraid")

## Handle monster death
func die() -> void:
	is_dead = true

	# Play death animation if available
	if $AnimatedSprite2D.sprite_frames.has_animation("die"):
		$AnimatedSprite2D.play("die")
		await $AnimatedSprite2D.animation_finished

	# Disable collisions and AI
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	# Flash effect
	for i in range(2):
		visible = false
		await get_tree().create_timer(0.1).timeout
		visible = true
		await get_tree().create_timer(0.1).timeout

	# Hide monster instead of removing it
	visible = false

	# Start respawn timer
	await get_tree().create_timer(respawn_time).timeout

	# Respawn the monster at original position
	respawn()

## Respawn the monster at its original position
func respawn() -> void:
	# Reset position
	position = original_position
	target_position = position

	# Reset state
	current_state = State.CHASE
	is_dead = false
	is_moving = false

	# Reset animation
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("normal")

	# Re-enable physics and collision
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)

	# Make visible again
	visible = true

	print("Monster respawned at original position: ", original_position)

## Adapt direction based on current movement (similar to GameMaker original)
func adapt_direction() -> void:
	# If moving vertically
	if velocity.x == 0:
		# Try turning left or right
		if randf() < 0.33 and !test_move(transform, Vector2(-Global.GRID_SIZE, 0)):
			velocity = Vector2(-move_speed, 0) * Global.GRID_SIZE
		elif randf() < 0.33 and !test_move(transform, Vector2(Global.GRID_SIZE, 0)):
			velocity = Vector2(move_speed, 0) * Global.GRID_SIZE
	# If moving horizontally
	else:
		# Try turning up or down
		if randf() < 0.33 and !test_move(transform, Vector2(0, -Global.GRID_SIZE)):
			velocity = Vector2(0, -move_speed) * Global.GRID_SIZE
		elif randf() < 0.33 and !test_move(transform, Vector2(0, Global.GRID_SIZE)):
			velocity = Vector2(0, move_speed) * Global.GRID_SIZE

	# Update target position if velocity changed
	if velocity != Vector2.ZERO:
		target_position = position + velocity.normalized() * Global.GRID_SIZE
		is_moving = true
