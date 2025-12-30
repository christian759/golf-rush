extends Area2D

# Signal to notify when ball enters hole
signal ball_entered_hole

@export var suction_speed := 10.0
@export var suction_radius := 20.0

var ball_to_suck: RigidBody2D = null

func _ready():
	# Connect to our own body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Ball" or body.has_method("fire_shot"): # Robust check
		print("Ball entered hole!")
		ball_to_suck = body
		ball_to_suck.linear_damp = 5.0 # Slow it down fast
		
		# Disable ball logic so user can't shoot inside hole
		if "can_shoot" in ball_to_suck:
			ball_to_suck.can_shoot = false
			
		# Wait a tiny bit then trigger level complete
		# But we want a suction animation first
		await get_tree().create_timer(0.5).timeout
		var level = get_tree().current_scene
		if level.has_method("level_complete"):
			level.level_complete()

func _physics_process(delta):
	if ball_to_suck:
		# Suck ball towards center
		var dir = global_position - ball_to_suck.global_position
		if dir.length() < 5.0:
			ball_to_suck.linear_velocity = Vector2.ZERO
			ball_to_suck.global_position = global_position # force center
		else:
			ball_to_suck.apply_central_force(dir.normalized() * suction_speed * 100.0)
