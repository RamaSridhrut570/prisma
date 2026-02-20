extends CharacterBody3D

### NODE REFERENCES ###
@onready var neck: Node3D = $neck
@onready var head: Node3D = $neck/head
@onready var camera_3d: Camera3D = $neck/head/eyes/Camera3D
@onready var eyes: Node3D = $neck/head/eyes
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_crouch: RayCast3D = $RayCast_Crouch
@onready var ray_cast_is_wall_check_f: RayCast3D = $RayCast_is_wall_check_F
@onready var ray_cast_is_still_wall_check_f: RayCast3D = $RayCast_is_still_wall_check_F
@onready var ray_cast_is_in_air: RayCast3D = $RayCast_is_in_air
@onready var vertical_climb_timer: Timer = $Vertical_Climb_Timer
@onready var animation_player: AnimationPlayer = $neck/head/eyes/AnimationPlayer


### CAMERA SETTINGS ###
@export var mouse_sens: float = 0.2
@export var cam_rotation_amount: float = 0.05
@export var free_look_tilt_amount: float = 4
@export var camera_rotation_speed: float = 5.0
var mouse_input: Vector2



const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(89))
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and Input.is_action_pressed("escape"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
