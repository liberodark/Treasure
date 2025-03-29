extends Node2D
## Global game state singleton that manages score, lives, and level progression.
##
## Provides signals and methods to track player progress across the game.
## This script should be used as an autoload singleton.

# Score and lives tracking
var score: int = 0
var high_score: int = 0
var lives: int = 3

# Game state signals
## Emitted when the score changes, with the new score value
signal score_changed(new_score: int)
## Emitted when player lives change, with the new lives count
signal lives_changed(new_lives: int)
## Emitted when the player loses all lives
signal game_over
## Emitted when a level is completed
signal level_completed

# Constants
const RESTART_DELAY: float = 2.0
const LEVEL_RELOAD_DELAY: float = 1.0
const DEFAULT_LIVES: int = 3

func _ready() -> void:
	# Initialize high score from saved data if available
	# load_game_data()
	pass

## Add points to the player's score
func add_score(points: int) -> void:
	score += points
	if score > high_score:
		high_score = score
		# save_game_data()
	
	score_changed.emit(score)

## Reduce player lives by one and handle game over if needed
func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	
	if lives <= 0:
		game_over.emit()
		await get_tree().create_timer(RESTART_DELAY).timeout
		reset_game()
		
		# Reload the first level
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("load_level"):
			game_manager.load_level(0)
	else:
		# Reload the current level
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("reload_current_level"):
			await get_tree().create_timer(LEVEL_RELOAD_DELAY).timeout
			game_manager.reload_current_level()

## Reset game state for a new game
func reset_game() -> void:
	score = 0
	lives = DEFAULT_LIVES
	
	# Notify UI and other systems
	score_changed.emit(score)
	lives_changed.emit(lives)

## Mark current level as completed
func complete_level() -> void:
	level_completed.emit()
	
	# Optional: Transition to next level
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("next_level"):
		await get_tree().create_timer(1.0).timeout
		game_manager.next_level()

## Save game data (high score, etc.) - could be implemented later
func save_game_data() -> void:
	# TODO: Implement save game functionality
	pass

## Load game data (high score, etc.) - could be implemented later
func load_game_data() -> void:
	# TODO: Implement load game functionality
	pass
