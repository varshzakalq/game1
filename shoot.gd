extends Node3D
#for getting collison object and giving damage
@onready var ray_cast_3d: RayCast3D = $RayCast3D


# Called when the node enters the scene tree for the first time.
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		shoot()

func shoot() -> void:
	var ray = $RayCast3D 
	
	if ray.is_colliding():
		var hit_object = ray.get_collider()
		
		# 1. Look for the child named "HealthComponent"
		var health = hit_object.get_node_or_null("health")
		
		# 2. If it exists, call the take_damage function
		if health:
			health.take_damage(25.0)
			print("Hit a destructible object!")
		else:
			print("Hit something with no health component (like a wall).")
