extends Node3D


@onready var stage_manager: Node = $Game_Manager/StageManager
@onready var title: Label = $"Camera3D/Main Menu/Title"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_cycle_stages()


# Loops through all stages on a 2-second interval, forever.
func _cycle_stages() -> void:
	# Stage index → matching color property on stage_manager
	var stage_colors: Array = [
		stage_manager.birth_color,
		stage_manager.childhood_color,
		stage_manager.youth_color,
		stage_manager.adulthood_color,
		stage_manager.midlife_color,
		stage_manager.aging_color,
		stage_manager.death_color,
	]
	while true:
		var stages = stage_manager.Stage.values()
		for i in stages.size():
			stage_manager.set_stage(stages[i])
			title.label_settings.font_color = stage_colors[i]
			await get_tree().create_timer(2.0).timeout
