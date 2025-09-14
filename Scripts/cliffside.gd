extends Node

@onready var respawn_point = $respawnpoint
@onready var transition_area = $TransitionArea

var player_scene = preload("res://Scenes/player.tscn")
var player_instance: Node = null

# Pause menu preload and instance
var pause_menu_instance: Node = null

func _ready():
	spawn_player()  # Spawn player first to ensure it's ready
	transition_area.body_entered.connect(_on_transition_area_body_entered)  # Connect the signal

func spawn_player():
	player_instance = player_scene.instantiate()
	player_instance.global_position = respawn_point.global_position
	add_child(player_instance)
	player_instance.connect("player_died", Callable(self, "_on_player_died"))
	
	# Ensure player is pausable (freezes on global pause, but processes input normally)
	player_instance.process_mode = Node.PROCESS_MODE_PAUSABLE


func _on_player_died():
	# Wait before respawn
	await get_tree().create_timer(1.5).timeout
	spawn_player()

func _on_transition_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Assuming player is in "player" group
		# Example: Transition back to world (customize as needed)
		get_tree().change_scene_to_file("res://Scenes/world.tscn")
		# If using your Global singleton: Global.current_scene = "world"; Global.finish_changing_scene()
