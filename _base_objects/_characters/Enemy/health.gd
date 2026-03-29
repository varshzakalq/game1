extends Component
class_name HealthComponent
var damage_audio = preload("uid://cq8xfv8qmfql2")
var blast_audio= preload("uid://cisc24go2238h")
@onready var enemy: CollisionShape3D = $"../CollisionShape3D"

# Signals allow other nodes (like UI or the Enemy) to react
signal health_changed(current_health, max_health)
signal died

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func _ready() -> void:
	current_health = max_health
	# Emit initial health so UI can sync up
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	AudioManager.play_3d(damage_audio,enemy.position,10)
	current_health -= amount
	# Clamp ensures we don't go below zero
	current_health = max(current_health, 0)
	
	health_changed.emit(current_health, max_health)
	print("Entity took damage. Current Health: ", current_health)
	
	if current_health <= 0:
		AudioManager.play_3d(blast_audio,enemy.position,10)
		die()

func die() -> void:
	died.emit()
