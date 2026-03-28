extends Time_Character

func _physics_process(delta: float) -> void:

	if not _is_rewinding:
		var inp = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var input_dir = Vector2.ZERO
		input_dir.x = - inp.y
		input_dir.y = - inp.x
		_move_self(input_dir, delta)
		
		if Input.is_action_just_pressed("ui_accept"):
			_attempt_jump()
			
		# Remember to pass delta here once you update the base class!

		move_and_slide()
		
	# 4. Call the parent class so the snapshot interval timer can run
	super._physics_process(delta)
