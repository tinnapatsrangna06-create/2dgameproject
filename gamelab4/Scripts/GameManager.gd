# This script is an autoload, that can be accessed from any other script!

extends Node2D

var score : int = 0
var hp : int= 0
var currentlevel :PackedScene=null
var player = null

# Adds 1 to score variable
func add_score():
	score += 1

func damage(dm):
	hp -= dm
	AudioManager.death_sfx.play()
# Loads next level
func load_next_level(next_scene : PackedScene):
	get_tree().change_scene_to_packed(next_scene)
