class_name HUD
extends CanvasLayer
## User interface that displays game information like score and lives.
##
## Connects to global signals to update the display when values change.

func _ready() -> void:
	# Make sure Global singleton exists
	if not has_node("/root/Global"):
		push_error("Global singleton not found!")
		return
	
	# Connect to Global signals
	if not Global.score_changed.is_connected(_on_score_changed):
		Global.score_changed.connect(_on_score_changed)
	
	if not Global.lives_changed.is_connected(_on_lives_changed):
		Global.lives_changed.connect(_on_lives_changed)
	
	# Initialize the UI with current values
	_on_score_changed(Global.score)
	_on_lives_changed(Global.lives)

## Update score display when score changes
func _on_score_changed(new_score: int) -> void:
	if has_node("MarginContainer/VBoxContainer/ScoreLabel"):
		$MarginContainer/VBoxContainer/ScoreLabel.text = "Score: %d" % new_score

## Update life icons when lives change
func _on_lives_changed(new_lives: int) -> void:
	# Make sure we have the lives container
	if not has_node("MarginContainer/VBoxContainer/LivesContainer"):
		return
		
	# Update life icons based on number of lives
	for i in range(1, 4):  # We have 3 life icons
		var life_icon_path = "MarginContainer/VBoxContainer/LivesContainer/LifeIcon%d" % i
		if has_node(life_icon_path):
			get_node(life_icon_path).visible = i <= new_lives
