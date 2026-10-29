extends Node2D


func get_observation():
	var distances: Array
	for c in get_children():
		distances.append(c.get_distance())
	return distances
