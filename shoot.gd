extends Node3D

@export_category("Weapon Setup")
@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.2 # Cooldown between shots
@export var damage: float = 25.0
@export var bullet_speed: float = 10



@onready var target : Node3D = $Target

var _fire_timer: float = 0.0

func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	
	# Prevent the player from shooting while time is actively rewinding!
	if Globals.player != null and Globals.player.get("_is_rewinding") == true:
		return
		
	# Using is_action_pressed allows for automatic fire if they hold the button
	if Input.is_action_pressed("Fire") and _fire_timer <= 0.0:
		shoot()
		_fire_timer = fire_rate

func shoot() -> void:
	if projectile_scene == null:
		push_warning("PlayerWeapon: No projectile scene assigned in Inspector!")
		return
		
	var proj = projectile_scene.instantiate()
	if proj is TemporalProjectile:
		
		var diff = target.global_position - global_position
		diff = -diff
		proj.scale = 0.5*Vector3.ONE
		proj.target_dir = diff
		proj.damage = damage
		proj.speed = bullet_speed
		proj.target = TemporalProjectile.targets.Enemy
		target.add_child(proj)
	
