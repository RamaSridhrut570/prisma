## Finite State Machine for managing player states
class_name StateMachine
extends Node

## The initial state to start with
@export var initial_state: State = null

## Current active state
@onready var current_state: State = null

## Reference to all states by name
var states: Dictionary = {}

func _ready() -> void:
	# Collect all child states
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.finished.connect(_transition_to_state)
			child.player = owner  # Give each state a reference to the player
	
	# Wait for owner to be ready, then initialize
	await owner.ready
	
	# Set initial state
	if initial_state == null and get_child_count() > 0:
		initial_state = get_child(0) as State
	
	if initial_state:
		current_state = initial_state
		current_state.enter("")

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Transition to a new state
func _transition_to_state(new_state_name: String, data: Dictionary = {}) -> void:
	if not states.has(new_state_name):
		push_error("State " + new_state_name + " does not exist!")
		return
	
	var previous_state_name = current_state.name if current_state else ""
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Enter new state
	current_state = states[new_state_name]
	current_state.enter(previous_state_name, data)

## Force transition to a state (useful for external triggers)
func force_transition(state_name: String, data: Dictionary = {}) -> void:
	_transition_to_state(state_name, data)

## Get current state name
func get_current_state_name() -> String:
	return current_state.name if current_state else ""
