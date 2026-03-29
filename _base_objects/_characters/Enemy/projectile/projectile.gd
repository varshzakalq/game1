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
@export var turn_speed: float = 5.0 

var current_target: Node3D = null
var _alive_timer: float = 0.0

# ==========================================
# INITIALIZATION
# ==========================================
func _ready() -> void:
	super._ready() 

func fire(spawn_transform: Transform3D, target_node: Node3D = null) -> void:
	global_transform = spawn_transform
	current_target = target_node
	
	if current_target != null and is_instance_valid(current_target):
		look_at(current_target.global_position, Vector3.UP)

# ==========================================
# MOVEMENT OVERRIDE
# ==========================================
func _process_normal_movement(delta: float) -> void:
	_alive_timer += delta
	if _alive_timer >= lifetime:
		queue_free()
		return

	var flight_direction = -global_transform.basis.z.normalized()

	if is_homing and current_target != null and is_instance_valid(current_target):
		var direction_to_target = global_position.direction_to(current_target.global_position)
		flight_direction = flight_direction.lerp(direction_to_target, turn_speed * delta).normalized()
		look_at(global_position + flight_direction, Vector3.UP)

	velocity = flight_direction * speed

# ==========================================
# IMPACT & DAMAGE LOGIC
# ==========================================
func _on_hitbox_body_entered(body: Node3D) -> void:
	if _is_rewinding:
		return
		
	match target:
		targets.Player:
			if not body is Player: return
			_deal_age_damage(body)
		targets.Enemy:
			# Changed from Time_Character to StandardEnemy to match your logic!
			if not body is StandardEnemy: return 
			_deal_damage_to_enemy(body)

func _deal_age_damage(target_body: Player):
	if not target_body.aging_component:
		push_error("NO AGING COMPONENT IN PLAYER")
		queue_free()
		return
	
	target_body.aging_component.age_damage(damage)
	
	# Optional: Spawn an explosion particle here
	queue_free()

func _deal_damage_to_enemy(target_body: StandardEnemy) -> void:
	if not target_body.health_component:
		push_error("NO HEALTH COMPONENT IN ENEMY")
		queue_free()
		return

	# target_body.health_component.take_damage(damage) # Or whatever your exact function is!
	print("Projectile hit: ", target_body.name, " for ", damage, " damage!")
	
	# Optional: Spawn an explosion particle here
	queue_free()
