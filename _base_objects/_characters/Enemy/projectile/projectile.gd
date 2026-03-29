class_name TemporalProjectile
extends Time_Character

enum targets{
	Player,
	Enemy
}

@onready var omni_light = $MeshInstance3D/OmniLight3D
@onready var mesh = $MeshInstance3D

@export_category("Projectile Aesthetics")
@export var proj_color : Color 
@export var energy : float 
@export var volumetric_energy : float

@export_category("Projectile Stats")
@export var speed: float = 10.0
@export var damage: float = 25.0
@export var lifetime: float = 20.0
@export var target: targets = targets.Player


@export_category("Visuals")
@export var impact_particles_scene: PackedScene 

var target_dir: Vector3 = Vector3.ZERO
var _alive_timer: float = 0.0

func _ready() -> void:
	
	
	
	top_level = true
	super._ready() 
	
	omni_light.light_color = proj_color 
	omni_light.light_volumetric_fog_energy = volumetric_energy
	
	var new_material = StandardMaterial3D.new()
	new_material.emission_color = proj_color
	new_material.color = proj_color
	new_material.emission_energy_multiplier = energy*1.5
	#mesh.set_surface_override_material(0, new_material)
	
	_take_snapshot(0)

func _process(delta: float) -> void:
	
	
	if EventBus.REWINDING:
		if _reached_history_end:
			
			queue_free()
	
	else:
		_alive_timer += delta
		
	
	if _alive_timer > lifetime:
		queue_free()


func _physics_process(delta: float) -> void:
	if not EventBus.REWINDING:
		_process_normal_movement(delta)
	
	super._physics_process(delta)
	

func _process_normal_movement(delta: float) -> void:
	
	
	_alive_timer += delta
	if _alive_timer >= lifetime:
		queue_free()
		return

	var flight_direction = target_dir
	velocity = -flight_direction * speed
	move_and_slide()

func _on_hitbox_body_entered(body: Node3D) -> void:
	if _is_rewinding:
		return
		
	match target:
		targets.Player:
			if not body is Player: return
			_deal_age_damage(body)
		targets.Enemy:
			if not body is StandardEnemy: return 
			_deal_damage_to_enemy(body)

func _deal_age_damage(target_body: Player) -> void:
	if not target_body.aging_component:
		push_error("NO AGING COMPONENT IN PLAYER")
		_spawn_impact_and_destroy()
		return
	
	target_body.aging_component.age_damage(damage)
	
	_spawn_impact_and_destroy()

func _deal_damage_to_enemy(target_body: StandardEnemy) -> void:
	if not target_body.get("health_component") or not target_body.health_component:
		push_error("NO HEALTH COMPONENT IN ENEMY")
		_spawn_impact_and_destroy()
		return
	
	
	target_body.health_component.take_damage(damage)
	
	
	print("Projectile hit: ", target_body.name, " for ", damage, " damage!")
	
	
	_spawn_impact_and_destroy()

func _spawn_impact_and_destroy() -> void:
	if impact_particles_scene != null:
		var impact = impact_particles_scene.instantiate()
		get_tree().current_scene.add_child(impact)
		impact.global_position = global_position
		
		if impact is GPUParticles3D or impact is CPUParticles3D:
			impact.emitting = true
			impact.finished.connect(impact.queue_free)
			
	queue_free()
