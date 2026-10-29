extends RayCast2D
class_name Sensor

enum Direction { Horizontal, Verticle, Degree45 }

@export var direction: Direction
var max_distance: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if direction == Direction.Horizontal:
		max_distance = abs(target_position.x)
	if direction == Direction.Verticle:
		max_distance = abs(target_position.y)
	if direction == Direction.Degree45:
		max_distance = abs(target_position.x) * sqrt(2)


func get_distance() -> float:
	if is_colliding():
		var distance = global_position.distance_to(get_collision_point())
		return distance / max_distance
	return 1.0
