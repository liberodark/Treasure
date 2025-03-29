extends CanvasLayer

func _ready():
	# Connect to Global signals
	if not Global.score_changed.is_connected(_on_score_changed):
		Global.score_changed.connect(_on_score_changed)
	
	if not Global.lives_changed.is_connected(_on_lives_changed):
		Global.lives_changed.connect(_on_lives_changed)
	
	# Initialize the UI with current values
	_on_score_changed(Global.score)
	_on_lives_changed(Global.lives)

func _on_score_changed(new_score):
	$MarginContainer/VBoxContainer/ScoreLabel.text = "Score: " + str(new_score)

func _on_lives_changed(new_lives):
	# Update life icons based on number of lives
	for i in range(1, 4):  # We have 3 life icons
		var life_icon = $MarginContainer/VBoxContainer/LivesContainer.get_node("LifeIcon" + str(i))
		life_icon.visible = i <= new_lives
