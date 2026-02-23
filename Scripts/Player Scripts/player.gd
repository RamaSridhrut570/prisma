extends CharacterBody3D


const FOOTSTEPS = preload("uid://cmktost4kxabt")



#################################################
###              NODE REFERENCES              ###
#################################################

@onready var neck: Node3D = $neck
@onready var head: Node3D = $neck/head
@onready var eyes: Node3D = $neck/head/eyes
@onready var camera_3d: Camera3D = $neck/head/eyes/Camera3D
@onready var eyes_anim: AnimationPlayer = $neck/head/eyes/AnimationPlayer
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_crouch: RayCast3D = $RayCast_Crouch
@onready var vertical_climb_timer: Timer = $Vertical_Climb_Timer
@onready var sfx_player: AudioStreamPlayer = $SFX
@onready var dialogues_player: AudioStreamPlayer = $Dialogues
@onready var torch_light: SpotLight3D = $neck/head/eyes/Camera3D/TorchLight

# Wall Detection Raycasts
@export_group("Wall Detection")
@export var ray_cast_is_wall_check_F: RayCast3D
@export var ray_cast_is_wall_check_L: RayCast3D
@export var ray_cast_is_wall_check_R: RayCast3D
@export var ray_cast_is_still_wall_check_F: RayCast3D
@export var ray_cast_is_on_floor: RayCast3D


#################################################
###             CONFIGURATION                 ###
#################################################

@export_group("Camera Settings")
@export var mouse_sens: float = 0.2
@export var cam_rotation_amount: float = 0.05
@export var free_look_tilt_amount: float = 4
@export var camera_rotation_speed: float = 5.0

@export_group("Movement Settings")
@export var lerp_speed: float = 6.0
@export var air_lerp_speed: float = 1.0
@export var walking_speed: float = 9.0
@export var sprinting_speed: float = 16.0
@export var crouching_speed: float = 5.0
@export var crouching_depth: float = -1.6
@export var slide_speed: float = 12.0

@export_group("Jump Settings")
@export var JUMP_HEIGHT: float = 4.0
@export var JUMP_TIME_TO_PEAK: float = 0.4
@export var JUMP_TIME_TO_DESCENT: float = 0.3
@export var DOUBLE_JUMP_VELOCITY: float = 20.0
@export var enable_double_jump: bool = true

@export_group("Fall and Land Settings")
@export var FALL_VEL_THRESHOLD := -36.0
@export var LAND_VEL_THRESHOLD := -36.0

@export_group("Wall Mechanics")
@export var WALL_CLIMB_SPEED: float = 9.0
@export var WALL_CLIMB_GRAVITY: float = 3.0
@export var WALL_CLIMB_MAX_DURATION: float = 1.0
@export var WALL_CLIMB_JUMP_BOOST: float = 1.0
@export var MAX_WALL_SLIDE_SPEED: float = 10.0
@export var WALL_JUMP_HORIZONTAL_SPEED: float = 16.0
@export var WALL_JUMP_TURN_SPEED: float = 10.0

@export_group("Mechanic Toggles")
@export var can_walk: bool = true
@export var can_sprint: bool = true
@export var can_crouch: bool = true
@export var can_slide: bool = true
@export var can_jump: bool = true
@export var can_double_jump_mechanic: bool = true
@export var can_wall_climb: bool = true
@export var can_wall_jump: bool = true
@export var can_wall_slide: bool = true
@export var can_free_look: bool = true
@export var can_look: bool = true
@export var can_torch: bool = false

# Calculated Physics Constants
@onready var JUMP_VELOCITY: float = ((2.0 * JUMP_HEIGHT) / JUMP_TIME_TO_PEAK) * -1.0
@onready var JUMP_GRAVITY: float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK)) * -1.0
@onready var FALL_GRAVITY: float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0


#################################################
###            STATE VARIABLES                ###
#################################################

# --- Movement States ---
var current_speed: float = 5.0
var walking: bool = false
var sprinting: bool = false
var crouching: bool = false
var sliding: bool = false
var free_looking: bool = false

# --- Physics Vectors ---
var direction: Vector3 = Vector3.ZERO
var local_velocity: Vector3 = Vector3.ZERO
var horizontal_velocity: Vector3 = Vector3.ZERO
var slide_vector: Vector2 = Vector2.ZERO

# --- Wall & Air States ---
var wall_climbing: bool = false
var wall_slide_enabled: bool = true
var wall_jump_available: bool = false
var can_double_jump: bool = false
var just_wall_jumped: bool = false
var rotating_to_wall_jump: bool = false

# --- Jump Counters & Timers ---
const MAX_JUMPS: int = 2
var JUMPS_DONE: int = 0
var wait_time_1: float = 0.0
var wall_jump_timer: float = 0.0
var wall_jump_window_timer: float = 0.0
var wall_jump_max_duration: float = 0.3
var slide_timer: float = 0.0
var slide_timer_max: float = 1.6

# --- Wall Jump Logic Vars ---
var wall_jump_direction: Vector3 = Vector3.ZERO
var wall_jump_speed: float = 0.0
var target_wall_jump_yaw: float = 0.0

# --- Head Bobbing Vars ---
var HEAD_BOBBING_SPRINTING_SPEED = 22.0
var HEAD_BOBBING_WALKING_SPEED = 14.0
var HEAD_BOBBING_CROUCHING_SPEED = 10.0
# Intensity: Boosted (Sprint > Walk > Crouch)
var HEAD_BOBBING_SPRINTING_INTENSITY = 0.25
var HEAD_BOBBING_WALKING_INTENSITY = 0.15
var HEAD_BOBBING_CROUCHING_INTENSITY = 0.1

var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0
var head_bobbing_current_intensity: float = 0.0

# --- Footstep Vars ---
var _prev_bob_sin: float = 0.0 # Tracks last frame's sine value to detect zero-crossings

# --- Camera Transform Targets ---
var default_camera_rotation: Vector3 = Vector3.ZERO
var climb_camera_rotation: Vector3 = Vector3(-20, 0, 0)
var landing_camera_offset: Vector3 = Vector3(5, 0, 0)

# --- Falling and Landing ---
var input_locked: bool = false
var was_on_floor: bool = false
var last_vertical_velocity_y: float = 0.0


#################################################
###           LIFECYCLE FUNCTIONS             ###
#################################################

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	wall_jump_available = false
	wall_slide_enabled = true
	was_on_floor = is_on_floor()
	sfx_player.stream = FOOTSTEPS
	if torch_light:
		torch_light.visible = can_torch


func _process(_delta: float) -> void:
	# Convert world velocity into local space (player-relative)
	local_velocity = global_transform.basis.inverse() * velocity

func _physics_process(delta: float) -> void:
	_apply_wall_jump_turn(delta)
	validate_movement_states()
	
	vertical_wall_climb(delta)
	apply_gravity_and_friction(delta)

	var on_floor_now := is_on_floor()
	_update_fall_and_land_animations(on_floor_now)
	was_on_floor = on_floor_now
	last_vertical_velocity_y = velocity.y

	if is_on_floor():
		enable_front_raycasts()

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if input_locked:
		input_dir = Vector2.ZERO

	handle_stance_and_sliding(delta, input_dir)
	_update_slide(delta)
	
	handle_free_look_and_sliding(delta)
	handle_head_bob(delta, input_dir)
	
	handle_movement(delta, input_dir)
	camera_tilt(input_dir.x, delta)

func _input(event: InputEvent) -> void:
	if input_locked:
		return
	if rotating_to_wall_jump:
		return
		
	if event is InputEventMouseMotion and can_look:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(89))

func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if Input.is_action_just_pressed("toggle_wall_slide"):
		wall_slide_enabled = !wall_slide_enabled

	if Input.is_action_just_pressed("toggle_torch") and can_torch:
		if torch_light:
			torch_light.visible = !torch_light.visible
		
	if event is InputEventKey and event.pressed and Input.is_action_pressed("escape"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#################################################
###             MOVEMENT LOGIC                ###
#################################################

func handle_movement(delta: float, input_dir: Vector2) -> void:
	if not can_walk:
		input_dir = Vector2.ZERO
	
	# Normal direction calculation
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)
	
	# Sliding logic
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = slide_timer * slide_speed
	
	# Wall jump control
	if just_wall_jumped and wall_jump_timer > 0:
		wall_jump_timer -= delta
		
		# Calculate influence strength
		var wall_influence = wall_jump_timer / wall_jump_max_duration
		
		# Blend wall jump direction with player input direction
		if direction != Vector3.ZERO:
			direction = lerp(direction, wall_jump_direction, wall_influence * 0.8) # 80% max wall influence
		else:
			direction = wall_jump_direction * wall_influence
		
		# Override speed
		current_speed = max(current_speed, wall_jump_speed * wall_influence)
		
		# End wall jump
		if wall_jump_timer <= 0:
			just_wall_jumped = false
	
	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	jump_logic(delta)
	move_and_slide()

func apply_gravity_and_friction(delta: float) -> void:
	# Reset jump counter when landing
	if is_on_floor():
		JUMPS_DONE = 0
	
	if wall_climbing:
		return
	
	if is_on_wall_only() and velocity.y < 0.0:
		if wall_slide_enabled and can_wall_slide:
			# sliding mode
			velocity.y -= FALL_GRAVITY * delta
			if velocity.y < -MAX_WALL_SLIDE_SPEED:
				velocity.y += MAX_WALL_SLIDE_SPEED
		else:
			# falling mode
			velocity.y -= FALL_GRAVITY * delta
		return
	else:
		# Normal gravity
		var gravity = JUMP_GRAVITY if velocity.y > 0.0 else FALL_GRAVITY
		velocity.y -= gravity * delta

func validate_movement_states() -> void:
	# Reset states when landing
	if is_on_floor():
		wall_climbing = false
		just_wall_jumped = false
		wall_jump_timer = 0.0
		wall_jump_window_timer = 0.0
		
	# Can't slide while wall climbing
	if wall_climbing:
		sliding = false
	
	# SCENARIO 3: Start wall jump window when hitting wall in air
	if not is_on_floor() and is_on_wall_only():
		if enable_double_jump:
			# With double jump: Only start window if player has jumped
			if JUMPS_DONE >= 1 and wall_jump_window_timer <= 0:
				wall_jump_window_timer = 1.6
		else:
			# Without double jump: Start window immediately
			if wall_jump_window_timer <= 0:
				wall_jump_window_timer = 2
	
	# Set wall jump availability for "normal" wall contact
	if enable_double_jump:
		wall_jump_available = not is_on_floor() and is_on_wall_only() and (JUMPS_DONE >= 1 or wall_jump_window_timer > 0)
	else:
		wall_jump_available = not is_on_floor() and is_on_wall_only()

	# OVERRIDE: while actively wall climbing, one press must be enough
	if wall_climbing and not is_on_floor():
		wall_jump_available = true

#################################################
###           JUMP & WALL MECHANICS           ###
#################################################

func jump_logic(delta: float) -> void:
	if input_locked:
		return
	if not can_jump:
		return
	# Update wall jump window timer (still used only if you want some coyote-style feature)
	if wall_jump_window_timer > 0:
		wall_jump_window_timer -= delta

	if not Input.is_action_just_pressed("jump"):
		return
		
	# 1) Slide jump (floor slide)
	if sliding and can_slide:
		sliding = false
		free_looking = false
		velocity.y = - JUMP_VELOCITY
		JUMPS_DONE = 1
		return

	# 2) Normal ground jump
	if is_on_floor():
		velocity.y = - JUMP_VELOCITY
		JUMPS_DONE = 1
		return

	# 3) Wall-climb jump
	if wall_climbing and not is_on_floor() and can_wall_jump and wall_jump_available:
		var wall_is_ending = ray_cast_is_wall_check_F.is_colliding() \
			and !ray_cast_is_still_wall_check_F.is_colliding()
		
		if wall_is_ending:
			# LEDGE CASE: climb up instead of wall jump
			velocity.y = WALL_CLIMB_SPEED * 1.5
			if wait_time_1 <= 0:
				wait_time_1 = 0.5
		else:
			# CLIMBING BUT NOT ON LEDGE: always wall jump
			wall_jump_logic(delta)
			JUMPS_DONE = max(JUMPS_DONE, 1)
		return

	# 4) NORMAL WALL CONTACT (sliding, sticking, failed climb → slide, etc.)
	if is_on_wall_only() and not is_on_floor() and can_wall_jump and wall_jump_available:
		# Any time you are on a wall (but not ledge, because that was handled above),
		# you can wall jump with a single press.
		wall_jump_logic(delta)
		JUMPS_DONE = max(JUMPS_DONE, 1)
		return

	# 5) Double jump in open air (no wall)
	if not is_on_floor() and JUMPS_DONE < MAX_JUMPS and enable_double_jump and can_double_jump_mechanic:
		if velocity.y < 9 and velocity.y > -16:
			velocity.y = DOUBLE_JUMP_VELOCITY
			JUMPS_DONE += 1


func wall_jump_logic(_delta: float) -> void:
	if wall_climbing:
		stop_wall_climb()
	free_looking = false

	#if not wall_jump_available:
		#return

	var collision = get_last_slide_collision()
	if collision == null:
		return
	var wall_normal: Vector3 = collision.get_normal()

	var velocity_on_jump = velocity
	velocity = velocity_on_jump.bounce(wall_normal) # Reflect velocity
	velocity.y = - JUMP_VELOCITY # Add upward force

	# Update direction and speed
	wall_jump_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	wall_jump_speed = WALL_JUMP_HORIZONTAL_SPEED
	just_wall_jumped = true
	wall_jump_timer = wall_jump_max_duration
	
	# Turn towards the jumped direction
	target_wall_jump_yaw = atan2(wall_jump_direction.x, wall_jump_direction.z) + PI
	rotating_to_wall_jump = true

func _apply_wall_jump_turn(delta: float) -> void:
	if not rotating_to_wall_jump:
		return

	rotation.y = lerp_angle(rotation.y, target_wall_jump_yaw, WALL_JUMP_TURN_SPEED * delta)

	var ang_diff = abs(wrapf(target_wall_jump_yaw - rotation.y, -PI, PI))
	if ang_diff < deg_to_rad(2.0):
		rotation.y = target_wall_jump_yaw
		rotating_to_wall_jump = false
		neck.rotation.y = 0.0
		free_looking = false
func vertical_wall_climb(delta: float) -> void:
	if not can_wall_climb:
		if wall_climbing:
			stop_wall_climb()
		return
	
	var on_wall = ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding()
	var wall_is_ending = ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding()
	var no_wall = !ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding()
	var on_floor = ray_cast_is_on_floor.is_colliding() or is_on_floor()

	# HOLD to climb
	if Input.is_action_pressed("wall_climb"):
		if on_wall:
			# Start climbing whether in air or on floor
			if not wall_climbing:
				wall_climbing = true
				vertical_climb_timer.start(WALL_CLIMB_MAX_DURATION)
				tilt_camera_towards(climb_camera_rotation, delta)
				JUMPS_DONE = max(JUMPS_DONE, 1)

			# Constant climb upward
			velocity.y = WALL_CLIMB_SPEED

		# When you're already climbing and the wall is ending
		if wall_climbing and !on_floor:
			if wall_is_ending:
				velocity.y = WALL_CLIMB_SPEED * 1.5
				if wait_time_1 <= 0:
					wait_time_1 = 0.5
				wait_time_1 -= delta
				if wait_time_1 <= 0:
					stop_wall_climb()

		# Lose the wall: stop
		if wall_climbing and no_wall:
			stop_wall_climb()

		# Timer runs out: stop
		if wall_climbing and vertical_climb_timer.get_time_left() <= 0:
			stop_wall_climb()

	# Release key: stop
	if Input.is_action_just_released("wall_climb"):
		stop_wall_climb()

	# Optional: if you want to auto-stop when standing on ground with no wall:
	if on_floor and no_wall and wall_climbing:
		stop_wall_climb()

func stop_wall_climb() -> void:
	wall_climbing = false
	vertical_climb_timer.stop()
	disable_front_raycasts()
	tilt_camera_towards(default_camera_rotation, 0.1)


# Helper to check walls (Used for potential side-to-side logic)
func get_wall_collision():
	var on_wall_front = ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding()
	if ray_cast_is_wall_check_L.is_colliding() and !ray_cast_is_wall_check_R.is_colliding():
		wall_jump_available = true
		return ray_cast_is_wall_check_L.get_collision_normal()
	if !ray_cast_is_wall_check_L.is_colliding() and ray_cast_is_wall_check_R.is_colliding():
		wall_jump_available = true
		return -ray_cast_is_wall_check_R.get_collision_normal()
	if ray_cast_is_wall_check_L.is_colliding() and ray_cast_is_wall_check_R.is_colliding():
		wall_jump_available = false
		return (ray_cast_is_wall_check_L.get_collision_normal() + ray_cast_is_wall_check_R.get_collision_normal()).normalized()
	if on_wall_front:
		wall_jump_available = true
		return ray_cast_is_wall_check_F.get_collision_normal()
	if !ray_cast_is_still_wall_check_F.is_colliding() and ray_cast_is_wall_check_F.is_colliding():
		wall_jump_available = false
	else:
		return Vector3.ZERO


#################################################
###         STANCE, SLIDE & HELPERS           ###
#################################################

func handle_stance_and_sliding(delta: float, input_dir: Vector2) -> void:
	var crouch_down := Input.is_action_pressed("crouch") and can_crouch
	var crouch_pressed := Input.is_action_just_pressed("crouch") and can_crouch
	var head_blocked := ray_cast_crouch.is_colliding()

	if crouch_down or sliding or head_blocked:
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false

		# Start slide ONLY once (don't start a slide just because head is blocked)
		if crouch_pressed and sprinting and input_dir != Vector2.ZERO and is_on_floor() and not sliding and can_slide and not head_blocked:
			start_slide(input_dir)

		walking = false
		sprinting = false
		crouching = true

	else:
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		if Input.is_action_pressed("sprint") and can_sprint:
			current_speed = lerp(current_speed, sprinting_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = lerp(current_speed, walking_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false

func start_slide(input_dir: Vector2) -> void:
	sliding = true
	slide_vector = input_dir
	free_looking = true
	slide_timer = slide_timer_max

func stop_slide() -> void:
	sliding = false
	free_looking = false

func _update_slide(delta: float) -> void:
	if not sliding:
		return

	# 1) Stop if front ray hits obstacle
	if ray_cast_is_wall_check_F.is_colliding():
		stop_slide()
		return

	# 2) Stop if we leave the floor
	if not is_on_floor():
		stop_slide()
		return

	# 3) Timer expiration
	slide_timer -= delta
	if slide_timer <= 0.0:
		stop_slide()

func disable_front_raycasts() -> void:
	ray_cast_is_wall_check_F.enabled = false
	ray_cast_is_still_wall_check_F.enabled = false

func enable_front_raycasts() -> void:
	ray_cast_is_wall_check_F.enabled = true
	ray_cast_is_still_wall_check_F.enabled = true

func check_wall_contact() -> bool:
	return ray_cast_is_wall_check_F.is_colliding() and not is_on_floor()


#################################################
###           CAMERA & ANIMATIONS             ###
#################################################

func handle_head_bob(delta: float, input_dir: Vector2) -> void:
	if sprinting:
		head_bobbing_current_intensity = HEAD_BOBBING_SPRINTING_INTENSITY
		head_bobbing_index += HEAD_BOBBING_SPRINTING_SPEED * delta
	elif walking:
		head_bobbing_current_intensity = HEAD_BOBBING_WALKING_INTENSITY
		head_bobbing_index += HEAD_BOBBING_WALKING_SPEED * delta
	elif crouching:
		head_bobbing_current_intensity = HEAD_BOBBING_CROUCHING_INTENSITY
		head_bobbing_index += HEAD_BOBBING_CROUCHING_SPEED * delta
		
	if is_on_floor() and !sliding and input_dir != Vector2.ZERO:
		var current_sin := sin(head_bobbing_index)
		head_bobbing_vector.y = current_sin
		head_bobbing_vector.x = cos(head_bobbing_index / 2) # Figure-8 pattern
		
		# --- Footstep: fire on each downward zero-crossing of the sine (one step) ---
		if _prev_bob_sin >= 0.0 and current_sin < 0.0:
			_play_footstep()
		_prev_bob_sin = current_sin
		
		# Apply bobbing to head position
		var target_y = head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0)
		var target_x = head_bobbing_vector.x * head_bobbing_current_intensity
		
		head.position.y = lerp(head.position.y, target_y, delta * lerp_speed)
		head.position.x = lerp(head.position.x, target_x, delta * lerp_speed)
	else:
		# Reset head position when not moving
		_prev_bob_sin = 0.0
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		head.position.x = lerp(head.position.x, 0.0, delta * lerp_speed)

func _play_footstep() -> void:
	if not sfx_player or not sfx_player.stream:
		return
	# Pitch range scales with bobbing intensity:
	#   crouching (low intensity) → subtle, higher pitch
	#   sprinting (high intensity) → heavier, lower pitch
	var base_pitch := remap(head_bobbing_current_intensity, 0.05, 0.4, 1.2, 0.85)
	sfx_player.pitch_scale = base_pitch + randf_range(-0.56, 0.26)
	sfx_player.play()

func handle_free_look_and_sliding(delta: float) -> void:
	if (Input.is_action_pressed("free_look") and can_free_look) or sliding:
		free_looking = true
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(neck.rotation.y * free_look_tilt_amount), delta * lerp_speed)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * lerp_speed)

func tilt_camera_towards(target_rotation: Vector3, delta: float) -> void:
	camera_3d.rotation_degrees = lerp(camera_3d.rotation_degrees, target_rotation, camera_rotation_speed * delta)

func camera_tilt(input_x: float, delta: float) -> void:
	camera_3d.rotation.z = lerp(camera_3d.rotation.z, -input_x * cam_rotation_amount, 10 * delta)

func _update_fall_and_land_animations(on_floor_now: bool) -> void:
	# 1) Falling anim: in air and falling fast
	if not on_floor_now and velocity.y < FALL_VEL_THRESHOLD:
		if not eyes_anim.is_playing() or eyes_anim.current_animation != "Falling":
			eyes_anim.play("Falling")
	else:
		# If we are not falling fast (or are on the floor), stop "Falling"
		if eyes_anim.is_playing() and eyes_anim.current_animation == "Falling":
			eyes_anim.stop()

	# 2) Landing: just touched floor with high impact (use previous frame's vertical speed)
	if on_floor_now and not was_on_floor and last_vertical_velocity_y < LAND_VEL_THRESHOLD:
		_play_landing_sequence()

func _play_landing_sequence() -> void:
	if input_locked:
		return
		
	input_locked = true
	
	if eyes_anim.is_playing():
		eyes_anim.stop()
	eyes_anim.play("Landing")
	
	# Duration must match your "land" animation length
	await get_tree().create_timer(1.5).timeout

	input_locked = false
	
	Engine.time_scale = 0.5
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 1
	# After landing, return to idle/default anim if needed
	if not is_on_floor():
		return
