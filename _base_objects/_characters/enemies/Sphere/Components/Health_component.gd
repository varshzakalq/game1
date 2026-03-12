extends Node

@onready var main_body : CharacterBody3D = owner

var Health : float = 100.0:
	set(val):
		
		if val < Health:
			main_body._play_take_damage_animation()
		
		else:
			main_body._play_heal_animation()
		
		
		Health = val
		
		
		if Health <= 0:
			main_body.kill_self()
