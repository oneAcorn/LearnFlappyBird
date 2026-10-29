extends Area2D


func get_distance():
	if has_overlapping_areas():
		var others = get_overlapping_areas()
		if others.size() > 0:
			var other = others[0]
			var distance = other.global_position.y - global_position.y
			# 屏幕纵轴尺寸800
			return distance / 800
	else:
		return 0
