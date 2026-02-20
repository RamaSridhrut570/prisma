extends Node


# Reference to the player (Assign in inspector or find dynamically)
@export var player: CharacterBody3D
# Reference to Environment Nodes (Assign in inspector)
@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D

# Current active stage (Backing variable)
var _current_stage: Stage = Stage.BIRTH

# Exported property to allow Inspector changes
@export var current_stage: Stage:
	get:
		return _current_stage
	set(val):
		_current_stage = val
		_apply_stage_logic()


@export_group("Color Schemes")
@export var birth_color: Color = Color("ff8ab5ff")
@export var childhood_color: Color = Color("ffbe81ff")
@export var youth_color: Color = Color("FFC107")
@export var adulthood_color: Color = Color("68bf00ff")
@export var midlife_color: Color = Color("1f6778ff")
@export var aging_color: Color = Color("400e5dff")
@export var death_color: Color = Color("B71C1C")

# Levels / Color Stages
enum Stage {
	BIRTH,
	CHILDHOOD,
	YOUTH,
	ADULTHOOD,
	MIDLIFE,
	AGING,
	DEATH
}


func _ready() -> void:
	_apply_stage_logic()

# Public API to set stage (triggers setter)
func set_stage(new_stage: Stage) -> void:
	current_stage = new_stage

func _apply_stage_logic() -> void:
	match _current_stage:
		Stage.BIRTH:
			_setup_birth()
		Stage.CHILDHOOD:
			_setup_childhood()
		Stage.YOUTH:
			_setup_youth()
		Stage.ADULTHOOD:
			_setup_adulthood()
		Stage.MIDLIFE:
			_setup_midlife()
		Stage.AGING:
			_setup_aging()
		Stage.DEATH:
			_setup_death()

# Helper to apply colors and stage-specific environment effects
func _apply_stage_color(color: Color, stage: Stage) -> void:
	if sun_light:
		sun_light.light_color = color
	
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		
		# --- Base Color Application ---
		env.fog_light_color = color
		env.volumetric_fog_albedo = color
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = color
		env.glow_enabled = true
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.adjustment_enabled = true
		
		# --- Stage-Specific Effects ---
		match stage:
			Stage.BIRTH:
				# Soft, dreamy, warm glow
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.1
				env.volumetric_fog_density = 0.08
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
				env.glow_intensity = 0.8
				env.glow_bloom = 0.3
				env.adjustment_saturation = 1.50
				env.adjustment_contrast = 0.75
			Stage.CHILDHOOD:
				# Fresh, lively, slightly brighter
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.08
				env.volumetric_fog_density = 0.04
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
				env.glow_intensity = 0.55
				env.glow_bloom = 0.06
				env.adjustment_saturation = 1.1
				env.adjustment_contrast = 1.0
			Stage.YOUTH:
				# Vibrant, energetic, saturated
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.12
				env.volumetric_fog_density = 0.05
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
				env.glow_intensity = 0.7
				env.glow_bloom = 0.05
				env.adjustment_saturation = 1.2
				env.adjustment_contrast = 1.05
			Stage.ADULTHOOD:
				# Grounded, stable, natural
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.05
				env.volumetric_fog_density = 0.15
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
				env.glow_intensity = 0.4
				env.glow_bloom = 0.02
				env.adjustment_saturation = 1.0
				env.adjustment_contrast = 1.05
			Stage.MIDLIFE:
				# Reflective, warm but subdued
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.07
				env.volumetric_fog_density = 0.25
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_MIX
				env.glow_intensity = 0.5
				env.glow_bloom = 0.10
				env.adjustment_saturation = 1.05
				env.adjustment_contrast = 1.1
			Stage.AGING:
				# Calm, muted, hazy wisdom
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.15
				env.volumetric_fog_density = 0.15
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
				env.glow_intensity = 0.65
				env.glow_bloom = 0.12
				env.adjustment_saturation = 0.85
				env.adjustment_contrast = 0.9
			Stage.DEATH:
				# Dramatic, desaturated, high contrast
				env.fog_enabled = true
				env.volumetric_fog_emission = color * 0.03
				env.volumetric_fog_density = 0.3
				env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
				env.glow_intensity = 0.8
				env.glow_bloom = 0.15
				env.adjustment_saturation = 0.7
				env.adjustment_contrast = 1.25

# --------------------------------------------------------------------------------
# BIRTH: Simple, safe platforms + Gentle introduction.
# --------------------------------------------------------------------------------
func _setup_birth() -> void:
	print("Stage: Birth")
	_apply_stage_color(birth_color, Stage.BIRTH) # Soft Reddish/Pinkish (Sunrise/Peach)
	if not player: return

	# --- MECHANICS ---
	player.can_walk = true
	player.can_look = true
	player.can_jump = false
	player.can_sprint = false
	player.can_crouch = true
	player.can_slide = false
	player.can_double_jump_mechanic = false
	player.can_wall_climb = false
	player.can_wall_jump = false
	player.can_wall_slide = false
	player.can_free_look = true

	# --- SPEEDS ---
	player.walking_speed = 5.0 # Slow, gentle pace
	player.sprinting_speed = 5.0 # Same as walk
	player.crouching_speed = 2.0
	player.slide_speed = 0.0

	# --- HEAD BOBBING ---
	# Boosted intensities: Walking noticeable now
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.4
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.3
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.2 # (Unused)
	
	player.HEAD_BOBBING_WALKING_SPEED = 9.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 7.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 10.0

# --------------------------------------------------------------------------------
# CHILDHOOD: Hidden paths + Exploration + Curiosity.
# --------------------------------------------------------------------------------
func _setup_childhood() -> void:
	print("Stage: Childhood")
	_apply_stage_color(childhood_color, Stage.CHILDHOOD) # Bright Orange (energetic/playful)
	if not player: return

	# --- MECHANICS ---
	player.can_walk = true
	player.can_jump = true
	player.can_crouch = true
	player.can_sprint = true
	player.can_look = true
	player.can_free_look = true
	player.can_slide = false
	player.can_double_jump_mechanic = false
	player.can_wall_climb = false
	player.can_wall_jump = false
	player.can_wall_slide = true

	# --- SPEEDS ---
	player.walking_speed = 8.0 # Curious wandering
	player.sprinting_speed = 13.0 # Kids run fast!
	player.crouching_speed = 4.0 # Sneaking into secret paths
	player.slide_speed = 0.0

	# --- HEAD BOBBING ---
	# Bouncy, playful steps
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.3 # Noticeable bounce
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.4 # High energy bounce
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.2
	
	player.HEAD_BOBBING_WALKING_SPEED = 14.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 18.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 8.0

# --------------------------------------------------------------------------------
# YOUTH: Fast movement, slides, runs + High Energy.
# --------------------------------------------------------------------------------
func _setup_youth() -> void:
	print("Stage: Youth")
	_apply_stage_color(youth_color, Stage.YOUTH) # Amber/Gold (reflective)
	if not player: return

	# FULL MOVEMENT KIT
	player.can_walk = true
	player.can_sprint = true
	player.can_crouch = true
	player.can_slide = true # Sliding unlocked!
	player.can_jump = true
	player.can_double_jump_mechanic = true # Peak energy
	
	player.can_wall_climb = true
	player.can_wall_jump = true
	player.can_wall_slide = true
	player.can_look = true
	player.can_free_look = true

	# --- SPEEDS ---
	player.walking_speed = 10.0 # Fast baseline
	player.sprinting_speed = 18.0 # Peak speed
	player.crouching_speed = 5.0
	player.slide_speed = 14.0 # Fast slides

	# --- HEAD BOBBING ---
	# Stabilized but fast (athletic, confident stride)
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.15 # Smooth
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.2 # Controlled
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.1
	
	player.HEAD_BOBBING_WALKING_SPEED = 16.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 24.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 10.0

# --------------------------------------------------------------------------------
# ADULTHOOD: Complex puzzles + Precision + Timing.
# --------------------------------------------------------------------------------
func _setup_adulthood() -> void:
	print("Stage: Adulthood")
	_apply_stage_color(adulthood_color, Stage.ADULTHOOD) # Light Green
	if not player: return

	player.can_walk = true
	player.can_sprint = true
	player.can_crouch = true
	player.can_slide = true
	player.can_jump = true
	
	player.can_double_jump_mechanic = true
	player.can_wall_climb = true
	player.can_wall_jump = true
	player.can_wall_slide = true
	
	player.can_look = true
	player.can_free_look = true

	# --- SPEEDS ---
	player.walking_speed = 9.0 # Steady, controlled
	player.sprinting_speed = 15.0 # Disciplined
	player.crouching_speed = 5.0
	player.slide_speed = 12.0

	# --- HEAD BOBBING ---
	# Very stable (confident, grounded stride)
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.1 # Minimal
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.15 # Controlled
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.08
	
	player.HEAD_BOBBING_WALKING_SPEED = 14.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 22.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 10.0

# --------------------------------------------------------------------------------
# MIDLIFE: Sharp angles + Difficult jumps + "Ghost platforms".
# --------------------------------------------------------------------------------
func _setup_midlife() -> void:
	print("Stage: Midlife")
	_apply_stage_color(midlife_color, Stage.MIDLIFE) # Deep Green (grounded)
	if not player: return

	# Reflective, slightly heavier
	player.can_walk = true
	player.can_sprint = true
	player.can_crouch = true
	player.can_slide = true
	player.can_jump = true
	
	# Double jump disabled — precision and consequence
	player.can_double_jump_mechanic = false
	
	player.can_wall_climb = true
	player.can_wall_jump = true
	player.can_wall_slide = true
	player.can_look = true
	player.can_free_look = true

	# --- SPEEDS ---
	player.walking_speed = 8.0 # More cautious
	player.sprinting_speed = 13.0 # Less reckless
	player.crouching_speed = 4.5
	player.slide_speed = 10.0

	# --- HEAD BOBBING ---
	# Heavier, reflective steps
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.25 # Noticeable weight
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.3 # Labored
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.15
	
	player.HEAD_BOBBING_WALKING_SPEED = 12.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 18.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 8.0

# --------------------------------------------------------------------------------
# AGING: Crumbling platforms + "Only forward" + Letting Go.
# --------------------------------------------------------------------------------
func _setup_aging() -> void:
	print("Stage: Aging")
	_apply_stage_color(aging_color, Stage.AGING) # Purple (wisdom, calm)
	if not player: return

	player.can_walk = true
	player.can_jump = true
	
	# Declining body
	player.can_sprint = false
	player.can_slide = false
	player.can_crouch = true # Can crouch, hard to get up
	
	player.can_double_jump_mechanic = false
	player.can_wall_climb = false
	player.can_wall_jump = false
	player.can_wall_slide = false
	
	player.can_look = true
	player.can_free_look = true

	# --- SPEEDS ---
	player.walking_speed = 5.5 # Slower, heavier
	player.sprinting_speed = 5.5 # No sprint
	player.crouching_speed = 3.0
	player.slide_speed = 0.0

	# --- HEAD BOBBING ---
	# Heavy, labored steps
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.4 # Heavy
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.4
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.4 # (Unused)
	
	player.HEAD_BOBBING_WALKING_SPEED = 10.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 16.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 8.0

# --------------------------------------------------------------------------------
# DEATH: World dissolves + Fragments + White light -> Black screen.
# --------------------------------------------------------------------------------
func _setup_death() -> void:
	print("Stage: Death")
	_apply_stage_color(death_color, Stage.DEATH) # Deep Red (finality)
	if not player: return

	# The final walk
	player.can_walk = true
	player.can_look = true
	player.can_free_look = true
	
	# Strip everything
	player.can_sprint = false
	player.can_crouch = false
	player.can_slide = false
	player.can_jump = false
	player.can_double_jump_mechanic = false
	player.can_wall_climb = false
	player.can_wall_jump = false
	player.can_wall_slide = false

	# --- SPEEDS ---
	player.walking_speed = 3.0 # Barely moving
	player.sprinting_speed = 3.0
	player.crouching_speed = 2.0
	player.slide_speed = 0.0

	# --- HEAD BOBBING ---
	# Very heavy, disoriented (matching Birth's heaviness)
	player.HEAD_BOBBING_WALKING_INTENSITY = 0.8 # Maximum weight
	player.HEAD_BOBBING_CROUCHING_INTENSITY = 0.6
	player.HEAD_BOBBING_SPRINTING_INTENSITY = 0.8 # (Unused)
	
	player.HEAD_BOBBING_WALKING_SPEED = 5.0
	player.HEAD_BOBBING_SPRINTING_SPEED = 5.0
	player.HEAD_BOBBING_CROUCHING_SPEED = 4.0
