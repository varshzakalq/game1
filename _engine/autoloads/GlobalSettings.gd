extends Node

const SAVE_PATH = "user://settings.json"

var settings : Dictionary = {
	"display_mode": 1, 
	"master_volume": 1.0,
	"fov": 75.0,
	"sensitivity": 5.0,
	"keybinds": {} # Stores custom action mapping. Example: {"ui_up": 87}
}

func _ready() -> void:
	_load_settings()
	apply_video_and_audio()
	apply_keybinds()

func save_settings() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

func _load_settings() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		
		if parsed is Dictionary:
			for key in parsed:
				settings[key] = parsed[key]
			return
			
	save_settings()

func apply_video_and_audio() -> void:
	var root_window = get_window()
	if settings["display_mode"] == 1:
		root_window.mode = Window.MODE_FULLSCREEN
	else:
		root_window.mode = Window.MODE_WINDOWED
		root_window.borderless = false
		var target_size = Vector2i(1280, 720)
		root_window.size = target_size
		
		var current_screen = root_window.current_screen
		var screen_pos = DisplayServer.screen_get_position(current_screen)
		var screen_size = DisplayServer.screen_get_size(current_screen)
		root_window.set_deferred("position", screen_pos + (screen_size / 2) - (target_size / 2))
		
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(settings["master_volume"]))
	AudioServer.set_bus_mute(bus_index, settings["master_volume"] == 0.0)

# Overwrites the default InputMap with the player's saved keys
func apply_keybinds() -> void:
	for action in settings["keybinds"]:
		var keycode = settings["keybinds"][action]
		var new_event = InputEventKey.new()
		new_event.physical_keycode = keycode
		
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, new_event)
