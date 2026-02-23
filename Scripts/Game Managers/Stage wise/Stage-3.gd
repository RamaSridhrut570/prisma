extends Node

signal death_by_falling

#const STAGE_4 = preload("uid://gjssk0oihrb1")
const DEATH_BY_FALLING_SFX = preload("uid://y6s8to0nst2u")
const YOUTH_3 = preload("uid://2txh4d8r0wpc")
const MAIN_MENU_3D = preload("uid://bev2rkaxkq873")
const PRISMA___OST = preload("uid://8mg6pswbpkn2")

@onready var portal: Node = $"../Portal"
@export var death_sound: AudioStreamPlayer
@export var stage_manager: Node
@export var collectible_manager: Node
@onready var dialogue: AudioStreamPlayer = $Dialogue
@onready var ending_panel: ColorRect = $"../CanvasLayer/UI/Ending_panel"
@onready var ending_label: Label = $"../CanvasLayer/UI/Ending_panel/Ending_Label"
@onready var bgm: AudioStreamPlayer = $"../BGM"


@export_group("BGM")
@export var bgm_pitch_scale: float = 1.2

# SFX plays when the player crosses this speed (warning threshold)
@export var die_velocity_y: float = 81.0
# Scene reloads when the player crosses this speed (death threshold)
@export var max_velocity_y: float = 100.0

var _player: CharacterBody3D = null
var _sfx_played: bool = false # ensures SFX triggers only once
var _died: bool = false # ensures reload triggers only once


func _ready() -> void:
	if bgm:
		bgm.stream = PRISMA___OST
		bgm.pitch_scale = bgm_pitch_scale
		bgm.play()
	portal.player_entered.connect(_on_portal_entered)
	death_by_falling.connect(_on_death_by_falling)
	ending_label.hide()
	ending_panel.hide()

	# Disable collision on all disabled platforms at start
	for platform in get_tree().get_nodes_in_group("Disabled Platforms"):
		platform.set_deferred("collision_layer", 0)
		platform.hide()

	# Connect orb collection signal
	if collectible_manager:
		collectible_manager.all_orbs_collected.connect(_on_all_orbs_collected)

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]


func _on_all_orbs_collected() -> void:
	for platform in get_tree().get_nodes_in_group("Disabled Platforms"):
		platform.set_deferred("collision_layer", 1)
		platform.show()


func _process(_delta: float) -> void:
	if not _player: return

	# Threshold 1: play SFX as soon as they're falling fast enough
	if not _sfx_played and _player.velocity.y < -die_velocity_y:
		_sfx_played = true
		if death_sound:
			death_sound.stream = DEATH_BY_FALLING_SFX
			death_sound.pitch_scale = 0.8
			death_sound.play()

	# Threshold 2: emit death signal once max speed is exceeded
	if not _died and _player.velocity.y < -max_velocity_y:
		_died = true
		death_by_falling.emit()


func _on_death_by_falling() -> void:
	await get_tree().create_timer(1.5).timeout
	get_tree().call_deferred("reload_current_scene")


func _on_portal_entered() -> void:
	ending_panel.show()
	await get_tree().create_timer(1.0).timeout
	ending_label.text = "They knew,"
	ending_label.show()
	dialogue.stream = YOUTH_3
	dialogue.play()
	await get_tree().create_timer(2.0).timeout
	ending_label.text = "that I would become a GOD"
	await dialogue.finished
	await get_tree().create_timer(1.0).timeout
	get_tree().call_deferred("change_scene_to_packed", MAIN_MENU_3D)
