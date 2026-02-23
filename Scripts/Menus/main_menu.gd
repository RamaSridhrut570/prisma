extends Control

const STAGE_1 = preload("uid://dpc613hns36js")
const GLASS_006 = preload("uid://c0sg0wa5i1w6x")
const PRISMA___OST = preload("uid://8mg6pswbpkn2")
const HEADPHONES = preload("uid://bedkob4vu8ysf")

@onready var start_game: Button = $"BoxContainer/Start Game"
@onready var exit: Button = $BoxContainer/Exit
@onready var sfx: AudioStreamPlayer = $sfx
@onready var headphones_panel: ColorRect = $Headphones_panel
@onready var rec_label: Label = $Headphones_panel/rec_Label
@onready var dialogue: AudioStreamPlayer = $Dialogue
@onready var bgm: AudioStreamPlayer = $BGM


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	bgm.stream = PRISMA___OST
	bgm.play()
	sfx.stream = GLASS_006
	headphones_panel.visible = false
	rec_label.text = ""
	dialogue.stream = HEADPHONES

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func headphones_recommended() -> void:
	bgm.stop()
	headphones_panel.visible = true
	await get_tree().create_timer(1.0).timeout
	rec_label.text = "Please use headphones for best experience"
	dialogue.play()
	await dialogue.finished
	rec_label.text = ""
	await get_tree().create_timer(1.0).timeout
	headphones_panel.visible = false
	get_tree().change_scene_to_file("uid://dpc613hns36js")


func _on_exit_pressed() -> void:
	get_tree().quit()
	

func _on_start_game_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()

func _on_controls_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()

func _on_exit_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()

func _on_start_game_pressed() -> void:
	headphones_recommended()
