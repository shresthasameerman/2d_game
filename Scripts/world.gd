extends Node

@onready var respawn_point = $respawnpoint
@onready var transition_area = $TransitionArea

var player_scene = preload("res://Scenes/player.tscn")
var player_instance: Node = null

func _ready():
	spawn_player()
	transition_area.body_entered.connect(_on_area_2d_body_entered)

func spawn_player():
	player_instance = player_scene.instantiate()
	player_instance.global_position = respawn_point.global_position
	add_child(player_instance)
	player_instance.connect("player_died", Callable(self, "_on_player_died"))

func _on_player_died():
	# Wait before respawn
	await get_tree().create_timer(1.5).timeout
	spawn_player()

func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		change_scene()

func change_scene():
	if Global.current_scene == "cliffside":
		get_tree().change_scene_to_file("res://Scenes/world.tscn")
		Global.finish_changing_scene()
