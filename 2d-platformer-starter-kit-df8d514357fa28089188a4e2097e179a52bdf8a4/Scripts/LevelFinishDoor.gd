extends Area2D

@export var next_scene: PackedScene

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
var players_inside: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	_play_default()

# ========== SIGNALS ==========
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"): 
		return
	players_inside += 1
	if is_transitioning:
		return

	is_transitioning = true

	# เล่น crack ถ้ามี แล้วรอให้จบ
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation("crack"):
		spr.play("crack")
		await spr.animation_finished



	# เปลี่ยนด่าน
	if next_scene:
		await get_tree().create_timer(0.01).timeout
		# ถ้าใช้ SceneTransition ของคุณ
		SceneTransition.load_scene(next_scene)
		# หรือถ้าอยากเปลี่ยนตรง ๆ:
		# get_tree().change_scene_to_packed(next_scene)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	players_inside = max(players_inside - 1, 0)

	# ถ้าไม่มีผู้เล่นค้างในคอลลิชัน กลับไปเล่น default
	if players_inside == 0 and !is_transitioning:
		_play_default()

# ========== HELPERS ==========
func _play_default() -> void:
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation("default"):
		spr.play("default")

#extends Area2D
#
## Define the next scene to load in the inspector
#@export var next_scene : PackedScene
#
## Load next level scene when player collide with level finish door.
#func _on_body_entered(body):
	#if body.is_in_group("Player"):
		#get_tree().call_group("Player", "death_tween") # death_tween is called here just to give the feeling of player entering the door.
		#AudioManager.level_complete_sfx.play()
		#SceneTransition.load_scene(next_scene)
