extends Node
## Global game state singleton that manages score, lives, and level progression.

# Score and lives tracking
var score = 0
var high_score = 0
var lives = 3
var default_lives = 3

# Game state signals
signal score_changed(new_score)
signal lives_changed(new_lives)
signal game_over
signal level_completed

# Constants
const GRID_SIZE = 32
const RESTART_DELAY = 2.0
const LEVEL_RELOAD_DELAY = 1.0

func _ready():
	# Initialize high score from saved data if available
	pass

## Add points to the player's score
func add_score(points):
	score += points
	if score > high_score:
		high_score = score

	score_changed.emit(score)

## Reduce player lives by one and handle game over if needed
func lose_life():
	lives -= 1
	lives_changed.emit(lives)

	if lives <= 0:
		game_over.emit()
	else:
		# Reload the current level
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("reload_current_level"):
			await get_tree().create_timer(LEVEL_RELOAD_DELAY).timeout
			game_manager.reload_current_level()

## Reset game state for a new game
func reset_game():
	score = 0
	lives = default_lives

	# Notify UI and other systems
	score_changed.emit(score)
	lives_changed.emit(lives)

## Mark current level as completed
func complete_level():
	level_completed.emit()
