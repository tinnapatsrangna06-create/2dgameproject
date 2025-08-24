extends CharacterBody2D

@export var speed: int = 100            # ความเร็ว
@export var move_distance: int = 200    # ระยะที่เดินจากจุดเริ่มได้ (ซ้าย/ขวา)

var start_position: Vector2
var direction: int = 1  # 1 = ขวา, -1 = ซ้าย

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	start_position = global_position
	# ตั้งค่าเริ่มต้นให้หันขวา และเล่นอนิเมชัน "walk"
	anim.flip_h = false
	if anim.sprite_frames and anim.sprite_frames.has_animation("walk"):
		anim.play("walk")

func _physics_process(delta: float) -> void:
	# เคลื่อนที่ตามทิศ
	velocity.x = direction * speed
	move_and_slide()

	# ถ้าเดินเกินระยะที่กำหนดให้กลับทิศ และดันตำแหน่งกลับเข้าขอบเล็กน้อยกันสั่น
	var dx := global_position.x - start_position.x
	if abs(dx) > move_distance:
		# ล็อกให้ไม่เลยขอบ


		# กลับทิศ
		direction *= -1

	# พลิกสปрайต์ให้หันตามทิศ (ถ้าไฟล์ต้นฉบับหันขวา ให้ใช้เงื่อนไขนี้ได้เลย)
	anim.flip_h = direction < 0

	# เล่นแอนิเมชัน (กรณีมีหลายชุด เช่น walk/idle)
	if abs(velocity.x) > 0.1:
		if anim.sprite_frames and anim.sprite_frames.has_animation("walk"):
			if anim.animation != "walk":
				anim.play("walk")
