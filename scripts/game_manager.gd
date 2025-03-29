extends Node
## Manages game state, level loading, and progression through the game.
##
## Also handles game pausing and pause menu integration.

# Path references to game levels
const LEVEL_PATHS = [
	"res://scenes/levels/level0.tscn",
	"res://scenes/levels/level1.tscn",
	"res://scenes/levels/level2.tscn",
	"res://scenes/levels/level3.tscn",
	"res://scenes/levels/level4.tscn",
	"res://scenes/levels/level5.tscn",
]

# Audio references
const MUSIC_PATH = "res://assets/sounds/music.ogg"

# Reference to the HUD scene
@export var hud_scene_path: String = "res://scenes/ui/hud.tscn"
@export var pause_menu_scene_path: String = "res://scenes/ui/pause_menu.tscn"

# Game state tracking
var current_level = 0
var hud_instance = null
var current_level_instance = null
var is_reloading = false
var treasures_remaining: int = 0
var music_player: AudioStreamPlayer = null
var is_paused: bool = false
var pause_menu_instance = null

func _ready():
	# Add to sfx_parent group for audio management
	add_to_group("sfx_parent")
	
	# Connect to Global signals
	if has_node("/root/Global"):
		Global.game_over.connect(_on_game_over)
		Global.level_completed.connect(_on_level_completed)
	
	# Set up background music
	_setup_music_player()
	
	# Initialize the pause menu
	_setup_pause_menu()
	
	# Start the game with the first level
	load_level(current_level)
	
	# Debug output
	print("GameManager ready, pause menu path: " + pause_menu_scene_path)
	print("Pause menu instance: " + str(pause_menu_instance != null))

func _setup_pause_menu():
	if ResourceLoader.exists(pause_menu_scene_path):
		var pause_menu_scene = load(pause_menu_scene_path)
		pause_menu_instance = pause_menu_scene.instantiate()
		add_child(pause_menu_instance)
		
		# Connect pause menu signals
		pause_menu_instance.resume_requested.connect(_on_resume_game)
		pause_menu_instance.main_menu_requested.connect(_on_quit_to_main_menu)
		
		# Hide the menu initially
		pause_menu_instance.hide_menu()
		print("Pause menu setup successful")
	else:
		push_error("Could not load pause menu scene: %s" % pause_menu_scene_path)

## Load a specific level by index
func load_level(level_index):
	if is_reloading:
		return
		
	is_reloading = true
	
	if level_index < 0 or level_index >= LEVEL_PATHS.size():
		push_error("Error: Level index %d out of range!" % level_index)
		is_reloading = false
		return
	
	# Remove current level if it exists
	_clear_current_level()
	
	# Load and instantiate the new level
	var level_path = LEVEL_PATHS[level_index]
	if ResourceLoader.exists(level_path):
		var level_scene = load(level_path)
		current_level_instance = level_scene.instantiate()
		add_child(current_level_instance)
		
		# Update current level index
		current_level = level_index
		print("Level %d loaded." % (current_level + 1))
		
		# Play music if this is level 0 and it's not already playing
		if level_index == 0 and music_player and not music_player.playing:
			music_player.play()
		
		# Add HUD over the level
		_add_hud()
		
		# Connect to treasures after a frame to ensure they're properly added to the scene
		call_deferred("_connect_to_treasures")
	else:
		push_error("Could not load level path: %s" % level_path)
	
	is_reloading = false

## Connect to all treasures in the current level
func _connect_to_treasures():
	# Wait one frame to ensure all nodes are properly added to the scene
	await get_tree().process_frame
	
	# Find all treasures in the level
	var treasures = get_tree().get_nodes_in_group("treasures")
	treasures_remaining = treasures.size()
	
	print("Level started with %d treasures to collect" % treasures_remaining)
	
	# Connect to each treasure's collected signal
	for treasure in treasures:
		if not treasure.collected.is_connected(_on_treasure_collected):
			treasure.collected.connect(_on_treasure_collected)
	
	# Check if there are no treasures in the level
	if treasures_remaining == 0:
		print("No treasures in this level, it might be a boss level or a special level.")

## Called when a treasure is collected
func _on_treasure_collected(_value):
	treasures_remaining -= 1
	print("Treasure collected! Remaining: %d" % treasures_remaining)
	
	# Check if all treasures have been collected
	if treasures_remaining <= 0:
		print("All treasures collected! Level complete!")
		# Call the global level complete function
		if has_node("/root/Global"):
			Global.complete_level()

## Progress to the next level
func next_level():
	var next_index = current_level + 1
	
	# Check if we've reached the end of the game
	if next_index >= LEVEL_PATHS.size():
		print("Game completed! Congratulations!")
		# TODO: Show game completion screen
		return
	
	load_level(next_index)

## Reload the current level
func reload_current_level():
	if is_reloading:
		return
		
	# Add a small delay to ensure all processes are completed before reload
	await get_tree().create_timer(0.1).timeout
	load_level(current_level)

## Clear the current level from the scene
func _clear_current_level():
	# Free current level instance if it exists
	if current_level_instance != null:
		current_level_instance.queue_free()
		current_level_instance = null
	
	# Remove old HUD if it exists
	if hud_instance:
		hud_instance.queue_free()
		hud_instance = null
		
	# Make sure the scene is clean
	for child in get_children():
		if child.name.begins_with("Level"):
			child.queue_free()

## Add the HUD to the scene
func _add_hud():
	if ResourceLoader.exists(hud_scene_path):
		var hud_resource = load(hud_scene_path)
		hud_instance = hud_resource.instantiate()
		add_child(hud_instance)
	else:
		push_error("Could not load HUD scene: %s" % hud_scene_path)

## Handler for game over signal
func _on_game_over():
	print("Game over - restarting from first level")
	# Wait a bit before restarting
	await get_tree().create_timer(2.0).timeout
	# Reset the game state before loading the new level
	Global.reset_game()
	load_level(0)

## Set up the music player for background music
func _setup_music_player():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	if ResourceLoader.exists(MUSIC_PATH):
		var music = load(MUSIC_PATH)
		music_player.stream = music
		music_player.volume_db = -10.0  # Set an appropriate volume level
		music_player.bus = "Music"
	else:
		push_error("Could not load music file: %s" % MUSIC_PATH)

## Handler for level completed signal
func _on_level_completed():
	print("Level completed - loading next level")
	# Wait a bit before loading next level
	await get_tree().create_timer(1.0).timeout
	next_level()

## Captures unhandled inputs for pause management
func _input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game")) and not is_reloading:
		print("Pause key/button pressed")
		if is_paused:
			_on_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

## Pauses the game and shows the pause menu
func _pause_game():
	print("Pausing the game")
	if is_paused:
		return
		
	is_paused = true
	get_tree().paused = true
	
	if pause_menu_instance:
		pause_menu_instance.show_menu()
	else:
		push_error("Pause menu instance is null! Cannot show pause menu.")

## Resumes the game and hides the pause menu
func _on_resume_game():
	print("Resuming the game")
	is_paused = false
	get_tree().paused = false
	
	if pause_menu_instance:
		pause_menu_instance.hide_menu()

## Quits the level and returns to the main menu
func _on_quit_to_main_menu():
	print("Returning to main menu")
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
