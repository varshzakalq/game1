extends Control

@onready var menu = $Menu/VBoxContainer/Back_to_menu
@onready var settings = $Settings
@onready var settings_button = $Menu/VBoxContainer/Settings
@onready var pause_buttons = $Menu

var shown = false

func _ready() -> void:
	menu.pressed.connect(_exit_to_main_menu)
	settings_button.pressed.connect(_settings_button)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if shown: 
			shown = false
			get_tree().paused = false
			hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			shown = true
			get_tree().paused = true
			show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		

func _settings_button():
	pause_buttons.hide()
	settings.show()
	

func _exit_to_main_menu():
	if get_tree().paused: get_tree().paused = false
	get_tree().change_scene_to_file("res://_main/Starting scenes/Start menu.tscn")
