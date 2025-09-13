extends CharacterBody2D

signal player_died

@onready var hit_animation_player: AnimationPlayer = $HitAnimationPlayer
@onready var camera_2d: Camera2D = $Camera2D
@onready var cliffside_camera: Camera2D = $CliffSideCamera
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_cooldown: Timer = $attack_cooldown
@onready var deal_attack_timer: Timer = $deal_attack_timer

const SPEED = 100
var Current_Dir = "none"
var Enemy_inAttack_Range = false
var health = 200
var player_alive = true
var Enemy_attack_cooldown = true
var attack_IP = false
var start_position: Vector2

func _ready():
	add_to_group("player")
	attack_cooldown.connect("timeout", Callable(self, "_on_attack_cooldown_timeout"))
	hit_animation_player.connect("animation_finished", Callable(self, "_on_hit_animation_player_animation_finished"))
	deal_attack_timer.connect("timeout", Callable(self, "_on_deal_attack_timer_timeout"))
	
	start_position = global_position
	
	if is_instance_valid(health_bar):
		health_bar.max_value = health
		update_health_bar()
	else:
		print("ERROR: HealthBar node not found. Please check the path in @onready var health_bar: ProgressBar = $HealthBar")

func _physics_process(delta: float):
	if player_alive:
		player_movement(delta)
		attack()
		enemy_attack()
		current_camera()

	if health <= 0 and player_alive:
		player_alive = false
		die()

func player_movement(delta):
	velocity = Vector2.ZERO
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if direction.length() > 0:
		velocity = direction.normalized() * SPEED
		if Input.is_action_pressed("ui_right"):
			Current_Dir = "right"
		elif Input.is_action_pressed("ui_left"):
			Current_Dir = "left"
		elif Input.is_action_pressed("ui_down"):
			Current_Dir = "down"
		elif Input.is_action_pressed("ui_up"):
			Current_Dir = "up"
		play_anim(1)
	else:
		play_anim(0)
	
	move_and_slide()

func play_anim(movement):
	var dir = Current_Dir

	if dir == "right":
		animated_sprite_2d.flip_h = false
		if movement == 1:
			animated_sprite_2d.play("Side_Walk")
		elif movement == 0 and !attack_IP:
			animated_sprite_2d.play("Side_Idle")
	elif dir == "left":
		animated_sprite_2d.flip_h = true
		if movement == 1:
			animated_sprite_2d.play("Side_Walk")
		elif movement == 0 and !attack_IP:
			animated_sprite_2d.play("Side_Idle")
	elif dir == "down":
		animated_sprite_2d.flip_h = false
		if movement == 1:
			animated_sprite_2d.play("Front_Walk")
		elif movement == 0 and !attack_IP:
			animated_sprite_2d.play("Idle")
	elif dir == "up":
		animated_sprite_2d.flip_h = false
		if movement == 1:
			animated_sprite_2d.play("Back_Walk")
		elif movement == 0 and !attack_IP:
			animated_sprite_2d.play("Back_Idle")

func player():
	pass

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		Enemy_inAttack_Range = true

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		Enemy_inAttack_Range = false

func enemy_attack():
	if Enemy_inAttack_Range and Enemy_attack_cooldown:
		health -= 20
		Enemy_attack_cooldown = false
		attack_cooldown.start()
		print("Player health: ", health)
		update_health_bar()
		if health > 0:
			hit_animation_player.play("Hit")

func _on_attack_cooldown_timeout() -> void:
	Enemy_attack_cooldown = true

func attack():
	var dir = Current_Dir
	if Input.is_action_just_pressed("attack"):
		Global.player_current_attack = true
		attack_IP = true
		if dir == "right":
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play("Side_Attack")
			deal_attack_timer.start()
		elif dir == "left":
			animated_sprite_2d.flip_h = true
			animated_sprite_2d.play("Side_Attack")
			deal_attack_timer.start()
		elif dir == "down":
			animated_sprite_2d.play("Front_Attack")
			deal_attack_timer.start()
		elif dir == "up":
			animated_sprite_2d.play("Back_Attack")
			deal_attack_timer.start()

func _on_deal_attack_timer_timeout() -> void:
	deal_attack_timer.stop()
	Global.player_current_attack = false
	attack_IP = false

func take_damage(amount: int) -> void:
	if player_alive:
		health -= amount
		print("Player health = ", health)
		update_health_bar()
		hit_animation_player.play("Hit")

		if health <= 0:
			health = 0
			die()

func die() -> void:
	player_alive = false
	print("player dead")
	animated_sprite_2d.play("Death")
	emit_signal("player_died")
	queue_free()

func _on_hit_animation_player_animation_finished():
	hit_animation_player.stop()

func current_camera():
	if Global.current_scene == "world":
		camera_2d.enabled = true
		cliffside_camera.enabled = false
	elif Global.current_scene == "cliffside":
		camera_2d.enabled = false
		cliffside_camera.enabled = true

func update_health_bar():
	if is_instance_valid(health_bar):
		health_bar.value = health
	
func respawn():
	health = 200
	player_alive = true
	attack_IP = false
	Enemy_inAttack_Range = false
	Enemy_attack_cooldown = true
	global_position = start_position
	animated_sprite_2d.play("Idle")
	update_health_bar()
