extends Node

@export var sub_label: Label
@export var ui: Control

# Optional tracking
var total_orbs: int = 0
var collected_orbs: int = 0


signal all_orbs_collected

func _ready():
	pass

func register_orb() -> void:
	total_orbs += 1

func orb_collected() -> void:
	collected_orbs += 1
	sub_label.text = str("Orb collected: ", collected_orbs, "/", total_orbs)
	ui._show_label()
	if collected_orbs >= total_orbs:
		all_orbs_collected.emit()
		sub_label.text = "All orbs collected!"
		ui._hide_label()
