class_name Player
extends CharacterBody2D
## Player controller with grid-based movement.
##
## Handles player input, movement on a grid, and interactions with
## treasures and monsters.

# Grid movement configuration
@export var move_speed: float = 3.0
@export var monster_kill_score: int = 25
@export var flash_count: int = 2
@export var flash_duration: float = 0.05

# Movement state tracking
var input_direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_being_defeated: bool = false  # Flag to prevent multiple defeats
var last_direction: String = "up"  # Track the last movement direction for idle state

# Sound resources
const MONSTER_DEFEAT_SOUND_PATH: String = "res://assets/sounds/catch.ogg"
const DEATH_SOUND_PATH: String = "res://assets/sounds/dead.ogg"

func _ready() -> void:
	target_position = position
	add_to_group("player")

	# Make sure the collision shape has the right size
	if has_node("CollisionShape2D"):
		$CollisionShape2D.shape.size = Vector2(30, 30)

	# Start with the default direction animation, frame 1
	$AnimatedSprite2D.animation = last_direction
	$AnimatedSprite2D.frame = 1

func _physics_process(delta: float) -> void:
	if not is_moving and not is_being_defeated:
		_handle_input()

	if is_moving and not is_being_defeated:
		_process_movement(delta)

## Handle player input for movement
func _handle_input() -> void:
	input_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_direction = Vector2.RIGHT
		$AnimatedSprite2D.play("right")
		last_direction = "right"
	elif Input.is_action_pressed("ui_left"):
		input_direction = Vector2.LEFT
		$AnimatedSprite2D.play("left")
		last_direction = "left"
	elif Input.is_action_pressed("ui_down"):
		input_direction = Vector2.DOWN
		$AnimatedSprite2D.play("down")
		last_direction = "down"
	elif Input.is_action_pressed("ui_up"):
		input_direction = Vector2.UP
		$AnimatedSprite2D.play("up")
		last_direction = "up"
	# No else case needed - we keep the last animation playing when idle

	# Calculate target position if we have input
	if input_direction != Vector2.ZERO:
		target_position = position + input_direction * Global.GRID_SIZE
		is_moving = true

## Process movement toward target position
func _process_movement(delta: float) -> void:
	var move_vector: Vector2 = target_position - position
	var movement_length: float = move_vector.length()

	# Check if we've reached the destination
	if movement_length < 1.0:
		position = target_position
		is_moving = false
		# Stop animation and set to frame 1 of the last direction
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.animation = last_direction
		$AnimatedSprite2D.frame = 1
		return

	# Calculate movement step
	var move_step: float = move_speed * Global.GRID_SIZE * delta

	# Check if this step will reach or exceed the target
	if movement_length <= move_step:
		position = target_position
		is_moving = false
		# Stop animation and set to frame 1 of the last direction
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.animation = last_direction
		$AnimatedSprite2D.frame = 1
	else:
		velocity = move_vector.normalized() * move_step
		var test_collision = move_and_collide(velocity, true)

		if not test_collision:
			position += velocity
		else:
			is_moving = false
			# Stop animation and set to frame 1 of the last direction
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.animation = last_direction
			$AnimatedSprite2D.frame = 1

			# Check if we collided with a monster
			if test_collision.get_collider() and test_collision.get_collider().is_in_group("monsters"):
				_handle_monster_collision(test_collision.get_collider())

## Handle monster collision logic
func _handle_monster_collision(monster: Node2D) -> void:
	# Avoid handling collision if already being defeated
	if is_being_defeated:
		return

	# Check if monster is afraid
	if "current_state" in monster and monster.current_state == monster.State.AFRAID:
		_defeat_monster(monster)
	else:
		_player_defeated()

## Handle defeating a monster
func _defeat_monster(monster: Node2D) -> void:
	print("Defeating afraid monster")
	# Kill the monster
	if monster.has_method("die"):
		monster.die()

	# Add points for killing a monster
	Global.add_score(monster_kill_score)

	# Play defeat monster sound
	var sound_player = AudioStreamPlayer.new()
	add_child(sound_player)

	if ResourceLoader.exists(MONSTER_DEFEAT_SOUND_PATH):
		sound_player.stream = load(MONSTER_DEFEAT_SOUND_PATH)
		sound_player.volume_db = -5.0
		sound_player.play()

		# Auto-remove the sound player when it finishes
		await sound_player.finished
		sound_player.queue_free()

## Handle player being defeated by a monster
func _player_defeated() -> void:
	# Prevent multiple defeats
	if is_being_defeated:
		return

	is_being_defeated = true
	print("Player killed by monster!")

	# Disable all collision instantly
	$CollisionShape2D.set_deferred("disabled", true)

	# Disable player controls
	set_physics_process(false)

	# Lose a life through the global system immediately
	Global.lose_life()

	# Play death sound
	var sound_player = AudioStreamPlayer.new()
	add_child(sound_player)

	if ResourceLoader.exists(DEATH_SOUND_PATH):
		sound_player.stream = load(DEATH_SOUND_PATH)
		sound_player.volume_db = -5.0
		sound_player.play()

	# Make player flash quickly
	for i in range(flash_count):
		visible = false
		await get_tree().create_timer(flash_duration).timeout
		visible = true
		await get_tree().create_timer(flash_duration).timeout

	# Make player invisible at the end to avoid confusion
	visible = false
