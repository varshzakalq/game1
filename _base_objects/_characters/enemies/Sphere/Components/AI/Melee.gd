extends Sphere_control_base

var Attack_Range : float = 0.1
var Damage_Amount : float = 10

func _when_target_detected(delta : float):
	var target = main_body.Target
	var pos : Vector3 = main_body.global_position
	if pos.distance_to(target.global_position) < Attack_Range:
		_damage_target(target, Damage_Amount)
		
	else:
		main_body._move_towards(target.global_position)


func _damage_target(target, amount : float):
	if not target.has_method("take_damage"):
		push_error("Target has no method to take damage")
	else:
		main_body._play_melee_attack_animation()
		target.take_damage(amount)
