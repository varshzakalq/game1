extends Node

signal sensitivity_changed(value : float)
signal fov_changed(value : float)

signal rewinding(value : bool)
signal ambient_aging(value : float)
var roll_back = preload("uid://bpeb1uwni7a0q")

var REWINDING = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Rewind"):
		rewinding.emit(true)
		REWINDING = true
	if event.is_action_released("Rewind"):
		rewinding.emit(false)
		REWINDING = false

var rewind_sfx = null

func _process(delta: float) -> void:
	
	if REWINDING:
		if Globals.player != null:
			Globals.player.aging_component.increase_age(delta, 500)
		
		
		if not rewind_sfx:
			rewind_sfx = AudioManager.play_2d(roll_back,0)
		
	if !REWINDING:
		if not rewind_sfx: return
		rewind_sfx.stop()
		rewind_sfx.queue_free()
