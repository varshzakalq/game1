extends Time_Character

func _physics_process(delta: float) -> void:
	# 1. Handle Rewind Input (Held down)
	# Replace "ui_undo" with whatever action you mapped in Project Settings, or use Input.is_key_pressed(KEY_R)
	if Input.is_action_pressed("Rewind"):
		_rollback(delta)
	else:
		# Check if the button was just let go to reset our speed and states
		if Input.is_action_just_released("Rewind"):
			_stop_rollback()
			
		# 2. Handle Normal Input ONLY if we aren't rewinding
		if not _is_rewinding:
			var inp = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			var input_dir = Vector2.ZERO
			input_dir.x = - inp.y
			input_dir.y = - inp.x
			_move_self(input_dir, delta)
			
			if Input.is_action_just_pressed("ui_accept"):
				_attempt_jump()
				
			# Remember to pass delta here once you update the base class!
			_get_gravity(delta) 
			
	# 3. Apply Physics Movement
	# We ONLY call move_and_slide when we are NOT rewinding. 
	# Why? Because during a rewind, the Tween is explicitly teleporting the 'position' 
	# back through time. If move_and_slide() runs at the same time, the physics engine 
	# will fight the Tween and cause stuttering.
	if not _is_rewinding:
		move_and_slide()
		
	# 4. Call the parent class so the snapshot interval timer can run
	super._physics_process(delta)
