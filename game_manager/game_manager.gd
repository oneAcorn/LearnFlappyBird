extends Node

signal GameStart
signal GameOver
signal UpdateScore

var score = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateScore.connect(add_score)
	GameOver.connect(on_game_over)


func add_score():
	score += 1


func on_game_over():
	score = 0
