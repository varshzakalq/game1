extends StandardEnemy
class_name Bossada

@export var explosion_scene2: PackedScene
@export var explosion_scene: PackedScene
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var guns : Array[Bosda_Gun] = [
	$Guns/Left_gun,
	$Guns/Right
]
@export_category("Combat Setup")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 10
@export var speed: float = 5.0
const blast_sound = preload("uid://cisc24go2238h")


var is_in_burst_fire : bool = false
var burst_time : float = 0

func _physics_process(delta: float) -> void:
	# Safety check: if player isn't loaded, don't do anything
	if Globals.player == null:
		return
		

	
	
	super._physics_process(delta)

	move_and_slide()
	

var attack_counter = 0
var alternate_thing = 0

func launch_attack(_age_component, age_damage: float) -> void:
	
	if is_in_burst_fire: return
	
	attack_counter += 1
	
	
	var attack = randi_range(0, 1)
	
	match attack:
		0:
			alternate_thing += 1
			if alternate_thing%2 == 0:
				guns[0].shoot(Globals.player.global_position, age_damage_per_hit, 1, 1)
			if alternate_thing%2 == 1:
				guns[1].shoot(Globals.player.global_position, age_damage_per_hit, 1, 1)
			attack_counter -= 1
		
		1:
			if attack_counter < 3: 
				attack_counter += 1
				return
			
			attack_counter -= 3
			is_in_burst_fire = true
			burst_time = attack_cooldown

func _process(delta: float) -> void:
	
	
	
	# 4. Remove the object from the game
	queue_free()

		
	if is_in_burst_fire:
		for gun in guns:
			gun.shoot(Globals.player.global_position, age_damage_per_hit/10., 0.1, 0.6)
		
		burst_time -= delta
		if burst_time < 0: is_in_burst_fire = false

func process_chase(_delta: float, distance_to_player: float) -> void:
	var dist = global_position.distance_to(Globals.player.global_position)

	if dist > attack_range:
		if not navigation_agent_3d.is_navigation_finished():
			var next_path_pos = navigation_agent_3d.get_next_path_position()
			var direction = (next_path_pos - global_position).normalized()
			velocity = direction * SPEED
			
	_turn_towards(Vector3(Globals.player.global_position.x, global_position.y, Globals.player.global_position.z ))
	


func _ready() -> void:
	health_component.died.connect(_on_death)
	
	super._ready()

func _on_death() -> void:
	
	var dist = global_position.distance_to(Globals.player.global_position)
	
	var explosion = explosion_scene.instantiate()
		
		# 4. Add it to the level (the enemy's parent)
	get_parent().add_child(explosion)
	#AudioManager.play_3d(blast_sound,position,70)
		# 5. Move it to the enemy's current position
	explosion.global_position = global_position
		
		# 6. If it's a particle system, ensure it starts emitting
	if explosion is GPUParticles3D or explosion is CPUParticles3D:
		explosion.emitting = true
	if dist < 2.: 
		print("damaged")
		var damage = 100./(dist)
		Globals.player.aging_component.age_damage(damage)
	
	
	# 4. Remove the object from the game
	queue_free()


	
	


func _on_health_component_damage() -> void:
	var explosion = explosion_scene2.instantiate()
	#AudioManager.play_3d(blast_sound,position,40)	
		# 4. Add it to the level (the enemy's parent)
	get_parent().add_child(explosion)
		
		# 5. Move it to the enemy's current position
	explosion.global_position = global_position
		
		# 6. If it's a particle system, ensure it starts emitting
	if explosion is GPUParticles3D or explosion is CPUParticles3D:
		explosion.emitting = true
	
	pass # Replace with function body.
