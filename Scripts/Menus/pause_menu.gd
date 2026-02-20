extends Control

const Main_Menu = preload("uid://b24lmsex3wy4v")
const GLASS_006 = preload("uid://c0sg0wa5i1w6x")


@onready var sfx: AudioStreamPlayer = $sfx

func _process(_delta: float) -> void:
	testEsc()

func _ready() -> void:
	$AnimationPlayer.play("RESET")


func resume():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	$AnimationPlayer.play("blur")

func testEsc():
	if Input.is_action_just_pressed("escape") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("escape") and get_tree().paused == true:
		resume()


func _on_resume_pressed() -> void:
	resume()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("uid://b24lmsex3wy4v")

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_resume_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()

func _on_restart_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()

func _on_controls_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()

func _on_exit_mouse_entered() -> void:
	if sfx.finished:
		sfx.play()
