extends Node

const STAGE_2 = preload("uid://csodwrhjmtu4e")


@onready var portal: Node = $"../Portal"

@export var stage_manager: Node
@export var collectible_manager: Node


func _ready() -> void:
	portal.player_entered.connect(_on_portal_entered)

func _on_portal_entered() -> void:
	get_tree().call_deferred("change_scene_to_packed", STAGE_2)
