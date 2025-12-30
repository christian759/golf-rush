extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var start_button = $VBoxContainer/StartButton

func _ready():
	# Simple entrance animation
	title_label.modulate.a = 0.0
	start_button.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 1.0).from(Vector2(0.8, 0.8))
	tween.tween_property(start_button, "modulate:a", 1.0, 0.5)

func _on_start_button_pressed():
	GameManager.start_game()

func _on_daily_button_pressed():
	get_tree().change_scene_to_file("res://DailyMenu.tscn")
