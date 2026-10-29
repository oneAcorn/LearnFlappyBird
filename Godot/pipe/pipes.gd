extends Node2D

const SPEED := -150  # 向左移动
var passed := false  # 小鸟是否已通过,防止重复计分

@onready var coin: Area2D = $Coin
#@onready var pipe_bottom: Area2D = $PipeBottom
#@onready var pipe_top: Area2D = $PipeTop
#@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var animation_player: AnimationPlayer = $Coin/AnimationPlayer


func _process(delta: float) -> void:
	position.x += delta * SPEED


func _on_pipe_body_entered(body: Node2D) -> void:
	if body.is_in_group("bird") and not body.is_dead:
		GameManager.GameOver.emit()


func _on_coin_body_entered(body: Node2D) -> void:
	# 如果小鸟通过,且前未计分
	if body.is_in_group("bird") and not passed:
		passed = true
		GameManager.UpdateScore.emit()
		animation_player.play("coin")

		await animation_player.animation_finished
		coin.queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
