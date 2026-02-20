extends Node


@onready var sub_label: Label = $"../CanvasLayer/UI/MarginContainer/GridContainer/SubLabel"


# Reference to the StageManager node (Assign in inspector)
@export var stage_manager: Node
@export var collectible_manager: Node


func _ready() -> void:
	pass
