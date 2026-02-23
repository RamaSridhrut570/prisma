extends Node

const BIRTH_1 = preload("uid://tpacgp8p40jm")
const BIRTH_2 = preload("uid://ycjnyy5n1mtf")
const BIRTH_3 = preload("uid://7fsdf01nwt2f")


@onready var area_3d: Area3D = $Area3D
@onready var area_3d_2: Area3D = $Area3D2
@onready var area_3d_3: Area3D = $Area3D3

@export var player: CharacterBody3D


func _ready() -> void:
	area_3d.body_entered.connect(_on_area_1_body_entered)
	area_3d_2.body_entered.connect(_on_area_2_body_entered)
	area_3d_3.body_entered.connect(_on_area_3_body_entered)


func _get_dialogues_player() -> AudioStreamPlayer:
	return player.get_node("Dialogues") as AudioStreamPlayer


func _on_area_1_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = BIRTH_1
	dp.play()
	await dp.finished
	area_3d.monitoring = false
	area_3d.monitorable = false


func _on_area_2_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d_2.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = BIRTH_2
	dp.play()
	await dp.finished
	area_3d_2.monitoring = false
	area_3d_2.monitorable = false


func _on_area_3_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d_3.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = BIRTH_3
	dp.play()
	await dp.finished
	area_3d_3.monitoring = false
	area_3d_3.monitorable = false
