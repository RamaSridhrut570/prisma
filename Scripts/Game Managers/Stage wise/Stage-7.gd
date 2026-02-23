extends Node

# Stage-7 is the final stage (DEATH).
# Replace the TODO with your end screen / credits scene.

const DEATH_BY_FALLING_SFX = preload("uid://bv33th1lyqua5")
@onready var death_sound: AudioStreamPlayer = $"../Death_sound"
@onready var portal: Node = $"../Portal"

@export var stage_manager: Node
@export var collectible_manager: Node

# Maximum downward velocity before the player is considered to have fallen to their death
@export var max_velocity_y: float = 100.0

var _player: CharacterBody3D = null


func _ready() -> void:
	portal.player_entered.connect(_on_portal_entered)
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func _process(_delta: float) -> void:
	if _player and _player.velocity.y < -max_velocity_y:
		get_tree().call_deferred("reload_current_scene")

func _on_portal_entered() -> void:
	# TODO: change_scene_to_file("res://Scenes/Menus/credits.tscn") or similar
	pass
