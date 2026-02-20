extends State

func enter(previous_state: String, data: Dictionary = {}) -> void:
	print("Entering Idle State")
	player.current_speed = 0.0

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
	
	if Input.is_action_pressed("crouch"):
		finished.emit("CrouchingState")
		return
	
	if input_dir != Vector2.ZERO:
		if Input.is_action_pressed("sprint"):
			finished.emit("RunningState")
		else:
			finished.emit("WalkingState")
		return
	
	# Apply movement (should be minimal in idle)
	player.velocity.x = move_toward(player.velocity.x, 0, player.walking_speed)
	player.velocity.z = move_toward(player.velocity.z, 0, player.walking_speed)
	
	player.move_and_slide()
	
	# Check if we're no longer on the floor
	if not player.is_on_floor() and player.velocity.y < 0:
		finished.emit("FallingState")
