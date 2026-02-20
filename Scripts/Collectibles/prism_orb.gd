extends Node3D

const COLLECT = preload("uid://krgwijrd6fm5")

@onready var audio_player = $AudioStreamPlayer
@onready var mesh = $MeshInstance3D
@onready var light = $OmniLight3D
@onready var area_3d: Area3D = $Area3D

# Reference to the collectible manager (found via group)
var manager = null

func _ready():
	audio_player.stream = COLLECT
	
	# Find the collectible manager in the group "collectible_manager"
	var managers = get_tree().get_nodes_in_group("collectible_manager")
	if managers.size() > 0:
		manager = managers[0]
		if manager.has_method("register_orb"):
			manager.register_orb()
	else:
		print("Warning: No collectible manager found in group 'collectible_manager'")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		# Notify manager
		if manager and manager.has_method("orb_collected"):
			manager.orb_collected()
		
		# Disable collision and hide visuals
		area_3d.collision_layer = 0
		area_3d.collision_mask = 0
		mesh.visible = false
		if light:
			light.visible = false
		
		# Play sound
		if audio_player and audio_player.stream:
			randomize()
			var p: float = randf_range(1.8, 2.0)
			audio_player.pitch_scale = p
			audio_player.play()
			await audio_player.finished
		
		queue_free()
