extends RigidBody2D

# =====================
# TUNING (GAME FEEL)
# =====================
@export var max_force := 1300.0 # Maximum launch power
@export var max_drag_distance := 300.0 # Clamps the input vector length
@export var min_drag := 25.0
@export var stop_threshold := 15.0 # Increased for snappier stops
@export var power_curve := 1.25 # Non-linear power feel

@export var launch_angle_deg := 55.0 # For cosmetic arc preview if we had gravity-z simulation, but here strictly 2D top-down?
# WAIT: The design doc says "2D Arcade Golf". Usually top-down for "Golf Rush" implies billiards style or side-view? 
# "Use Godot's 2D physics system... Slightly exaggerated gravity". 
# If it's Side-View (Angry Birds style): Gravity affects Y.
# If it's Top-Down (Mini Golf): Gravity does NOT affect Y (except maybe slopes), friction does.
# User said: "Orientation: Landscape", "Slightly exaggerated gravity... Minimal air resistance." 
# AND "Slopes and ramps". 
# Usually "Golf Rush" with "Gravity" implies Side-View (like Flappy Golf or Desert Golfing).
# BUT "Drag from ball to aim... shot towards finger".
# Let's assume SIDE VIEW based on "Gravity" and "Trajectory Preview" usually implying an arc.
# IF Top-Down, "Gravity" usually just means friction/slopes.
# Let's stick to the existing code's implication which used `gravity`.
# Existing code: `vel.y += gravity * trajectory_step`. This implies SIDE VIEW.

@export var gravity_scale_override := 0.0 # We let the physics engine handle gravity usually, but if we want custom...
# Actually rigidBody2D has `gravity_scale`.

@export var trajectory_points := 30
@export var trajectory_step := 0.05

# =====================
# STATE
# =====================
@onready var trajectory: Line2D = $TrajectoryLine
# @onready var sprite: Sprite2D = $Sprite2D # Assuming we have one, or just use `ball.png`

var pointer_pos := Vector2.ZERO
var is_dragging := false
var can_shoot := true

# =====================
# READY
# =====================
func _ready():
	trajectory.clear_points()
	trajectory.visible = false
	# High continuous collision detection for fast moving objects
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	# Set physics material properties if not set in editor
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 0.3

# =====================
# PHYSICS
# =====================
func _physics_process(_delta):
	# Stop the ball if it's moving very slowly to allow next shot
	if linear_velocity.length() < stop_threshold:
		# Only force stop if we are on the ground/not falling? 
		# For side-view, we don't want to stop in mid-air.
		# We can check vertical velocity or collision.
		# For now, simplistic check:
		if abs(linear_velocity.y) < 10.0: # simplistic ground check assumption
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			if not can_shoot and not is_dragging:
				can_shoot = true
				print("Ball stopped. Ready to shoot.")

# =====================
# INPUT
# =====================
func _input(event):
	if not can_shoot:
		return

	# Handle Touch & Mouse
	var is_aiming = false
	var is_releasing = false
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: is_aiming = true
			else: is_releasing = true
			
	elif event is InputEventScreenTouch:
		if event.pressed: is_aiming = true
		else: is_releasing = true

	if is_aiming:
		start_aim(get_global_mouse_position()) # event.position might be viewport relative
	elif is_releasing and is_dragging:
		release_shot(get_global_mouse_position())
	
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_dragging:
		update_trajectory(get_global_mouse_position())

# =====================
# AIM CONTROL
# =====================
func start_aim(pos: Vector2):
	# Optional: Check if touch is near ball? Or anywhere on screen?
	# "Drag from ball to aim" implies near ball. 
	# User Request: "Drag from ball to aim (direction is toward the finger, not away)."
	# WAIT. "Direction is toward the finger, not away" -> This is SLINGSHOT usually implies drag BACK to shoot FORWARD.
	# BUT user said: "Drag from ball to aim... direction is TOWARD the finger".
	# Use Case: Touch Ball -> Drag Right -> Ball shoots Right. (Direct Aiming)
	# User said: "Drag distance controls power."
	# OK. So: Vector = (Pointer - Ball).
	
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
	var impulse = calculate_impulse(pointer)
	
	# If pull is too small, hide trajectory
	if impulse.length() < 10.0: # small threshold
		trajectory.visible = false
		return
	else:
		trajectory.visible = true

	# Simulate trajectory
	trajectory.clear_points()
	var pos = Vector2.ZERO # Local space
	var vel = impulse / mass # Initial velocity
	
	# Gravity from project settings usually 980
	var grav = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale
	var grav_vec = ProjectSettings.get_setting("physics/2d/default_gravity_vector") * grav
	
	for i in trajectory_points:
		trajectory.add_point(pos)
		vel += grav_vec * trajectory_step
		pos += vel * trajectory_step
		
		# Optional: Raycast to stop trajectory at walls? 
		# For fast "Arcade" feel, simple arc is often enough or just dot projection.

func calculate_impulse(pointer: Vector2) -> Vector2:
	var to_target = pointer - global_position
	var distance = to_target.length()
	
	# Clamp distance for max power
	var t = clamp(distance / max_drag_distance, 0.0, 1.0)
	
	# Power curve
	var speed = pow(t, power_curve) * max_force
	
	var dir = to_target.normalized()
	return dir * speed

# =====================
# SHOOT
# =====================
func fire_shot(pointer: Vector2):
	var impulse = calculate_impulse(pointer)
	if impulse.length() < 10.0:
		# Cancel shot
		return
		
	apply_impulse(impulse)
	can_shoot = false
	
	# Register shot with GameManager
	GameManager.register_stroke()
	
	# Juice
	# Input.vibrate_handheld(20) # Good for feedback
