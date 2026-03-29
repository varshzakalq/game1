extends Node

signal sensitivity_changed(value : float)
signal fov_changed(value : float)

signal player_dead
signal rewinding(value : bool)
signal ambient_aging(value : float)
var roll_back = preload("uid://bpeb1uwni7a0q")
var REWINDING = false

func _ready() -> void:
	player_dead.connect(_on_player_dead)



func _on_player_dead():
	pass


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
		if Globals.player != null and rewind_sfx == null:
			Globals.player.aging_component.increase_age(delta, 500)
		
		
			rewind_sfx = AudioManager.play_2d(roll_back,0)
	
	if not REWINDING:
		if rewind_sfx != null: 
			rewind_sfx.stop()
			rewind_sfx.queue_free()
			rewind_sfx = null
