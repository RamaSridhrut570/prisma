extends Control

@export var sub_label: Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _show_label():
	sub_label.show()


func _hide_label():
	await get_tree().create_timer(2.0).timeout
	sub_label.hide()
