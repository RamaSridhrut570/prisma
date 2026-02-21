extends Node


const STAGE_3 = preload("uid://y8dqo0h6rgly")


@onready var portal: Node = $"../Portal"

@export var stage_manager: Node
@export var collectible_manager: Node


func _ready() -> void:
	portal.player_entered.connect(_on_portal_entered)

func _on_portal_entered() -> void:
	get_tree().call_deferred("change_scene_to_packed", STAGE_3)
