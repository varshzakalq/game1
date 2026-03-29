extends Component
class_name AgingComponent

signal age_increased(current_age: float)
signal max_age_reached()
signal took_age_damage(severity : float)


@export var max_age: float = 100.0
@export var aging_multiplier: float = 1.0 
@export var current_age: float = 0.0:
	set(value):
		_age_changed(value)
		
		current_age = value
		if current_age > max_age:
			current_age = max_age


var ambient_age_rate = 0


func _ready() -> void:
	EventBus.ambient_aging.connect(_set_ambient_age)


func age_damage(val: float, multiploer: float = 1):
	var dmg = val * multiploer
	current_age += dmg
	took_age_damage.emit(dmg)
	

func increase_age(delta: float, multiplier : float = 1):
	current_age += delta * multiplier * 0.01

func _set_ambient_age(value: float):
	ambient_age_rate = value

func _process(delta: float) -> void:
	current_age += ambient_age_rate*delta
	#print(current_age)
	

func _age_changed(value : float):
	
	#current_age variable in this func is the value before the change was made
	
	if value > current_age:
		age_increased.emit(value)
	
