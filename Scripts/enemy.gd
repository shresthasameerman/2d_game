extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_2d: Camera2D = $Camera2d
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_attack_cooldown_timer: Timer = $PlayerAttackCooldownTimer
@onready var player_damage_timer: Timer = $PlayerDamageTimer # New timer for continuous damage

var SPEED = 20
var Player_Chase = false
var Player = null
var health = 150
var player_in_my_attack_zone = false # For the enemy to attack the player
var can_take_damage = true
var damage_to_player = 15 # Normal damage amount
var player_is_in_area = false # New flag to check if player is in the area

# --- Updated: Patrolling variables ---
@export var PATROL_DISTANCE: float = 100.0  # Distance for each side of the square patrol
var patrol_state: int = 0  # 0 = right, 1 = up, 2 = left, 3 = down
var patrol_start_pos: Vector2
var patrol_target: Vector2
const PATROL_MARGIN: float = 2.0  # Margin for reaching target

# Store original color so we can reset
var original_modulate: Color

# --- Knockback variables ---
var knockback_vector: Vector2 = Vector2.ZERO
@export var KNOCKBACK_FORCE: float = 80.0
@export var KNOCKBACK_DECAY: float = 8.0

# --- Slash Attack variables ---
@export var SLASH_SPEED: float = 120.0     # Burst movement speed
@export var SLASH_DURATION: float = 0.3    # How long the slash lasts
@export var SLASH_COOLDOWN: float = 2.0    # Cooldown before next slash
@export var SLASH_DAMAGE: int = 20         # Extra damage if slash connects
var can_slash_attack: bool = true
var is_slashing: bool = false

func _ready():
	original_modulate = animated_sprite.modulate
	reset_visuals()
	patrol_start_pos = position  # Set patrol center to starting position
	patrol_target = patrol_start_pos + Vector2(PATROL_DISTANCE, 0)  # Start by moving right
	patrol_state = 0

	# Connect the new timer's timeout signal
	$PlayerDamageTimer.connect("timeout", Callable(self, "_on_player_damage_timer_timeout"))

func reset_visuals():
	animated_sprite.modulate = original_modulate
	animation_player.stop()

func _physics_process(delta: float):
	deal_with_damage()

	# Apply knockback if active
	if knockback_vector.length() > 1:
		velocity = knockback_vector
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, KNOCKBACK_DECAY)
		move_and_slide()
		return

	# Slash attack movement
	if is_slashing:
		move_and_slide()
		return

	if Player_Chase and Player != null:
		# Random chance to trigger slash attack
		if can_slash_attack and randi() % 100 < 3: # ~3% chance per frame
			do_slash_attack()
		else:
			var direction = (Player.position - position).normalized()
			velocity = direction * SPEED

			if velocity.x > 0:
				animated_sprite.flip_h = false
			elif velocity.x < 0:
				animated_sprite.flip_h = true

			if animated_sprite.animation != "Walk":
				animated_sprite.play("Walk")

			move_and_slide()
	else:
		# --- Updated: Square patrol logic when not chasing ---
		var direction = (patrol_target - position).normalized()
		velocity = direction * SPEED

		position += velocity * delta
		move_and_slide()

		# Check if reached target
		if position.distance_to(patrol_target) < PATROL_MARGIN:
			patrol_state = (patrol_state + 1) % 4  # Cycle through states
			match patrol_state:
				0:  # Right
					patrol_target = patrol_start_pos + Vector2(PATROL_DISTANCE, 0)
					animated_sprite.flip_h = false
				1:  # Up
					patrol_target = patrol_start_pos + Vector2(0, -PATROL_DISTANCE)
				2:  # Left
					patrol_target = patrol_start_pos + Vector2(-PATROL_DISTANCE, 0)
					animated_sprite.flip_h = true
				3:  # Down
					patrol_target = patrol_start_pos + Vector2(0, PATROL_DISTANCE)

		# Play walk animation during movement
		if velocity.length() > 0:
			if animated_sprite.animation != "Walk":
				animated_sprite.play("Walk")
		else:
			if animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")

# --- Slash Attack ---
func do_slash_attack():
	if Player == null: return
	can_slash_attack = false
	is_slashing = true

	var direction = (Player.position - position).normalized()
	velocity = direction * SLASH_SPEED

	# Speed up animation to look aggressive
	animated_sprite.play("Walk")
	animated_sprite.speed_scale = 2.0  # make walk look faster

	# Slash does extra damage if player is in range
	if player_is_in_area and Player != null and Player.has_method("take_damage"):
		Player.take_damage(SLASH_DAMAGE)

	# End slash after short time
	await get_tree().create_timer(SLASH_DURATION).timeout
	is_slashing = false
	animated_sprite.speed_scale = 1.0  # reset speed

	# Start cooldown
	await get_tree().create_timer(SLASH_COOLDOWN).timeout
	can_slash_attack = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	Player = body
	Player_Chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	Player = null
	Player_Chase = false

func _on_enemy_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_is_in_area = true
		# Start the continuous damage timer
		$PlayerDamageTimer.start()

func _on_enemy_hit_box_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_is_in_area = false
		# Stop the continuous damage timer
		$PlayerDamageTimer.stop()

func deal_with_damage():
	if player_is_in_area and Global.player_current_attack:
		if can_take_damage:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.camera_2d:
				player.camera_2d.trigger_shake()

			health -= 25
			$"take damage cooldown".start()
			can_take_damage = false
			print("slime health =", health)

			animation_player.play("hitflashenemy")

			# --- Apply Knockback ---
			if player:
				knockback_vector = (position - player.position).normalized() * KNOCKBACK_FORCE

			if health <= 0:
				die()

# --- New: Enemy death handling ---
func die():
	velocity = Vector2.ZERO  # Stop movement
	Player_Chase = false     # Stop chasing
	animation_player.play("death")  # Play death animation

	# Disable collisions so player can’t interact
	$CollisionShape2D.disabled = true

	# Wait until the animation finishes, then remove enemy
	await animation_player.animation_finished
	queue_free()

func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true

# --- New: Player Damage Timer function ---
func _on_player_damage_timer_timeout() -> void:
	# If the player is still in the area, deal damage
	if player_is_in_area and Player != null and Player.has_method("take_damage"):
		Player.take_damage(damage_to_player)
