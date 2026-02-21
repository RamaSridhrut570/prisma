extends Node

@export var sub_label: Label
@export var ui: Control
@export var portal: Node

# Optional tracking
var total_orbs: int = 0
var collected_orbs: int = 0
var _all_collected: bool = false


signal all_orbs_collected

func _ready():
	if portal: portal.disable_portal()

func register_orb() -> void:
	total_orbs += 1

func reset() -> void:
	collected_orbs = 0
	total_orbs = 0
	_all_collected = false
	if portal: portal.disable_portal()
	ui._hide_label()

func orb_collected() -> void:
	collected_orbs += 1
	sub_label.text = str("Orb collected: ", collected_orbs, "/", total_orbs)
	ui._show_label()
	ui._hide_label()
	if collected_orbs >= total_orbs and total_orbs > 0:
		_all_collected = true
		all_orbs_collected.emit()
		sub_label.text = "All orbs collected!"
		ui._show_label()
		ui._hide_label()
		if portal: portal.enable_portal()
		await get_tree().create_timer(4.0).timeout
		if _all_collected: # Guard: skip if reset() was called during the wait
			sub_label.text = "Find the Portal."
			ui._show_label()
