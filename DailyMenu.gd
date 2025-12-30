extends Control

@onready var date_label = $VBoxContainer/DateLabel
@onready var play_button = $VBoxContainer/PlayButton

func _ready():
	var date = Time.get_date_dict_from_system()
	date_label.text = "Daily Challenge\n%02d-%02d-%04d" % [date.day, date.month, date.year]

func _on_play_button_pressed():
	# Load Daily Level
	get_tree().change_scene_to_file("res://levels/DailyLevel.tscn")

func _on_back_button_pressed():
	# Back to Main Menu
	GameManager.load_main_menu()
