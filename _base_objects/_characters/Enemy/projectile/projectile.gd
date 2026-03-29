class_name TemporalProjectile
extends Time_Character

enum targets{
	Player,
	Enemy
}

@export_category("Projectile Stats")
@export var speed: float = 30.0
@export var damage: float = 25.0
@export var lifetime: float = 5.0
@export var target: targets = targets.Player

@export_category("Homing Settings")
@export var is_homing: bool = false
@export var turn_speed: float = 5.0 # How sharply it can correct its course

var current_target: Node3D = null
var _alive_timer: float = 0.0

# ==========================================
# INITIALIZATION
# ==========================================
func _ready() -> void:
	# Crucial: Let Time_Character set up its history arrays
	super._ready() 

# Call this from whatever script spawns the projectile!
func fire(spawn_transform: Transform3D, target: Node3D = null) -> void:
	global_transform = spawn_transform
	current_target = target
	
	# Instantly snap the bullet to aim at the target's chest before frame 1
	if current_target != null and is_instance_valid(current_target):
		look_at(current_target.global_position, Vector3.UP)
# ==========================================
# MOVEMENT OVERRIDE
# ==========================================
# By overriding this specific parent function, the projectile will fly 
# automatically but still freeze/rewind perfectly when _is_rewinding is true.
func _process_normal_movement(delta: float) -> void:
	_alive_timer += delta
	if _alive_timer >= lifetime:
		queue_free()
		return

	# Default: Fly straight forward
	var flight_direction = -global_transform.basis.z.normalized()

	# Homing Logic: Steer towards the target if we have one
	if is_homing and current_target != null and is_instance_valid(current_target):
		var direction_to_target = global_position.direction_to(current_target.global_position)
		flight_direction = flight_direction.lerp(direction_to_target, turn_speed * delta).normalized()
		
		# Visually rotate the bullet to face its new trajectory
		look_at(global_position + flight_direction, Vector3.UP)

	# Apply the velocity for the parent's move_and_slide() to use
	velocity = flight_direction * speed

# ==========================================
# IMPACT & DAMAGE LOGIC
# ==========================================
# Connect an Area3D's 'body_entered' signal to this function!
func _on_hitbox_body_entered(body: Node3D) -> void:
	# If we are currently rewinding, we shouldn't deal damage or explode!
	if _is_rewinding:
		return
		
	match target:
		targets.Player:
			if not body is Player: return
			_deal_age_damage(body)
		targets.Enemy:
			if not body is StandardEnemy: return
			_deal_damage_to_enemy(body)
			

	
	# Optional: Spawn an explosion particle here before deleting
	

func _deal_age_damage(target_body: Player):
	
	if not target_body.aging_component:
		push_error("NO AGING COMPONENT IN PLAYER")
		queue_free()
		return
	
	target_body.aging_component.age_damage(damage)
	
	queue_free()
	

func _deal_damage_to_enemy(target_body: Time_Character) -> void:
	
	if not target_body.health_component:
		push_error("NO HEALTH COMPONENT IN ENEMY")
		queue_free()
		return

	print("Projectile hit: ", target_body.name, " for ", damage, " damage!")

	
	queue_free()
