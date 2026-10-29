extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -500.0
const GRAVITY := 1500

# 预加载音效资源,提高运行效率
const HIT := preload("res://assets/hit.wav")
const POINT := preload("res://assets/point.wav")
const WING := preload("res://assets/wing.wav")

var rot_degree := 0  # 当前转度
var is_dead := false

@export var max_speed := 700
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var fly_sound: AudioStreamPlayer2D = $FlySound
@onready var score_sound: AudioStreamPlayer2D = $ScoreSound
@onready var ai_ctrl: AIController2D = $AIController2D
@onready var sensors: Node2D = $Sensors


func _ready() -> void:
	#GameManager.GameStart.connect(on_game_start)
	GameManager.UpdateScore.connect(on_get_score)
	GameManager.GameOver.connect(on_game_over)
	ai_ctrl.init(self)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	ai_ctrl.reward += 0.01
	velocity.y += GRAVITY * delta
	var should_fly: bool = Input.is_action_just_pressed("fly") if ai_ctrl.heuristic == "human" else ai_ctrl.move_action == 1
	if should_fly:
		velocity.y = JUMP_VELOCITY
		fly_sound.stream = WING
		fly_sound.play()
	animated_sprite.rotation_degrees = clampf(-30.0 * velocity.y / JUMP_VELOCITY, -30, 30)
	velocity.y = clampf(velocity.y, -max_speed, max_speed)
	move_and_slide()


func on_game_start():
	is_dead = false
	particles.emitting = true


func on_get_score():
	ai_ctrl.reward += 1
	score_sound.stream = POINT
	score_sound.play()


func on_game_over():
	ai_ctrl.reward -= 5
	ai_ctrl.done = true
	ai_ctrl.reset()

	fly_sound.stream = HIT
	fly_sound.play()
	particles.emitting = false
	#is_dead = true
