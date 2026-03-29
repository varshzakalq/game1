extends Node3D
class_name Bosda_Gun

const inaccuracy : float = 5

@onready var main = $"../.."
@onready var projectile_scene = preload("res://_base_objects/_characters/Enemy/projectile/Projectile.tscn")
@onready var aimer : Node3D

func _ready() -> void:
	aimer = get_child(0)

func shoot(target_pos : Vector3, damage : float,  accuracy : float = 1, speed_multiplier : float = 1):
	var shot_pos = target_pos + inaccuracy*(1-accuracy)*Vector3(randf_range(-1,1), 0, randf_range(-1, 1))
	
	look_at(shot_pos)
	
	var target_dir = aimer.global_position - global_position
	
	

	var projectile : TemporalProjectile = projectile_scene.instantiate()
		

	
	
	projectile.speed = main.projectile_speed * speed_multiplier
	projectile.target_dir = -target_dir
	projectile.damage = damage
	projectile.target = TemporalProjectile.targets.Player
	add_child(projectile)
		
	
