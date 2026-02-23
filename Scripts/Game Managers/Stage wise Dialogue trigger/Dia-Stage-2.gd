extends Node

const CHILDHOOD_1 = preload("uid://jqvdghx8dp6s")
const CHILDHOOD_2 = preload("uid://bip5u0caiskll")
const CHILDHOOD_3 = preload("uid://jk1ch54igdkq")
const CHILDHOOD_4 = preload("uid://blu5w3ll6etao")


@onready var area_3d: Area3D = $Area3D
@onready var area_3d_2: Area3D = $Area3D2
@onready var area_3d_3: Area3D = $Area3D3
@onready var area_3d_4: Area3D = $Area3D4

@export var player: CharacterBody3D


func _ready() -> void:
	area_3d.body_entered.connect(_on_area_1_body_entered)
	area_3d_2.body_entered.connect(_on_area_2_body_entered)
	area_3d_3.body_entered.connect(_on_area_3_body_entered)
	area_3d_4.body_entered.connect(_on_area_4_body_entered)


func _get_dialogues_player() -> AudioStreamPlayer:
	return player.get_node("Dialogues") as AudioStreamPlayer


func _on_area_1_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = CHILDHOOD_1
	dp.play()
	await dp.finished
	area_3d.monitoring = false
	area_3d.monitorable = false


func _on_area_2_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d_2.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = CHILDHOOD_2
	dp.play()
	await dp.finished
	area_3d_2.monitoring = false
	area_3d_2.monitorable = false


func _on_area_3_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d_3.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = CHILDHOOD_3
	dp.play()
	await dp.finished
	area_3d_3.monitoring = false
	area_3d_3.monitorable = false


func _on_area_4_body_entered(body: Node3D) -> void:
	if body != player:
		return
	area_3d_4.monitoring = false
	var dp := _get_dialogues_player()
	dp.stream = CHILDHOOD_4
	dp.play()
	await dp.finished
	area_3d_4.monitoring = false
	area_3d_4.monitorable = false
