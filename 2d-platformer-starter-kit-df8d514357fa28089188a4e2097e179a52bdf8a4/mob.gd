extends RigidBody2D

@export var min_speed = 175.0
@export var max_speed = 350.0

var anim_list = ["mob1", "mob2", "mob3", "mob4", "mob5"]

func _ready():
	play_random_anim()

func play_random_anim():
	var random_index = randi() % anim_list.size()
	var anim_name = anim_list[random_index]
	$AnimatedSprite2D.play(anim_name)
	



func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
