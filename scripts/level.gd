extends Node2D

var score = 0
var treasures_total = 0

func _ready():
	# Connect all treasures
	for treasure in get_tree().get_nodes_in_group("treasures"):
		treasure.collected.connect(_on_treasure_collected)
		treasures_total += 1
	
	print("Level loaded! Find ", treasures_total, " treasures.")

func _on_treasure_collected(value):
	score += value
	print("Score: ", score)
	
	# Check if all treasures are collected
	var remaining = get_tree().get_nodes_in_group("treasures").size()
	if remaining == 0:
		print("Level completed! Final score: ", score)
		# Here you could load the next level or display a victory screen
