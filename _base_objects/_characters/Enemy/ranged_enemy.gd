class_name RangedEnemy
extends StandardEnemy



@onready var target_dir = $Target_dir

@export_category("Combat Setup")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 10
@export var speed: float = 5.0

@export_category("Effects")
@export var explosion_scene: PackedScene
const blast = preload("uid://cisc24go2238h")

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent

var previous_mem: bool = false

func _ready() -> void:
	super._ready()
	if health_component:
		health_component.died.connect(_on_death)

func _physics_process(delta: float) -> void:
	if Globals.player == null:
		return
		
	super._physics_process(delta)
	
	# CRITICAL QUICK-FIX: Stop applying gravity and movement if rewinding!
	if _is_rewinding:
		return
		

	move_and_slide()

# Hooking into your base class state machine
func process_chase(delta: float, distance_to_player: float) -> void:
	if _has_line_of_sight(Globals.player) or previous_mem:
		navigation_agent_3d.target_position = Globals.player.global_position
		previous_mem = true
	

	if distance_to_player > attack_range:
		if not navigation_agent_3d.is_navigation_finished():
			var next_path_pos = navigation_agent_3d.get_next_path_position()
			var direction = global_position.direction_to(next_path_pos)
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
	else:
		# Stop moving when in range
		velocity.x = move_toward(velocity.x, 0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 5.0)
		
		# Look at the player to aim
		var player_pos = Globals.player.global_position
		look_at(Vector3(player_pos.x, global_position.y, player_pos.z), Vector3.UP)

# Using your exact signature from the base class
func launch_attack(age_component, age_damage: float) -> void:
	
	print("ATTEMPTING ATTACK")
	if projectile_scene == null:
		push_warning("Enemy: Missing projectile or fire_point!")
		return
		
	var proj = projectile_scene.instantiate()
	
	var dir_vec : Vector3 = (target_dir.global_position - global_position).normalized()
	
	
	if proj is TemporalProjectile:
		proj.speed = projectile_speed
		proj.target_dir = dir_vec
		proj.damage = age_damage
		proj.target = TemporalProjectile.targets.Player
		target_dir.add_child(proj)
		

func _on_death() -> void:
	if explosion_scene != null:
		AudioManager.play_3d(blast,position)
		print("played")
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		
		if explosion is GPUParticles3D or explosion is CPUParticles3D:
			explosion.emitting = true
			
	var dist = global_position.distance_to(Globals.player.global_position)
	if dist < 1.5 and Globals.player.aging_component: 
		Globals.player.aging_component.age_damage(200)
	
	queue_free()
