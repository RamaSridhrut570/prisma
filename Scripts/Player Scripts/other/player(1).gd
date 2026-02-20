extends CharacterBody3D
### NODE EXPORTS (Scene References)
@export var neck: Node
@export var head: Node
@export var camera_3d: Node
@export var eyes: Node
@export var standing_collision_shape: Node
@export var crouching_collision_shape: Node
@export var ray_cast_3d: Node
@export var animation_player: Node
@export var pivot: Node
@export var weapon: CharacterBody3D
@export var hand: Marker3D
@export var ray_cast_is_wall_check_L: RayCast3D
@export var ray_cast_is_wall_check_R: RayCast3D
@export var ray_cast_is_wall_check_F: RayCast3D
@export var ray_cast_is_still_wall_check_F: RayCast3D
@export var ray_cast_is_in_air: RayCast3D
@export var weapon_pivot: Node3D
@export var hitbox: Area3D


### UI REFERENCES
@onready var equipped_state_icon: Sprite2D = $"UI Interface/Equipped_state"
@onready var not_equipped_state_icon: Sprite2D = $"UI Interface/Not_Equipped_state"
@onready var weapon_status_particles: GPUParticles2D = $"UI Interface/weapon_status_particles"
@onready var player_health: ProgressBar = $"UI Interface/Player_Health"
@onready var pause_menu_canvas: CanvasLayer = $"Pause Menu Canvas"

### CAMERA SETTINGS
@export var cam_rotation_amount: float = 0.05
@export var weapon_rotation_amount: float = 0.05
@export var weapon_sway_amount: float = 0.075
@export var mouse_sens: float = 0.2
@export var free_look_tilt_amount: float = 4
@export var camera_rotation_speed: float = 5.0
var mouse_input: Vector2

### MOVEMENT VARIABLES
@export var lerp_speed: float = 10.0
@export var air_lerp_speed: float = 1.0
@export var current_speed: float = 5.0
@export var walking_speed: float = 10.0
@export var sprinting_speed: float = 18.0
@export var crouching_speed: float = 8.0
@export var crouching_depth: float = -0.5

### JUMP VARIABLES
@export var jump_velocity: float = 5.5
@export var JUMP_HEIGHT: float = 8
@export var JUMP_TIME_TO_PEAK: float = 0.4
@export var JUMP_TIME_TO_DESCENT: float = 0.3
@onready var JUMP_VELOCITY: float = ((2.0 * JUMP_HEIGHT)/ JUMP_TIME_TO_PEAK) * -1.0
@onready var JUMP_GRAVITY: float = ((-2.0 * JUMP_HEIGHT)/ (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK)) * -1.0
@onready var FALL_GRAVITY: float = ((-2.0 * JUMP_HEIGHT)/ (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0

### WALL CLIMBING VARIABLES
@export var WALL_CLIMB_SPEED: float = 11.75
@export var WALL_CLIMB_GRAVITY: float = 3.0
@export var WALL_CLIMB_MAX_DURATION: float = 1.1
@export var WALL_CLIMB_JUMP_BOOST: float = 1.0
@export var vertical_climb_timer: Timer
var wall_climbing: bool = false

### WEAPON HOLDING
var def_hand_pos : Vector3
var def_hand_rot : Vector3

### CAMERA TRANSFORMATIONS (For Effects)
var default_camera_rotation: Vector3 = Vector3.ZERO  # Default camera rotation
var climb_camera_rotation: Vector3 = Vector3(-20, 0, 0)  # Camera tilt during climb
var landing_camera_offset: Vector3 = Vector3(5, 0, 0)  # Camera bounce offset on landing

### CAMERA FRAME INTERPOLATION
var gt_prev: Transform3D
var gt_current: Transform3D
var mesh_gt_prev: Transform3D
var mesh_gt_current: Transform3D

### PLAYER HEALTH
@export var max_health: int = 100
var current_health: int = max_health

### PLAYER STATES
var walking: bool = false
var sprinting: bool = false
var crouching: bool = false
var free_looking: bool = false
var sliding: bool = false
var input_locked: bool = false

### SLIDE VARIABLES
var slide_timer: float = 0.0
var slide_timer_max: float = 1.6
var slide_vector: Vector2 = Vector2.ZERO
@export var slide_speed: float = 20.0

### HEAD BOBBING VARIABLES
const head_bobbing_sprinting_speed: float = 22.0
const head_bobbing_walking_speed: float = 14.0
const head_bobbing_crouching_speed: float = 10.0
const head_bobbing_sprinting_intensity: float = 0.2
const head_bobbing_walking_intensity: float = 0.1
const head_bobbing_crouching_intensity: float = 0.05
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0
var head_bobbing_current_intensity: float = 0.0

### MOVEMENT DIRECTION
var direction: Vector3 = Vector3.ZERO

### Preloading Scenes




# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_camera_rotation = camera_3d.rotation_degrees

	# Store the initial position of the hand node for weapon bobbing
	#def_hand_pos = camera_3d.global_transform.origin + camera_3d.global_transform.basis * Vector3(2, -1, -1)
	def_hand_pos = hand.global_position
	def_hand_rot = camera_3d.global_transform.basis.get_euler()
	#def_hand_rot = -camera_3d.global_rotation + hand.global_rotation


func _process(_delta: float) -> void:
	#Updating the Health Bar
	player_health.value = current_health
	
	weapon_status()
	if Input.is_action_just_pressed("light_attack"):
		weapon.handle_light_attack_input()
	
	if Input.is_action_just_pressed("recall"):
			weapon.recall()
	
	


func _input(event):
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(89))
	


func weapon_status():
	if weapon.state == weapon.STATE.HELD:
		weapon_status_particles.emitting = true
		equipped_state_icon.show()
		not_equipped_state_icon.hide()
		
		
	else:
		weapon_status_particles.emitting = false
		equipped_state_icon.hide()
		not_equipped_state_icon.show()




func vertical_wall_climb(delta):
	# Start vertical climb if player is in the air and colliding with a front wall
	if !ray_cast_is_in_air.is_colliding() and ray_cast_is_wall_check_F.is_colliding() and ray_cast_is_still_wall_check_F.is_colliding():
		if Input.is_action_pressed("jump"):
			if not wall_climbing:
				wall_climbing = true
				vertical_climb_timer.start(WALL_CLIMB_MAX_DURATION)
				print("Timer started:", vertical_climb_timer.get_time_left())
				# Start camera tilt up
				tilt_camera_towards(climb_camera_rotation, delta)
		# Apply vertical climbing velocity
		velocity.y = WALL_CLIMB_SPEED
		
	# If the player is partially climbing (one ray detects the wall)
	elif !ray_cast_is_in_air.is_colliding() and ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding():
		velocity.y = WALL_CLIMB_SPEED * 1.5
		var wait_time_1 = 0.5
		if wait_time_1 > 0:
			wait_time_1 -= delta
		else:
			wait_time_1 = 0
			if wait_time_1 == 0:
				stop_wall_climb()
	elif !ray_cast_is_in_air.is_colliding() and !ray_cast_is_wall_check_F.is_colliding() and !ray_cast_is_still_wall_check_F.is_colliding():
		stop_wall_climb()

	# Stop climbing when the player makes it to the top of the wall
	if is_on_floor() and !ray_cast_is_wall_check_F.is_colliding():
		#print("Player reached the top of the wall")
		stop_wall_climb()

	# Stop climbing when the timer expires
	if vertical_climb_timer.get_time_left() <= 0:
		stop_wall_climb()


func stop_wall_climb():
	wall_climbing = false
	vertical_climb_timer.stop()
	disable_front_raycasts()
	# Reset camera to default
	tilt_camera_towards(default_camera_rotation, 0.1)


func disable_front_raycasts():
	ray_cast_is_wall_check_F.enabled = false
	ray_cast_is_still_wall_check_F.enabled = false
	#print("Front Raycasts disabled")


func enable_front_raycasts():
	ray_cast_is_wall_check_F.enabled = true
	ray_cast_is_still_wall_check_F.enabled = true
	#print("Front Raycasts enabled")


func disable_side_raycasts():
	ray_cast_is_wall_check_L.enabled = false
	ray_cast_is_wall_check_R.enabled = false
	#print("Side Raycasts disabled")


func enable_side_raycasts():
	ray_cast_is_wall_check_L.enabled = true
	ray_cast_is_wall_check_R.enabled = true
	#print("Side Raycasts enabled")



func jump_logic(delta):
	# Vertical climb jump logic
	if wall_climbing and Input.is_action_just_pressed("jump"):
		velocity.y = -WALL_CLIMB_JUMP_BOOST  # Apply a higher vertical jump boost for climbing
		#stop_wall_climb()  # Stop the vertical climb after jumping

	# Normal jump logic when on the ground
	elif is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -JUMP_VELOCITY  # Apply regular jump velocity

	# Apply gravity when not wall running or climbing
	if !wall_climbing:
		var gravity = JUMP_GRAVITY if velocity.y > 0.0 else FALL_GRAVITY
		velocity.y -= gravity * delta


func tilt_camera_towards(target_rotation: Vector3, delta):
	"""Smoothly tilt the camera towards a target rotation."""
	camera_3d.rotation_degrees = lerp(
		camera_3d.rotation_degrees,
		target_rotation,
		camera_rotation_speed * delta
	)


func camera_tilt(input_x, delta):
	camera_3d.rotation.z = lerp(camera_3d.rotation.z, -input_x * cam_rotation_amount, 10 * delta)

func weapon_tilt(input_x, input_y, delta):
	if hand:
		hand.rotation.z = lerp(hand.rotation.z, -input_x * weapon_rotation_amount, 10 * delta)
		hand.rotation.x = lerp(hand.rotation.x, -input_y * weapon_rotation_amount * 2, 10 * delta)

func weapon_sway(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
	hand.rotation.x = lerp(hand.rotation.x, mouse_input.y * weapon_rotation_amount, 10 * delta)
	hand.rotation.y = lerp(hand.rotation.y, mouse_input.x * weapon_rotation_amount, 10 * delta)

func landing_camera_bounce(delta):
	"""Add a brief camera bounce effect when landing."""
	var bounce_rotation = default_camera_rotation + landing_camera_offset
	camera_3d.rotation_degrees = lerp(
		camera_3d.rotation_degrees,
		bounce_rotation,
		camera_rotation_speed * delta
	)

	# Return to default camera rotation after the bounce
	camera_3d.rotation_degrees = lerp(
		camera_3d.rotation_degrees,
		default_camera_rotation,
		camera_rotation_speed * delta * 2.0
	)

func _physics_process(delta):
	# Check for landing to trigger bounce effect
	if is_on_floor() and !wall_climbing:
		landing_camera_bounce(delta)
	#Handle Vertical wall climbing
	vertical_wall_climb(delta)
	
	# Handle jumping
	jump_logic(delta)
	
	
	# Ensure raycasts are re-enabled when the player is on the ground
	if is_on_floor():
		ray_cast_is_wall_check_F.enabled = true
		ray_cast_is_still_wall_check_F.enabled = true
		ray_cast_is_wall_check_L.enabled = true
		ray_cast_is_wall_check_R.enabled = true
	
	
	#Getting movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	
	if Input.is_action_pressed("crouch") || sliding:
		#crouching state
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		#slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_vector = input_dir
			free_looking = true
			slide_timer = slide_timer_max
		
		walking = false
		sprinting = false
		crouching = true
		
		
	elif !ray_cast_3d.is_colliding():
		#standing state
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			#sprinting
			current_speed = lerp(current_speed, sprinting_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
			
		else:
			#walking
			current_speed = lerp(current_speed, walking_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false
	
	#Handle Free looking
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(neck.rotation.y * free_look_tilt_amount), delta * lerp_speed)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0,delta * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0,delta * lerp_speed)
	
	#Handle Sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
	
	
	#Handle Head Bob
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2) + 0.5
		head.position.y = lerp(head.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity/2), delta * lerp_speed)
		head.position.x = lerp(head.position.x, head_bobbing_vector.x * head_bobbing_current_intensity, delta * lerp_speed)
	
	else:
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		head.position.x = lerp(head.position.x, 0.0, delta * lerp_speed)
	

	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*air_lerp_speed)
	
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0,slide_vector.y)).normalized()
		current_speed =  (slide_timer) * slide_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	camera_tilt(input_dir.x, delta)
	weapon_tilt(input_dir.x, input_dir.y, delta)
	weapon_sway(delta)
	
# Camera set up to prevent jitter.
func camera_setup():
	camera_3d.set_as_top_level(true)
	
	camera_3d.global_transform = pivot.global_transform
	
	gt_prev = pivot.global_transform
	
	gt_current = pivot.global_transform
	
# Updating transform to interpolate the camera's movement for smoothness. 
func update_transform():
	gt_prev = gt_current
	gt_current = pivot.global_transform


func take_damage(damage: int):
	if current_health > 0:
		current_health -= damage
		print("Player hit! Health:", current_health)
		
		# Check if player is dead
		if current_health <= 0:
			die()

func die():
	get_tree().change_scene_to_file("res://Scenes/Menus/Death_Screen.tscn")


func _on_vertical_climb_timer_timeout() -> void:
	pass
	

'''
func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		area.get_parent().take_damage(10)  # Adjust damage value as needed
'''

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(15)
