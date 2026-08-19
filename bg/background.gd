extends Parallax2D

const BASE_SPEED := -150


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	scroll_offset.x += BASE_SPEED * scroll_scale.x * delta
