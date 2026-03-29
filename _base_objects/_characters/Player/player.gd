extends Time_Character
class_name Player

@export_category("Rollback Penalty Settings")
@export var penalty_fade_duration : float = 2.5 # How many seconds it takes to clear
@export var wave_distortion_strength : float = 0.4 # 1.0 is the original strong wave, 0.0 is no wave
var _penalty_tween : Tween

# ==========================================
# NODE REFERENCES
# ==========================================
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

# ==========================================
# FUNCTION BLOCKS
# ==========================================

func _ready() -> void:
	Globals.player = self
	just_finished_rewinding.connect(_on_rollback_finish)
	super._ready()

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

func _on_rollback_finish():
	var age = aging_component.current_age
	apply_rollback_penalty(age)

func age_effects(age : float):
	pass



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
	
