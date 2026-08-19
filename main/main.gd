extends Node2D

const GAP = 180
var pipes_scene: PackedScene = preload("res://pipe/pipes.tscn")

@export var bird_init_pos := Vector2(160, 300)
@onready var timer: Timer = $SpawnPoint/SpawnTimer
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var bird: CharacterBody2D = $Bird
@onready var pipes_group: Node2D = $PipesGroup


func _ready() -> void:
	GameManager.GameOver.connect(on_game_over)
	GameManager.GameStart.connect(on_game_start)


func on_game_start():
	new_pipes()
	timer.start()


func on_game_over():
	timer.stop()
	reset_game()


func _on_ceil_body_entered(body: Node2D) -> void:
	on_hit_border(body)


func _on_floor_body_entered(body: Node2D) -> void:
	on_hit_border(body)


func _on_spawn_timer_timeout() -> void:
	new_pipes()


func on_hit_border(body: Node2D):
	if body.is_in_group("bird") and not body.is_dead:
		GameManager.GameOver.emit()


func new_pipes():
	var pipes: Node2D = pipes_scene.instantiate()
	# 随机高度
	var pos_y = randf_range(spawn_point.position.y - GAP, spawn_point.position.y + GAP)
	pipes.global_position.x = spawn_point.position.x
	pipes.global_position.y = pos_y
	pipes_group.add_child(pipes)


func reset_game():
	bird.global_position = bird_init_pos
	var pipes = pipes_group.get_children()
	for pipe in pipes:
		pipe.queue_free()
