extends Node

# Global variables accessible from anywhere
var score = 0
var high_score = 0
var lives = 3

# Signals for game events
signal score_changed(new_score)
signal lives_changed(new_lives)
signal game_over
signal level_completed

func _ready():
	# Load high scores, etc. if needed
	pass

func add_score(points):
	score += points
	if score > high_score:
		high_score = score
	
	score_changed.emit(score)

func lose_life():
	lives -= 1
	lives_changed.emit(lives)
	
	if lives <= 0:
		game_over.emit()
		# Wait a moment before restarting
		await get_tree().create_timer(2.0).timeout
		reset_game()
		# Get the GameManager to reload the first level
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("load_level"):
			game_manager.load_level(0)
	else:
		# Reload the current level
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("reload_current_level"):
			# Wait a moment before restarting the level
			await get_tree().create_timer(1.0).timeout
			game_manager.reload_current_level()

func reset_game():
	score = 0
	lives = 3
	score_changed.emit(score)
	lives_changed.emit(lives)

func complete_level():
	level_completed.emit()
