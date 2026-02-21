extends Node

# Stage-7 is the final stage (DEATH).
# Replace the TODO with your end screen / credits scene.

@onready var portal: Node = $"../Portal"

@export var stage_manager: Node
@export var collectible_manager: Node

func _ready() -> void:
	portal.player_entered.connect(_on_portal_entered)

func _on_portal_entered() -> void:
	# TODO: change_scene_to_file("res://Scenes/Menus/credits.tscn") or similar
	pass
