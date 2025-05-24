class_name PauseManager
extends Node

"""
Required to restart the simulation after it is paused.
The action must be OUTSIDE of the main process
"""
func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if Input.is_action_just_pressed("pause_simulation"):
		if get_tree().paused:
			get_tree().paused = false
