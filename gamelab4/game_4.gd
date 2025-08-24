extends CharacterBody2D

@export var speed = 40
@export var gravity : float = 30
@export var sprite : String = "slime1"  # สามารถตั้งชื่อเป็น slime1, slime2, slime3 ได้
var time_run = 0
var spawn_point 
var alive = true

@onready var explosion: GPUParticles2D = $explosion

func _ready() -> void:
	$AnimatedSprite2D.play(sprite)
	velocity.x = speed if randf() < 0.5 else -speed
	spawn_point = position
	
func _process(delta: float) -> void:		
	if !visible : return

	if !is_on_floor():
		velocity.y += gravity

	if time_run > 1 and is_on_wall():
		velocity.x = -velocity.x
		time_run = 0

	if !$AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != sprite:
		$AnimatedSprite2D.play(sprite)

	$AnimatedSprite2D.flip_h = velocity.x > 0.0 
	time_run += delta

	move_and_slide()

func _on_hit_area_body_entered(body: Node2D) -> void:
	if alive:
		death_tween()

func death_tween():
	alive = false
	$AnimatedSprite2D.visible = false
	hide()

func respawn_tween():
	position = spawn_point
	$AnimatedSprite2D.visible = true
	show()
	alive = true
	scale = Vector2.ZERO

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2) 
	await tween.finished

	$AnimatedSprite2D.play(sprite)
	velocity.x = speed if randf() < 0.5 else -speed
	velocity.y = -200
