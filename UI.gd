extends CanvasLayer

@onready var score_label = $Control/ScoreLabel
@onready var time_label = $Control/TimeLabel
@onready var level_complete_panel = $Control/LevelCompletePanel

func _ready():
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	
	if level_complete_panel:
		level_complete_panel.visible = false

func _process(_delta):
	if time_label:
		time_label.text = "Time: %.1f" % GameManager.current_time
	if score_label:
		score_label.text = "Shots: %d" % GameManager.current_score

func _on_level_started():
	if level_complete_panel:
		level_complete_panel.visible = false

func _on_level_completed():
	if level_complete_panel:
		level_complete_panel.visible = true
		# Show stars etc.
