extends RigidBody2D

# =====================
# TUNING (GAME FEEL)
# =====================
@export var max_force := 1300.0
@export var min_drag := 25.0
@export var stop_threshold := 10.0
@export var max_speed := 1500.0
@export var power_curve := 1.25

@export var trajectory_points := 24
@export var trajectory_step := 0.08
@export var gravity := 980.0

# =====================
# STATE
# =====================
@onready var trajectory: Line2D = $TrajectoryLine

var touch_start := Vector2.ZERO
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
# INPUT (MOBILE)
# =====================
func _input(event):
	if not can_shoot:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			is_dragging = true
			trajectory.visible = true
		else:
			fire_shot(event.position)
			is_dragging = false
			trajectory.visible = false

	if event is InputEventScreenDrag and is_dragging:
		update_trajectory(event.position)

# =====================
# TRAJECTORY PREVIEW
# =====================
func update_trajectory(current_pos: Vector2):
	var drag = touch_start - current_pos

	# Prevent backward shots
	drag.y = min(drag.y, 0)

	var raw_force = drag.length()
	if raw_force < min_drag:
		trajectory.clear_points()
		return

	var normalized = clamp(raw_force / max_force, 0.0, 1.0)
	var force = pow(normalized, power_curve) * max_force

	var velocity = drag.normalized() * force / mass

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
func fire_shot(touch_end: Vector2):
	var drag = touch_start - touch_end
	drag.y = min(drag.y, 0)

	var raw_force = drag.length()
	if raw_force < min_drag:
		return

	var normalized = clamp(raw_force / max_force, 0.0, 1.0)
	var force = pow(normalized, power_curve) * max_force

	apply_impulse(drag.normalized() * force)
	Input.vibrate_handheld(20)

	can_shoot = false
