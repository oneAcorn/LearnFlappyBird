extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -500.0
const GRAVITY := 1500

# 预加载音效资源,提高运行效率
const HIT := preload("res://assets/hit.wav")
const POINT := preload("res://assets/point.wav")
const WING := preload("res://assets/wing.wav")

var rot_degree := 0  # 当前转度
var is_dead := true

@export var max_speed := 700
@onready var animated_sprite := $AnimatedSprite2D
@onready var particles := $CPUParticles2D
@onready var fly_sound := $FlySound
@onready var score_sound := $ScoreSound


func _physics_process(delta: float) -> void:
	if not is_dead:
		velocity.y += GRAVITY * delta

		if Input.is_action_just_pressed("fly"):
			velocity.y = JUMP_VELOCITY
			fly_sound.stream = WING
			fly_sound.play()

		# 根据当前纵向速度计算俯仰角
		# 使用clampf将旋转限制指定角度之间
		rot_degree = clampf(-30 * velocity.y / JUMP_VELOCITY, -30, 30)
		rotation_degrees = rot_degree

		# 确保速度不会限增加
		velocity.y = clampf(velocity.y, -max_speed, max_speed)

		move_and_slide()
