extends Node

var player_current_attack = false
var current_scene = "world"
var transition_scenes = false
var player_exit_cliffside_x = 0
var player_exit_cliffside_y = 0
var player_start_posex = 0
var player_start_posey = 0

func finish_changing_scene():
	if transition_scenes:
		transition_scenes = false
		if current_scene == "world":
			current_scene = "cliffside"
		else:
			current_scene = "world"
