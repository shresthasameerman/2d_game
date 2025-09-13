extends Node

@onready var respawn_point = $respawnpoint
@onready var transition_area = $TransitionArea

var player_scene = preload("res://Scenes/player.tscn")
var player_instance: Node = null

func _ready():
	spawn_player()

func spawn_player():
	player_instance = player_scene.instantiate()
	player_instance.global_position = respawn_point.global_position
	add_child(player_instance)
	player_instance.connect("player_died", Callable(self, "_on_player_died"))

func _on_player_died():
	# Wait before respawn
	await get_tree().create_timer(1.5).timeout
	spawn_player()


func _on_transition_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
