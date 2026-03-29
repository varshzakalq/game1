extends Time_Character
class_name Player

@onready var rewind_sfx : AudioStreamPlayer = $RewindSoundPlayer 


@export_category("Rollback Penalty Settings")
@export var penalty_fade_duration : float = 2.5 # How many seconds it takes to clear
@export var wave_distortion_strength : float = 0.4 # 1.0 is the original strong wave, 0.0 is no wave
var _penalty_tween : Tween

# ==========================================
# NODE REFERENCES
# ==========================================
@onready var mesh = $Mesh
#@onready var death_cam = $dead_cam
@onready var camera = %Camera
@onready var camera_rotation = camera.global_rotation.x :
	set(value):
		if camera.global_rotation.x != value:
			camera.global_rotation.x = value
			camera_rotation = value


# ==========================================
# MODULAR INPUT STATE
# ==========================================

var _input_direction : Vector2 = Vector2.ZERO
var _input_jump_requested : bool = false
var _input_sprint_held : bool = false


# ===============================
# PENALTY UI STUFF
# ===============================

var _penalty_rect : ColorRect
var _penalty_mat : ShaderMaterial
func _setup_penalty_ui() -> void:
	if _penalty_rect != null: return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10 
	add_child(canvas)
	
	_penalty_rect = ColorRect.new()
	canvas.add_child(_penalty_rect)
	
	_penalty_rect.size = get_viewport().get_visible_rect().size
	_penalty_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_penalty_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_penalty_mat = ShaderMaterial.new()
	var shader = Shader.new()
	
	shader.code = """
	shader_type canvas_item;
	
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
	uniform float intensity : hint_range(0.0, 1.0) = 0.0;
	
	// NEW: Independent control for the wave effect
	uniform float wave_multiplier : hint_range(0.0, 2.0) = 0.5;
	
	void fragment() {
		vec2 uv = SCREEN_UV;
		
		// Multiplied by wave_multiplier to dial down the nausea
		uv.x += sin(uv.y * 15.0 + TIME * 5.0) * 0.02 * intensity * wave_multiplier;
		uv.y += cos(uv.x * 15.0 + TIME * 4.0) * 0.02 * intensity * wave_multiplier;
		
		float r = texture(screen_texture, uv + vec2(0.015 * intensity, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(0.015 * intensity, 0.0)).b;
		vec3 color = vec3(r, g, b);
		
		float gray = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(color, vec3(gray), intensity * 0.85); 
		
		float dist = distance(SCREEN_UV, vec2(0.5));
		color.rgb *= smoothstep(0.8, 0.2, dist * (1.0 + intensity * 0.6));
		
		COLOR = vec4(color, 1.0);
	}
	"""
	_penalty_mat.shader = shader
	_penalty_rect.material = _penalty_mat

var _age_rect : ColorRect
var _age_mat : ShaderMaterial

func _setup_age_ui() -> void:
	if _age_rect != null: return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 9 
	add_child(canvas)
	
	_age_rect = ColorRect.new()
	canvas.add_child(_age_rect)
	
	_age_rect.size = get_viewport().get_visible_rect().size
	_age_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_age_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_age_mat = ShaderMaterial.new()
	var shader = Shader.new()
	
	shader.code = """
	shader_type canvas_item;
	
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
	uniform float intensity : hint_range(0.0, 1.0) = 0.0;
	uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
	
	void fragment() {
		vec2 uv = SCREEN_UV;
		
		// 1. Custom 9-Tap Blur
		vec3 color = vec3(0.0);
		float offset = 0.004 * blur_amount;
		
		color += texture(screen_texture, uv + vec2(-offset, -offset)).rgb;
		color += texture(screen_texture, uv + vec2(0.0, -offset)).rgb;
		color += texture(screen_texture, uv + vec2(offset, -offset)).rgb;
		color += texture(screen_texture, uv + vec2(-offset, 0.0)).rgb;
		color += texture(screen_texture, uv).rgb; // Center
		color += texture(screen_texture, uv + vec2(offset, 0.0)).rgb;
		color += texture(screen_texture, uv + vec2(-offset, offset)).rgb;
		color += texture(screen_texture, uv + vec2(0.0, offset)).rgb;
		color += texture(screen_texture, uv + vec2(offset, offset)).rgb;
		
		color /= 9.0; // Average the pixels out
		
		// 2. Very subtle color drain
		float gray = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(color, vec3(gray), intensity * 0.5); 
		
		COLOR = vec4(color, 1.0);
	}
	"""
	_age_mat.shader = shader
	_age_rect.material = _age_mat
	
# ===============================
# DAMAGE EFFECTS VARIABLES
# ===============================
var _damage_rect : ColorRect
var _damage_tween : Tween
@export var age_damage_reducing_factor : float = 10


# Camera Shake
var last_hit_severity : float = 1
var _camera_trauma : float = 0.0
@export var max_shake_offset : float = 0.3 # How far the camera violently jerks (in meters)

func _setup_damage_ui() -> void:
	if _damage_rect != null: return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 12 # Put this above absolutely everything
	add_child(canvas)
	
	_damage_rect = ColorRect.new()
	canvas.add_child(_damage_rect)
	_damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Start completely transparent. (White with a hint of sickly cyan)
	_damage_rect.color = Color(0.9, 1.0, 1.0, 0.0)

# ===============================
# ACTIVE REWIND EFFECTS
# ===============================
var _rewind_cleanup_tween : Tween
var _active_rewind_rect : ColorRect
var _active_rewind_mat : ShaderMaterial


func _setup_active_rewind_ui() -> void:
	if _active_rewind_rect != null: return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 11 # Sits on top of absolutely everything
	add_child(canvas)
	
	_active_rewind_rect = ColorRect.new()
	canvas.add_child(_active_rewind_rect)
	
	_active_rewind_rect.size = get_viewport().get_visible_rect().size
	_active_rewind_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_active_rewind_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_active_rewind_mat = ShaderMaterial.new()
	var shader = Shader.new()
	
	shader.code = """
	shader_type canvas_item;
	
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
	uniform float intensity : hint_range(0.0, 1.0) = 0.0;
	uniform float time;
	
	void fragment() {
		vec2 uv = SCREEN_UV;
		
		// 1. Violent horizontal VHS tearing
		float tear = sin(uv.y * 40.0 + time * 25.0) * 0.015 * intensity;
		
		// 2. Extreme Chromatic Aberration (RGB Split) pulling outward
		float r = texture(screen_texture, vec2(uv.x + tear + (0.04 * intensity), uv.y)).r;
		float g = texture(screen_texture, vec2(uv.x + tear, uv.y)).g;
		float b = texture(screen_texture, vec2(uv.x + tear - (0.04 * intensity), uv.y)).b;
		
		// 3. Fast rolling scanlines
		float scanline = sin(uv.y * 600.0 - time * 40.0) * 0.05 * intensity;
		
		COLOR = vec4(r - scanline, g - scanline, b - scanline, 1.0);
	}
	"""
	_active_rewind_mat.shader = shader
	_active_rewind_rect.material = _active_rewind_mat
	_active_rewind_rect.visible = false # Keep hidden until rewind starts
	
# ==========================================
# CORE LOOP
# ==========================================

func _physics_process(delta: float) -> void:
	
	_gather_inputs()
	
	
	if not _is_rewinding:
		_process_normal_movement(delta)
		
		move_and_slide()
		
	#EXTREMELY IMPORTANT
	super._physics_process(delta)

func _process(delta: float) -> void:
	age_effects(delta)
	
	# --- CAMERA SHAKE LOGIC ---
	if _camera_trauma > 0.0:
		# Decay the trauma over time (takes about 0.5 seconds to calm down completely)
		_camera_trauma = move_toward(_camera_trauma, 0.0, delta * 2.0)
		
		# Squaring the trauma is the golden rule of screen shake: 
		# It makes the camera snap violently at the start, then settle very smoothly.
		var shake_power = _camera_trauma * _camera_trauma * last_hit_severity * 0.01
		
		if camera != null:
			camera.h_offset = randf_range(-1.0, 1.0) * max_shake_offset * shake_power
			camera.v_offset = randf_range(-1.0, 1.0) * max_shake_offset * shake_power
	else:
		# Snap the camera back to perfectly dead-center once the shaking stops
		if camera != null and (camera.h_offset != 0.0 or camera.v_offset != 0.0):
			camera.h_offset = 0.0
			camera.v_offset = 0.0
	


# ==========================================
# FUNCTION BLOCKS
# ==========================================

func _ready() -> void:
	
	Globals.player = self
	just_finished_rewinding.connect(_on_rollback_finish)
	super._ready()
	if Globals.player_age != -1:
		aging_component.current_age = Globals.player_age

func _gather_inputs() -> void:
	# Capture movement vector (Normalized automatically by get_vector)
	_input_direction = Input.get_vector("Forward", "Backward", "Left", "Right")
	
	# Capture discrete actions
	_input_jump_requested = Input.is_action_just_pressed("Jump")
	
	# Capture continuous actions
	_input_sprint_held = Input.is_action_pressed("Sprint")

func _process_normal_movement(delta: float) -> void:
	
	# Apply standard directional movement
	_is_sprinting = _input_sprint_held
	_move_self(_input_direction, delta)
	
	# Apply jump logic
	if _input_jump_requested:
		_attempt_jump()


func _rollback(delta: float) -> void:
	super._rollback(delta)
	
	if _reached_history_end:
		return
		
	if _active_rewind_rect == null:
		_setup_active_rewind_ui()
		
	# 1. Base rewind speed percentage (0.0 to 1.0)
	var rewind_percentage = clamp((_current_rewind_speed - MIN_REWIND_SPEED) / (MAX_REWIND_SPEED - MIN_REWIND_SPEED), 0.0, 1.0)
	
	# 2. Calculate the exact severity the age penalty WILL be
	var age = 0.0
	if aging_component != null:
		age = aging_component.current_age
		
	var normalized_age = clamp(age / 100.0, 0.0, 1.0)
	var penalty_severity = pow(normalized_age, 1.5)
	
	# 3. Set the ceiling for the visuals
	# We use max(0.2, penalty_severity) so healthy players still get a *little* bit of visual feedback!
	var target_max_intensity = max(0.2, penalty_severity)
	
	# 4. Final blended intensity
	var intensity = rewind_percentage * target_max_intensity
	
	# --- APPLY EFFECTS ---
	
	# Camera FOV "Woosh" 
	camera.fov = lerp(camera.fov, 120.0 + (90.0 * intensity), 10.0 * delta)
	
	# Update the Shader
	_active_rewind_rect.visible = true
	_active_rewind_mat.set_shader_parameter("intensity", intensity)
	_active_rewind_mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
	
	# AUDIO HOOK
	if rewind_sfx != null:
		if not rewind_sfx.playing:
			rewind_sfx.play()
		rewind_sfx.pitch_scale = 1.0 + (intensity * 0.8)
func _on_rollback_finish() -> void:
	# 1. Trigger the age penalty so it starts the exact frame the rewind ends
	if aging_component != null:
		var age = aging_component.current_age
		apply_rollback_penalty(age)
		
	# 2. Kill any previous cleanup tween just in case
	if _rewind_cleanup_tween and _rewind_cleanup_tween.is_valid():
		_rewind_cleanup_tween.kill()
		
	_rewind_cleanup_tween = create_tween()
	_rewind_cleanup_tween.set_parallel(true) # Make all following tweens happen simultaneously
	
	# A. Melt the VHS shader away smoothly
	if _active_rewind_rect != null:
		# Grabs whatever intensity it ended at, and fades it to 0 over 0.6 seconds
		var current_intensity = _active_rewind_mat.get_shader_parameter("intensity")
		_rewind_cleanup_tween.tween_property(_active_rewind_mat, "shader_parameter/intensity", 0.0, 0.6).from(current_intensity).set_ease(Tween.EASE_OUT)
		
	# B. Smoothly snap the camera FOV back to normal
	if camera != null:
		_rewind_cleanup_tween.tween_property(camera, "fov", 75.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
	# C. Wind down the audio (like a record player stopping)
	if rewind_sfx != null and rewind_sfx.playing:
		_rewind_cleanup_tween.tween_property(rewind_sfx, "pitch_scale", 0.1, 0.5)
		_rewind_cleanup_tween.tween_property(rewind_sfx, "volume_db", -40.0, 0.5)
		
	# 3. After the 0.6 second fade out is completely finished, run the hard resets
	_rewind_cleanup_tween.chain().tween_callback(_hard_reset_rewind_state)

# A small helper function to reset everything once the tweens are done
func _hard_reset_rewind_state() -> void:
	if _active_rewind_rect != null:
		_active_rewind_rect.visible = false
		
	if rewind_sfx != null:
		rewind_sfx.stop()
		rewind_sfx.volume_db = 0.0 # Reset the volume for the next time we rewind

func age_effects(delta: float) -> void:
	
	Globals.player_age = aging_component.current_age
	if aging_component == null: return
	var age = aging_component.current_age
	
	if _age_rect == null:
		_setup_age_ui()
		
	# Normalize age to a 0.0 -> 1.0 scale
	var normalized_age = clamp(age / 100.0, 0.0, 1.0)
	
	# Using pow() with high exponents keeps the value extremely low 
	# until the player reaches old age, then it spikes up rapidly.
	
	# General sickness/wave stays invisible until ~age 40
	var passive_intensity = pow(normalized_age, 3.0) 
	
	# Blur is even more punishing, staying clear until ~age 60
	var blur_intensity = pow(normalized_age, 5.0) 
	
	_age_mat.set_shader_parameter("intensity", passive_intensity)
	_age_mat.set_shader_parameter("blur_amount", blur_intensity/1.4)


func _on_age_damage(amount: float) -> void:
	last_hit_severity = amount
	# Ensure the rewind UI actually exists before we try to glitch it
	if _active_rewind_rect == null:
		_setup_active_rewind_ui()
		
	# 1. Calculate Severity
	# 10 years of damage pushes the VHS glitch to a maximum 1.0 intensity
	var hit_severity = clamp(amount / age_damage_reducing_factor, 0.4, 1.0)
	
	# 2. The Time-Glitch Visual Spike
	_active_rewind_rect.visible = true
	
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
		
	_damage_tween = create_tween()
	_damage_tween.set_parallel(true)
	
	# Instantly snap the VHS shader to a violent tear, then fade it out over 0.5s
	_active_rewind_mat.set_shader_parameter("intensity", hit_severity)
	_damage_tween.tween_property(_active_rewind_mat, "shader_parameter/intensity", 0.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Violently kick the camera FOV backwards to simulate a physical blow
	if camera != null:
		var target_fov = 75.0 + (30.0 * hit_severity)
		camera.fov = target_fov
		# Elastic ease makes the camera physically bounce back into place
		_damage_tween.tween_property(camera, "fov", 75.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	# 3. Cleanup
	# Only hide the VHS effect if the player isn't actively holding the rewind button!
	_damage_tween.chain().tween_callback(func():
		if not _is_rewinding:
			_active_rewind_rect.visible = false
	)
	
	# 4. Inject Camera Trauma (Screen Shake)
	_camera_trauma = clamp(_camera_trauma + hit_severity, 0.0, 1.0)

func apply_rollback_penalty(age : float) -> void:
	if _penalty_rect == null:
		_setup_penalty_ui()
		
	var normalized_age = clamp(age / 100.0, 0.0, 1.0)
	var effect_severity = pow(normalized_age, 1.5)
	
	# Pass your custom wave strength into the shader
	_penalty_mat.set_shader_parameter("wave_multiplier", wave_distortion_strength)
	
	# 1. Kill any existing fade (in case the player rewinds twice in a row rapidly)
	if _penalty_tween and _penalty_tween.is_valid():
		_penalty_tween.kill()
		
	# 2. Instantly snap the visual distortion to the calculated severity
	_penalty_mat.set_shader_parameter("intensity", effect_severity)
	
	# 3. Create a Tween to smoothly fade the intensity back down to 0.0
	_penalty_tween = create_tween()
	
	# Use an ease-out curve so it clears quickly at first, then gently lingers
	_penalty_tween.set_trans(Tween.TRANS_SINE)
	_penalty_tween.set_ease(Tween.EASE_OUT)
	
	# Godot 4 allows us to tween shader parameters directly using this exact string path
	_penalty_tween.tween_property(_penalty_mat, "shader_parameter/intensity", 0.0, penalty_fade_duration)
	





#func death_aniamtion():
	#
	#camera.current = false
	#death_cam.current = true
	#mesh.hide()
