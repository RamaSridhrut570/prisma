extends Control

const MAIN = preload("uid://b8gacbdlnig36")
const GLASS_006 = preload("uid://c0sg0wa5i1w6x")

@onready var start_game: Button = $"BoxContainer/Start Game"
@onready var options: Button = $BoxContainer/Controls
@onready var exit: Button = $BoxContainer/Exit
@onready var sfx: AudioStreamPlayer = $sfx



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	sfx.stream = GLASS_006

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


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
	get_tree().change_scene_to_file("uid://b8gacbdlnig36")
