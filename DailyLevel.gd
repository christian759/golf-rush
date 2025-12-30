extends Node

@onready var generator = $"../LevelGenerator"

func _ready():
	# Calculate Daily Seed
	var date = Time.get_date_dict_from_system()
	# Simple int hash: YYYY * 10000 + MM * 100 + DD
	var seed_val = date.year * 10000 + date.month * 100 + date.day
	
	if generator:
		generator.generate_daily_level(seed_val)
