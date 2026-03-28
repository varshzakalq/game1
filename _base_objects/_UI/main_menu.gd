extends Control

# --- NODE REFERENCES ---
# We grab the VBoxContainer first so we don't have to write out the massive path 4 times
@onready var menu_vbox = $Menu/MarginContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var menu_cbox = $Menu
@onready var settings = $Settings

@onready var start_btn = menu_vbox.get_node("Start")
@onready var how_to_play_btn = menu_vbox.get_node("How to play")
@onready var settings_btn = menu_vbox.get_node("Settings")
@onready var quit_btn = menu_vbox.get_node("Exit") 

# If you have the SettingsMenu scene we just built instantiated in this scene, reference it here:
# @onready var settings_menu = $SettingsMenu 

func _ready() -> void:
	# Connect all buttons directly to their functions
	start_btn.pressed.connect(_on_start_pressed)
	how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

# ==========================================
# BUTTON LOGIC
# ==========================================

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://_main/Starting scenes/Starting scene.tscn")

func _on_how_to_play_pressed() -> void:
	# Toggle your tutorial popup visibility here
	print("How to play clicked")

func _on_settings_pressed() -> void:
	menu_cbox.hide()
	settings.show()

func _on_quit_pressed() -> void:
	# Safely closes the entire game application
	get_tree().quit()
