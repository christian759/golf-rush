extends Node2D
class_name Level

@export var par_strokes: int = 3
@export var gold_time: float = 10.0

# Store the start position to respawn the ball if needed
var start_position: Vector2

func _ready():
	# Find the ball and set its start position
	var ball = get_node_or_null("Ball")
	if ball:
		start_position = ball.global_position
	
	GameManager.level_started.emit()

func _on_ball_out_of_bounds():
	var ball = get_node_or_null("Ball")
	if ball:
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0.0
		ball.global_position = start_position
		# Optional: Add penalty stroke?
		
func level_complete():
	GameManager.level_completed.emit()
	print("Level Complete! Time: ", GameManager.current_time, " Strokes: ", GameManager.current_score)
	# Trigger UI here in real implementation
