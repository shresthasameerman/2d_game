extends Control

var game_tree
var is_game_paused: bool = false:
	set = set_game_paused

func _ready() -> void:
	game_tree = get_tree()
	# THIS IS THE FIX: Allow this node to process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause_Menu"):
		is_game_paused = !is_game_paused

func set_game_paused(value: bool) -> void:
	is_game_paused = value
	game_tree.paused = is_game_paused
	visible = is_game_paused

func _on_resume_pressed() -> void:
	is_game_paused = false

func _on_setting_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
