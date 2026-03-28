extends Control

# --- EXISTING NODE REFERENCES ---
@onready var fov_slider = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer/MarginContainer2/HSlider
@onready var fov_value = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer/MarginContainer3/Value

@onready var sens_slider = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer2/MarginContainer2/HSlider
@onready var sens_value = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer2/MarginContainer4/Value

@onready var display_toggle = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer3/MarginContainer2/OptionButton

@onready var audio_slider = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer4/MarginContainer2/HSlider
@onready var audio_value = $MarginContainer/VBoxContainer/TabContainer/Gameplay/HBoxContainer4/MarginContainer5/Value

@onready var back_button = $MarginContainer/VBoxContainer/Back_button

# --- NEW KEYBINDING REFERENCES & VARIABLES ---
@onready var keybind_list = $MarginContainer/VBoxContainer/TabContainer/Controls/Keybinds

# Put your exact Input Map action names in this array
@export var actions_to_remap: Array[String] = [
	"Forward",
	"Backward",
	"Left",
	"Right",
	"Jump",
	"Rewind"
	]

var is_remapping: bool = false
var action_to_remap: String = ""
var remapping_button: Button = null

func _ready() -> void:
	display_toggle.clear()
	display_toggle.add_item("Windowed")   
	display_toggle.add_item("Borderless") 
	
	display_toggle.select(GlobalSettings.settings["display_mode"])
	fov_slider.value = GlobalSettings.settings["fov"]
	sens_slider.value = GlobalSettings.settings["sensitivity"]
	audio_slider.value = GlobalSettings.settings["master_volume"]
		
	fov_value.text = str(fov_slider.value)
	sens_value.text = "%.3f" % sens_slider.value
	audio_value.text = str(int(audio_slider.value * 100))
		
	fov_slider.value_changed.connect(_on_fov_changed)
	sens_slider.value_changed.connect(_on_sens_changed)
	display_toggle.item_selected.connect(_on_display_selected)
	audio_slider.value_changed.connect(_on_audio_changed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	_create_keybind_list()
	
	if get_parent() != null: hide()

# ==========================================
# DYNAMIC KEYBINDING GENERATION
# ==========================================
func _create_keybind_list() -> void:
	# Clear out any placeholder nodes you might have left in the editor
	for child in keybind_list.get_children():
		child.queue_free()
		
	for action in actions_to_remap:
		var row = HBoxContainer.new()
		var action_label = Label.new()
		var key_button = Button.new()
		
		# Format the string to look nice (e.g., "ui_up" becomes "Ui Up")
		action_label.text = action.capitalize()
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Get the current key assigned to this action
		var events = InputMap.action_get_events(action)
		if events.size() > 0 and events[0] is InputEventKey:
			key_button.text = OS.get_keycode_string(events[0].physical_keycode)
		else:
			key_button.text = "Unassigned"
			
		key_button.custom_minimum_size = Vector2(150, 0) # Keeps button sizes uniform
		
		# We bind the specific action string and the button node to the function
		key_button.pressed.connect(_on_keybind_button_pressed.bind(action, key_button))
		
		row.add_child(action_label)
		row.add_child(key_button)
		keybind_list.add_child(row)

func _on_keybind_button_pressed(action: String, button: Button) -> void:
	if is_remapping: return # Prevent clicking multiple buttons at once
	
	is_remapping = true
	action_to_remap = action
	remapping_button = button
	button.text = "Press any key..."

# This function intercepts the very next raw hardware input
func _input(event: InputEvent) -> void:
	if is_remapping and event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled() # Stop the input from doing anything else in the game
		
		var new_keycode = event.physical_keycode
		
		# 1. Update the UI
		remapping_button.text = OS.get_keycode_string(new_keycode)
		
		# 2. Update the Godot InputMap immediately
		InputMap.action_erase_events(action_to_remap)
		InputMap.action_add_event(action_to_remap, event)
		
		# 3. Save to GlobalSettings dictionary
		GlobalSettings.settings["keybinds"][action_to_remap] = new_keycode
		
		# Reset state
		is_remapping = false
		action_to_remap = ""
		remapping_button = null

# ==========================================
# EXISTING SETTINGS LOGIC
# ==========================================
func _on_display_selected(index: int) -> void:
	GlobalSettings.settings["display_mode"] = index
	GlobalSettings.apply_video_and_audio()

func _on_audio_changed(value: float) -> void:
	audio_value.text = str(int(round(value * 100)))
	GlobalSettings.settings["master_volume"] = value
	GlobalSettings.apply_video_and_audio()

func _on_fov_changed(value: float) -> void:
	fov_value.text = str(value)
	GlobalSettings.settings["fov"] = value
	EventBus.fov_changed.emit(value)

func _on_sens_changed(value: float) -> void:
	# Display the 0-10 value on the UI
	sens_value.text = "%.1f" % value 
	
	# Update the dictionary with the raw 0-10 value
	GlobalSettings.settings["sensitivity"] = value
	
	# Emit the value to the EventBus
	EventBus.sensitivity_changed.emit(value)

func _on_back_button_pressed():
	GlobalSettings.save_settings()
	get_parent().get_node("Menu").show()
	hide()
