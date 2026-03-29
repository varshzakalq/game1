extends Control


@onready var back_button = $MarginContainer/VBoxContainer/Back_button


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	if get_parent() != null: hide()

func _on_back_button_pressed():
	get_parent().get_node("Menu").show()
	hide()
