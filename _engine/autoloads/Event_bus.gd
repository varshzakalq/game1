extends Node

signal sensitivity_changed(value : float)
signal fov_changed(value : float)

signal rewinding(value : bool)
signal ambient_aging(value : float)


var REWINDING = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Rewind"):
		rewinding.emit(true)
		REWINDING = true
	if event.is_action_released("Rewind"):
		rewinding.emit(false)
		REWINDING = false

func _process(delta: float) -> void:
	if REWINDING:
		if Globals.player != null:
			Globals.player.aging_component.increase_age(delta, 500)
