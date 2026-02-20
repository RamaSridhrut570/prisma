extends State

func enter(previous_state: String, data: Dictionary = {}) -> void:
	print("Entering Jumping State")
	player.velocity.y = -player.jump_velocity

func physics_update(delta: float) -> void:
	# Apply gravity
	var gravity = player.jump_gravity if player.velocity.y > 0.0 else player.fall_gravity
	player.velocity.y -= gravity * delta
	
	# Get input for air control
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Air movement control
	if input_dir != Vector2.ZERO:
		player.direction = lerp(player.direction,
			(player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
			delta * player.air_lerp_speed)
	
	player.velocity.x = player.direction.x * player.current_speed
	player.velocity.z = player.direction.z * player.current_speed
	
	# Check for wall climbing
	# Only enter wall climbing when the dedicated wall-run/climb input is held.
	# This prevents the Jump button from acting as the climb input when tapped or held.
	if (not player.ray_cast_is_in_air.is_colliding() and 
		player.ray_cast_is_wall_check_F.is_colliding() and 
		Input.is_action_pressed("wall_run")):
		finished.emit("WallClimbingState")
		return
	
	player.move_and_slide()
	
	# Transition to falling when going down
	if player.velocity.y >= 0:
		finished.emit("FallingState")
		return
	
	# Land
	if player.is_on_floor():
		if input_dir != Vector2.ZERO:
			if Input.is_action_pressed("sprint"):
				finished.emit("RunningState")
			else:
				finished.emit("WalkingState")
		else:
			finished.emit("IdleState")
