## Base class for all player states
class_name State
extends Node

## Emitted when the state wants to transition to another state
signal finished(next_state_name: String, data: Dictionary)

## Reference to the player this state belongs to
var player: CharacterBody3D

## Called when entering this state
func enter(previous_state: String, data: Dictionary = {}) -> void:
	pass

## Called when exiting this state  
func exit() -> void:
	pass

## Called every frame while this state is active
func update(delta: float) -> void:
	pass

## Called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass

## Called for input events while this state is active
func handle_input(event: InputEvent) -> void:
	pass
