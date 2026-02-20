extends CharacterBody3D

#################################################
###              NODE REFERENCES              ###
#################################################

@onready var neck: Node3D = $neck
@onready var head: Node3D = $neck/head
@onready var eyes: Node3D = $neck/head/eyes
@onready var camera_3d: Camera3D = $neck/head/eyes/Camera3D
@onready var animation_player: AnimationPlayer = $neck/head/eyes/AnimationPlayer
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_crouch: RayCast3D = $RayCast_Crouch
@onready var vertical_climb_timer: Timer = $Vertical_Climb_Timer

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
@export var lerp_speed: float = 10.0
@export var air_lerp_speed: float = 1.0
@export var walking_speed: float = 9.0
@export var sprinting_speed: float = 16.0
@export var crouching_speed: float = 5.0
@export var crouching_depth: float = -0.5
@export var slide_speed: float = 10.0

@export_group("Jump Settings")
@export var JUMP_HEIGHT: float = 4.0
@export var JUMP_TIME_TO_PEAK: float = 0.4
@export var JUMP_TIME_TO_DESCENT: float = 0.3
@export var DOUBLE_JUMP_VELOCITY: float = 20.0
@export var enable_double_jump: bool = true

@export_group("Wall Mechanics")
@export var WALL_CLIMB_SPEED: float = 9.0
@export var WALL_CLIMB_GRAVITY: float = 3.0
@export var WALL_CLIMB_MAX_DURATION: float = 1.0
@export var WALL_CLIMB_JUMP_BOOST: float = 1.0
@export var MAX_WALL_SLIDE_SPEED: float = 10.0
@export var WALL_JUMP_HORIZONTAL_SPEED: float = 16.0
@export var WALL_JUMP_TURN_SPEED: float = 10.0

@onready var JUMP_VELOCITY: float = ((2.0 * JUMP_HEIGHT) / JUMP_TIME_TO_PEAK) * -1.0
@onready var JUMP_GRAVITY: float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK)) * -1.0
@onready var FALL_GRAVITY: float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0

#################################################
###            STATE MACHINE                  ###
#################################################

enum PlayerState {
	IDLE,
	WALK,
	SPRINT,
	CROUCH,
	SLIDE,
	JUMP,
	FALL,
	WALL_SLIDE,
	WALL_CLIMB,
	WALL_JUMP
}

var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

#################################################
###            STATE VARIABLES                ###
#################################################

var current_speed: float = 5.0
var direction: Vector3 = Vector3.ZERO
var local_velocity: Vector3 = Vector3.ZERO
var horizontal_velocity: Vector3 = Vector3.ZERO
var slide_vector: Vector2 = Vector2.ZERO

var wall_slide_enabled: bool = true
var can_wall_jump: bool = false
var can_double_jump: bool = false
var just_wall_jumped: bool = false
var rotating_to_wall_jump: bool = false
var free_looking: bool = false

const MAX_JUMPS: int = 2
var JUMPS_DONE: int = 0
var wait_time_1: float = 0.0
var wall_jump_timer: float = 0.0
var wall_jump_window_timer: float = 0.0
var wall_jump_max_duration: float = 0.3
var slide_timer: float = 0.0
var slide_timer_max: float = 1.6

var wall_jump_direction: Vector3 = Vector3.ZERO
var wall_jump_speed: float = 0.0
var target_wall_jump_yaw: float = 0.0

const HEAD_BOBBING_SPRINTING_SPEED = 22.0
const HEAD_BOBBING_WALKING_SPEED = 14.0
const HEAD_BOBBING_CROUCHING_SPEED = 10.0
const HEAD_BOBBING_SPRINTING_INTENSITY = 0.2
const HEAD_BOBBING_WALKING_INTENSITY = 0.1
const HEAD_BOBBING_CROUCHING_INTENSITY = 0.05

var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0
var head_bobbing_current_intensity: float = 0.0

var default_camera_rotation: Vector3 = Vector3.ZERO
var climb_camera_rotation: Vector3 = Vector3(-20, 0, 0)
var landing_camera_offset: Vector3 = Vector3(5, 0, 0)

#################################################
###           LIFECYCLE FUNCTIONS             ###
#################################################

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	can_wall_jump = false
	wall_slide_enabled = true
	change_state(PlayerState.IDLE)

func _process(_delta: float) -> void:
	local_velocity = global_transform.basis.inverse() * velocity

func _physics_process(delta: float) -> void:
	_apply_wall_jump_turn(delta)
	update_state(delta)
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	handle_free_look_and_sliding(delta)
	handle_head_bob(delta, input_dir)
	camera_tilt(input_dir.x, delta)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if rotating_to_wall_jump:
		return
		
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(89))

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_wall_slide"):
		wall_slide_enabled = !wall_slide_enabled
		
	if event is InputEventKey and event.pressed and Input.is_action_pressed("escape"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#################################################
###         STATE MACHINE LOGIC               ###
#################################################

func change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return
	
	exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	enter_state(new_state)

func enter_state(state: PlayerState) -> void:
	match state:
		PlayerState.IDLE:
			current_speed = walking_speed
		PlayerState.WALK:
			current_speed = walking_speed
		PlayerState.SPRINT:
			current_speed = sprinting_speed
		PlayerState.CROUCH:
			current_speed = crouching_speed
			standing_collision_shape.disabled = true
			crouching_collision_shape.disabled = false
		PlayerState.SLIDE:
			free_looking = true
			slide_timer = slide_timer_max
			standing_collision_shape.disabled = true
			crouching_collision_shape.disabled = false
		PlayerState.WALL_CLIMB:
			vertical_climb_timer.start(WALL_CLIMB_MAX_DURATION)
			JUMPS_DONE = max(JUMPS_DONE, 1)
			disable_front_raycasts()
		PlayerState.WALL_JUMP:
			just_wall_jumped = true
			wall_jump_timer = wall_jump_max_duration

func exit_state(state: PlayerState) -> void:
	match state:
		PlayerState.SLIDE:
			free_looking = false
		PlayerState.WALL_CLIMB:
			vertical_climb_timer.stop()
			enable_front_raycasts()
			tilt_camera_towards(default_camera_rotation, 0.1)
		PlayerState.WALL_JUMP:
			just_wall_jumped = false

func update_state(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Update global conditions
	update_wall_conditions()
	
	if is_on_floor():
		JUMPS_DONE = 0
		enable_front_raycasts()
	
	# State-specific updates
	match current_state:
		PlayerState.IDLE:
			update_idle_state(delta, input_dir)
		PlayerState.WALK:
			update_walk_state(delta, input_dir)
		PlayerState.SPRINT:
			update_sprint_state(delta, input_dir)
		PlayerState.CROUCH:
			update_crouch_state(delta, input_dir)
		PlayerState.SLIDE:
			update_slide_state(delta, input_dir)
		PlayerState.JUMP, PlayerState.FALL:
			update_air_state(delta, input_dir)
		PlayerState.WALL_SLIDE:
			update_wall_slide_state(delta, input_dir)
		PlayerState.WALL_CLIMB:
			update_wall_climb_state(delta, input_dir)
		PlayerState.WALL_JUMP:
			update_wall_jump_state(delta, input_dir)
	
	# Apply physics
	apply_movement(delta, input_dir)
	handle_jump_input(delta)

func update_idle_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	
	if not is_on_floor():
		change_state(PlayerState.FALL)
	elif Input.is_action_pressed("crouch"):
		change_state(PlayerState.CROUCH)
	elif input_dir != Vector2.ZERO:
		if Input.is_action_pressed("sprint"):
			change_state(PlayerState.SPRINT)
		else:
			change_state(PlayerState.WALK)

func update_walk_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	lerp_speed_to(walking_speed, delta)
	head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
	standing_collision_shape.disabled = false
	crouching_collision_shape.disabled = true
	
	if not is_on_floor():
		change_state(PlayerState.FALL)
	elif Input.is_action_pressed("crouch"):
		change_state(PlayerState.CROUCH)
	elif Input.is_action_pressed("sprint") and input_dir != Vector2.ZERO:
		change_state(PlayerState.SPRINT)
	elif input_dir == Vector2.ZERO:
		change_state(PlayerState.IDLE)

func update_sprint_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	lerp_speed_to(sprinting_speed, delta)
	head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
	standing_collision_shape.disabled = false
	crouching_collision_shape.disabled = true
	
	if not is_on_floor():
		change_state(PlayerState.FALL)
	elif Input.is_action_just_pressed("crouch") and input_dir != Vector2.ZERO:
		slide_vector = input_dir
		change_state(PlayerState.SLIDE)
	elif not Input.is_action_pressed("sprint"):
		change_state(PlayerState.WALK)
	elif input_dir == Vector2.ZERO:
		change_state(PlayerState.IDLE)

func update_crouch_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	lerp_speed_to(crouching_speed, delta)
	head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
	
	if not is_on_floor():
		change_state(PlayerState.FALL)
	elif not Input.is_action_pressed("crouch") and not ray_cast_crouch.is_colliding():
		if Input.is_action_pressed("sprint"):
			change_state(PlayerState.SPRINT)
		elif input_dir != Vector2.ZERO:
			change_state(PlayerState.WALK)
		else:
			change_state(PlayerState.IDLE)

func update_slide_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	
	slide_timer -= delta
	current_speed = slide_timer * slide_speed
	head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
	
	# Stop conditions
	if ray_cast_is_wall_check_F.is_colliding() or not is_on_floor() or slide_timer <= 0.0:
		if not Input.is_action_pressed("crouch") and not ray_cast_crouch.is_colliding():
			change_state(PlayerState.IDLE)
		else:
			change_state(PlayerState.CROUCH)

func update_air_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	
	if is_on_floor():
		change_state(PlayerState.IDLE)
	elif is_on_wall_only() and Input.is_action_pressed("wall_run"):
		var on_wall = ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding()
		if on_wall:
			change_state(PlayerState.WALL_CLIMB)
	elif is_on_wall_only() and wall_slide_enabled and velocity.y < 0:
		change_state(PlayerState.WALL_SLIDE)

func update_wall_slide_state(delta: float, input_dir: Vector2) -> void:
	velocity.y -= FALL_GRAVITY * delta
	if velocity.y < -MAX_WALL_SLIDE_SPEED:
		velocity.y += MAX_WALL_SLIDE_SPEED
	
	if is_on_floor():
		change_state(PlayerState.IDLE)
	elif not is_on_wall_only():
		change_state(PlayerState.FALL)
	elif Input.is_action_pressed("wall_run"):
		var on_wall = ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding()
		if on_wall:
			change_state(PlayerState.WALL_CLIMB)

func update_wall_climb_state(delta: float, input_dir: Vector2) -> void:
	var on_wall = ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding()
	var wall_is_ending = ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding()
	var no_wall = !ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding()
	var on_floor = ray_cast_is_on_floor.is_colliding() or is_on_floor()
	
	tilt_camera_towards(climb_camera_rotation, delta)
	
	if Input.is_action_pressed("wall_run"):
		if on_wall and not on_floor:
			velocity.y = WALL_CLIMB_SPEED
		elif wall_is_ending:
			velocity.y = WALL_CLIMB_SPEED * 1.5
			if wait_time_1 <= 0:
				wait_time_1 = 0.5
			wait_time_1 -= delta
			if wait_time_1 <= 0:
				change_state(PlayerState.FALL)
		elif no_wall or on_floor or vertical_climb_timer.get_time_left() <= 0:
			change_state(PlayerState.FALL)
	else:
		change_state(PlayerState.FALL)

func update_wall_jump_state(delta: float, input_dir: Vector2) -> void:
	apply_gravity(delta)
	
	wall_jump_timer -= delta
	
	var wall_influence = wall_jump_timer / wall_jump_max_duration
	
	if direction != Vector3.ZERO:
		direction = lerp(direction, wall_jump_direction, wall_influence * 0.8)
	else:
		direction = wall_jump_direction * wall_influence
	
	current_speed = max(current_speed, wall_jump_speed * wall_influence)
	
	if wall_jump_timer <= 0:
		change_state(PlayerState.FALL)
	elif is_on_floor():
		change_state(PlayerState.IDLE)

func update_wall_conditions() -> void:
	if not is_on_floor() and is_on_wall_only():
		if enable_double_jump:
			if JUMPS_DONE >= 1 and wall_jump_window_timer <= 0:
				wall_jump_window_timer = 1.6
		else:
			if wall_jump_window_timer <= 0:
				wall_jump_window_timer = 2
	
	if enable_double_jump:
		can_wall_jump = not is_on_floor() and is_on_wall_only() and (JUMPS_DONE >= 1 or wall_jump_window_timer > 0)
	else:
		can_wall_jump = not is_on_floor() and is_on_wall_only()

#################################################
###           MOVEMENT & PHYSICS              ###
#################################################

func apply_movement(delta: float, input_dir: Vector2) -> void:
	# Calculate direction
	if current_state == PlayerState.SLIDE:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	elif is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)
	
	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

func apply_gravity(delta: float) -> void:
	var gravity = JUMP_GRAVITY if velocity.y > 0.0 else FALL_GRAVITY
	velocity.y -= gravity * delta

func lerp_speed_to(target_speed: float, delta: float) -> void:
	current_speed = lerp(current_speed, target_speed, delta * lerp_speed)

func handle_jump_input(delta: float) -> void:
	if wall_jump_window_timer > 0:
		wall_jump_window_timer -= delta
	
	if not Input.is_action_just_pressed("jump"):
		return
	
	match current_state:
		PlayerState.IDLE, PlayerState.WALK, PlayerState.SPRINT:
			velocity.y = -JUMP_VELOCITY
			JUMPS_DONE = 1
			change_state(PlayerState.JUMP)
		
		PlayerState.CROUCH, PlayerState.SLIDE:
			velocity.y = -JUMP_VELOCITY
			JUMPS_DONE = 1
			if not ray_cast_crouch.is_colliding():
				change_state(PlayerState.JUMP)
		
		PlayerState.WALL_CLIMB:
			var wall_is_ending = ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding()
			
			if wall_is_ending:
				velocity.y = WALL_CLIMB_SPEED * 1.5
				if wait_time_1 <= 0:
					wait_time_1 = 0.5
			else:
				perform_wall_jump()
				JUMPS_DONE += 1
				change_state(PlayerState.WALL_JUMP)
		
		PlayerState.WALL_SLIDE:
			var can_wall_jump_now = false
			
			if enable_double_jump:
				can_wall_jump_now = (JUMPS_DONE >= 1 or wall_jump_window_timer > 0)
			else:
				can_wall_jump_now = true
			
			if can_wall_jump_now:
				perform_wall_jump()
				JUMPS_DONE += 1
				change_state(PlayerState.WALL_JUMP)
		
		PlayerState.JUMP, PlayerState.FALL:
			if is_on_wall_only():
				var can_wall_jump_now = false
				
				if enable_double_jump:
					can_wall_jump_now = (JUMPS_DONE >= 1 or wall_jump_window_timer > 0)
				else:
					can_wall_jump_now = true
				
				if can_wall_jump_now:
					perform_wall_jump()
					JUMPS_DONE += 1
					change_state(PlayerState.WALL_JUMP)
			elif JUMPS_DONE < MAX_JUMPS and enable_double_jump:
				if velocity.y < 9 and velocity.y > -16:
					velocity.y = DOUBLE_JUMP_VELOCITY
					JUMPS_DONE += 1

func perform_wall_jump() -> void:
	free_looking = false
	
	if not can_wall_jump:
		return
	
	var collision = get_last_slide_collision()
	if collision == null:
		return
	
	var wall_normal: Vector3 = collision.get_normal()
	var velocity_on_jump = velocity
	velocity = velocity_on_jump.bounce(wall_normal)
	velocity.y = -JUMP_VELOCITY
	
	wall_jump_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	wall_jump_speed = WALL_JUMP_HORIZONTAL_SPEED
	
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

#################################################
###              HELPERS                      ###
#################################################

func disable_front_raycasts() -> void:
	ray_cast_is_wall_check_F.enabled = false
	ray_cast_is_still_wall_check_F.enabled = false

func enable_front_raycasts() -> void:
	ray_cast_is_wall_check_F.enabled = true
	ray_cast_is_still_wall_check_F.enabled = true

func get_wall_collision():
	var on_wall_front = ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding()
	if ray_cast_is_wall_check_L.is_colliding() and !ray_cast_is_wall_check_R.is_colliding():
		can_wall_jump = true
		return ray_cast_is_wall_check_L.get_collision_normal()
	if !ray_cast_is_wall_check_L.is_colliding() and ray_cast_is_wall_check_R.is_colliding():
		can_wall_jump = true
		return -ray_cast_is_wall_check_R.get_collision_normal()
	if ray_cast_is_wall_check_L.is_colliding() and ray_cast_is_wall_check_R.is_colliding():
		can_wall_jump = false
		return (ray_cast_is_wall_check_L.get_collision_normal() + ray_cast_is_wall_check_R.get_collision_normal()).normalized()
	if on_wall_front:
		can_wall_jump = true
		return ray_cast_is_wall_check_F.get_collision_normal()
	if !ray_cast_is_still_wall_check_F.is_colliding() and ray_cast_is_wall_check_F.is_colliding():
		can_wall_jump = false
	else:
		return Vector3.ZERO

#################################################
###           CAMERA & ANIMATIONS             ###
#################################################

func handle_head_bob(delta: float, input_dir: Vector2) -> void:
	match current_state:
		PlayerState.SPRINT:
			head_bobbing_current_intensity = HEAD_BOBBING_SPRINTING_INTENSITY
			head_bobbing_index += HEAD_BOBBING_SPRINTING_SPEED * delta
		PlayerState.WALK:
			head_bobbing_current_intensity = HEAD_BOBBING_WALKING_INTENSITY
			head_bobbing_index += HEAD_BOBBING_WALKING_SPEED * delta
		PlayerState.CROUCH:
			head_bobbing_current_intensity = HEAD_BOBBING_CROUCHING_INTENSITY
			head_bobbing_index += HEAD_BOBBING_CROUCHING_SPEED * delta
	
	if is_on_floor() and current_state != PlayerState.SLIDE and input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5
		head.position.y = lerp(head.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity / 2), delta * lerp_speed)
		head.position.x = lerp(head.position.x, head_bobbing_vector.x * head_bobbing_current_intensity, delta * lerp_speed)
	else:
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		head.position.x = lerp(head.position.x, 0.0, delta * lerp_speed)

func handle_free_look_and_sliding(delta: float) -> void:
	if Input.is_action_pressed("free_look") or current_state == PlayerState.SLIDE:
		free_looking = true
		if current_state == PlayerState.SLIDE:
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
