extends State

func enter(previous_state: String, data: Dictionary = {}) -> void:
	print("Entering Running State")
	player.current_speed = player.sprinting_speed

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y -= player.fall_gravity * delta
	
	# Get input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Check for state transitions
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		finished.emit("JumpingState")
		return
	
	if Input.is_action_pressed("crouch") and input_dir != Vector2.ZERO:
		# Initiate sliding
		player.slide_vector = input_dir
		player.slide_timer = player.slide_timer_max
		finished.emit("SlidingState")
		return
	elif Input.is_action_pressed("crouch"):
		finished.emit("CrouchingState")
		return
	
	if input_dir == Vector2.ZERO:
		finished.emit("IdleState")
		return
	
	if not Input.is_action_pressed("sprint"):
		finished.emit("WalkingState")
		return
	
	# Apply movement (similar to walking but faster)
	if player.is_on_floor():
		player.direction = lerp(player.direction, 
			(player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), 
			delta * player.lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			player.direction = lerp(player.direction,
				(player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * player.air_lerp_speed)
	
	player.velocity.x = player.direction.x * player.current_speed
	player.velocity.z = player.direction.z * player.current_speed
	
	# Apply head bobbing (more intense for running)
	player.apply_head_bobbing(
		player.head_bobbing_sprinting_intensity,
		player.head_bobbing_sprinting_speed, 
		delta
	)
	
	# Apply camera tilt
	player.apply_camera_tilt(input_dir.x, delta)
	
	player.move_and_slide()
	
	# Check if we're no longer on the floor
	if not player.is_on_floor():
		finished.emit("FallingState")
