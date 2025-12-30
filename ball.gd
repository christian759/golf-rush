extends RigidBody2D

# =====================
# TUNING (GAME FEEL)
# =====================
@export var max_force := 1300.0
@export var min_drag := 25.0
@export var stop_threshold := 10.0
@export var max_speed := 1500.0
@export var power_curve := 1.25

@export var launch_angle_deg := 55.0
@export var trajectory_points := 24
@export var trajectory_step := 0.08
@export var gravity := 980.0

# =====================
# STATE
# =====================
@onready var trajectory: Line2D = $TrajectoryLine

var pointer_pos := Vector2.ZERO
var is_dragging := false
var can_shoot := true

# =====================
# READY
# =====================
func _ready():
	trajectory.clear_points()
	trajectory.visible = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

# =====================
# PHYSICS
# =====================
func _physics_process(_delta):
	if linear_velocity.length() < stop_threshold:
		linear_velocity = Vector2.ZERO
		can_shoot = true

	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

# =====================
# INPUT (TOUCH + MOUSE)
# =====================
func _input(event):
	if not can_shoot:
		return

	# -------- TOUCH --------
	if event is InputEventScreenTouch:
		if event.pressed:
			start_aim(event.position)
		else:
			release_shot(event.position)

	if event is InputEventScreenDrag and is_dragging:
		update_trajectory(event.position)

	# -------- MOUSE --------
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_aim(event.position)
			else:
				release_shot(event.position)

	if event is InputEventMouseMotion and is_dragging:
		update_trajectory(event.position)

# =====================
# AIM CONTROL
# =====================
func start_aim(pos: Vector2):
	pointer_pos = pos
	is_dragging = true
	trajectory.visible = true
	update_trajectory(pos)

func release_shot(pos: Vector2):
	fire_shot(pos)
	is_dragging = false
	trajectory.visible = false

# =====================
# TRAJECTORY PREVIEW
# =====================
func update_trajectory(pointer: Vector2):
	var to_target = pointer - global_position
	var distance = to_target.length()

	if distance < min_drag:
		trajectory.clear_points()
		return

	var t = clamp(distance / max_force, 0.0, 1.0)
	var speed = pow(t, power_curve) * max_force / mass

	var angle = deg_to_rad(launch_angle_deg)
	var dir = to_target.normalized()

	var velocity = Vector2(
		dir.x * speed * cos(angle),
		-speed * sin(angle)
	)

	trajectory.clear_points()

	var pos = global_position
	var vel = velocity

	for i in trajectory_points:
		trajectory.add_point(to_local(pos))
		vel.y += gravity * trajectory_step
		pos += vel * trajectory_step

# =====================
# SHOOT
# =====================
func fire_shot(pointer: Vector2):
	var to_target = pointer - global_position
	var distance = to_target.length()

	if distance < min_drag:
		return

	var t = clamp(distance / max_force, 0.0, 1.0)
	var speed = pow(t, power_curve) * max_force

	var angle = deg_to_rad(launch_angle_deg)
	var dir = to_target.normalized()

	var impulse = Vector2(
		dir.x * speed * cos(angle),
		-speed * sin(angle)
	)

	apply_impulse(impulse)
	Input.vibrate_handheld(20)

	can_shoot = false
