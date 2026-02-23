extends Node

signal death_by_falling

const STAGE_3 = preload("uid://y8dqo0h6rgly")
const DEATH_BY_FALLING_SFX = preload("uid://y6s8to0nst2u")
const PRISMA___OST = preload("uid://8mg6pswbpkn2")

@onready var portal: Node = $"../Portal"
@export var death_sound: AudioStreamPlayer
@export var stage_manager: Node
@export var collectible_manager: Node
@onready var bgm: AudioStreamPlayer = $"../BGM"


@export_group("BGM")
@export var bgm_pitch_scale: float = 1.0

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
	get_tree().call_deferred("change_scene_to_packed", STAGE_3)
