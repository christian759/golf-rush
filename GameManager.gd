extends Node

# Signal emitted when the level is fully loaded and ready
signal level_started
# Signal emitted when the level is completed (hole reached)
signal level_completed

var current_level_index: int = 0
var current_score: int = 0 # In strokes
var current_time: float = 0.0

# Path pattern for levels. Assuming they are named Level_01.tscn, Level_02.tscn etc.
# Ideally we would have a list of packed scenes or resource paths.
var levels: Array[String] = [
	"res://levels/Level_01.tscn",
	"res://levels/Level_02.tscn",
	"res://levels/Level_03.tscn",
	"res://levels/Level_04.tscn",
	"res://levels/Level_05.tscn",
	"res://levels/Level_06.tscn",
	"res://levels/Level_07.tscn",
	"res://levels/Level_08.tscn",
	"res://levels/Level_09.tscn",
	"res://levels/Level_10.tscn",
	"res://levels/Level_11.tscn"
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game():
	load_level(0)

func load_main_menu():
	get_tree().change_scene_to_file("res://main.tscn")

func load_level(index: int):
	if index < 0:
		print("Level index cannot be negative.")
		return
		
	if index >= levels.size():
		print("No more levels! Returning to main menu.")
		load_main_menu()
		return
	
	current_level_index = index
	var level_path = levels[current_level_index]
	get_tree().change_scene_to_file(level_path)
	
	# Reset transients
	current_score = 0
	current_time = 0.0

func next_level():
	load_level(current_level_index + 1)

func restart_level():
	get_tree().reload_current_scene()
	current_score = 0
	current_time = 0.0

func register_stroke():
	current_score += 1

func _process(delta):
	# Wait for scene to be ready/loaded
	if get_tree().current_scene == null:
		return
		
	# Assuming we are in a level, only increment timer if not in a menu
	var scene_name = get_tree().current_scene.name
	if scene_name != "MainMenu" and scene_name != "Main" and scene_name != "DailyMenu": 
		current_time += delta
