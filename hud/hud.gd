extends CanvasLayer

@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var message: Label = $MarginContainer/VBoxContainer/Message
@onready var start_btn: Button = $MarginContainer/VBoxContainer/StartBtn


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_score()
	GameManager.GameOver.connect(on_game_over)
	GameManager.UpdateScore.connect(update_score)


func update_score():
	score_label.text = "Score: %s" % str(GameManager.score)


func on_game_over():
	update_score()
	message.text = "GAME OVER"
	message.show()
	start_btn.show()


func _on_start_btn_pressed() -> void:
	GameManager.GameStart.emit()
	message.hide()
	start_btn.hide()
