extends CharacterBody2D

@export var speed = 40
@export var gravity : float = 30
@export var sprite = "chicken"
var time_run = 0

func _ready() -> void:
	$AnimatedSprite2D.play(sprite)
	velocity.x = speed if randf()< 0.5 else -speed
	
func _process(delta: float) -> void:		
	if !is_on_floor():
		velocity.y += gravity
	if time_run > 1 && is_on_wall():
		velocity.x = -velocity.x
		time_run = 0
	if  !$AnimatedSprite2D.is_playing() || $AnimatedSprite2D.animation != sprite :
		$AnimatedSprite2D.play(sprite)
	$AnimatedSprite2D.flip_h = velocity.x > 0.0 
	time_run += delta
	move_and_slide()
extends RigidBody2D

@export var min_speed = 175.0
@export var max_speed = 350.0

var anim_list = ["mob1", "mob2", "mob3", "mob4", "mob5"]


func play_random_anim():
	var random_index = randi() % anim_list.size()
	var anim_name = anim_list[random_index]
	$AnimatedSprite2D.play(anim_name)
	



func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
