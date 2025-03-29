extends Node

# Global game variables
var score = 0
var lives = 3
var current_level = 0
var hud_scene = preload("res://scenes/ui/hud.tscn")
var hud_instance = null

# Paths to different levels
var levels = [
	"res://scenes/levels/level0.tscn",
	"res://scenes/levels/level1.tscn",
	"res://scenes/levels/level2.tscn",
	"res://scenes/levels/level3.tscn",
	"res://scenes/levels/level4.tscn",
	"res://scenes/levels/level5.tscn",
]

func _ready():
	# Load the first level
	load_level(current_level)

func load_level(level_index):
	if level_index >= 0 and level_index < levels.size():
		# Load the level scene
		var level_scene = load(levels[level_index])
		var level_instance = level_scene.instantiate()
		
		# Remove the old level if it exists
		for child in get_children():
			if child.name.begins_with("Level"):
				child.queue_free()
		
		# Remove old HUD if it exists
		if hud_instance:
			hud_instance.queue_free()
		
		# Add the new level
		add_child(level_instance)
		current_level = level_index
		print("Level ", current_level + 1, " loaded.")
		
		# Add HUD
		hud_instance = hud_scene.instantiate()
		add_child(hud_instance)
	else:
		print("Game Over! All levels completed.")
		# Here you could display an ending screen

func next_level():
	load_level(current_level + 1)

func reload_current_level():
	load_level(current_level)

func lose_life():
	lives -= 1
	if lives <= 0:
		print("Game Over!")
		# Here you could reset the game or display a game over screen
	else:
		print("Lives remaining: ", lives)
		# Reload the current level
		load_level(current_level)

func add_score(points):
	score += points
	Global.add_score(points)
	print("Score: ", score)
