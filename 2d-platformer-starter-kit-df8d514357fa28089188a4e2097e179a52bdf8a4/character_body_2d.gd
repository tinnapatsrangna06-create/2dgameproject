extends CharacterBody2D

@export var speed: int = 100            # ความเร็ว
@export var move_distance: int = 200    # ระยะที่เดินจากจุดเริ่ม (ซ้าย/ขวา)
@export var debug_log: bool = false

var start_position: Vector2
var direction: int = 1  # 1 = ขวา, -1 = ซ้าย

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# ให้มี Area2D ลูกชื่อ "DetectArea" แล้วต่อสัญญาณ area_entered -> _on_detect_area_entered

func _ready() -> void:
	start_position = global_position
	anim.flip_h = false
	if anim.sprite_frames and anim.sprite_frames.has_animation("walk"):
		anim.play("walk")
	if has_node("DetectArea"):
		$DetectArea.area_entered.connect(_on_detect_area_entered)
	add_to_group("Monsters")

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed
	move_and_slide()

	var dx := global_position.x - start_position.x
	if abs(dx) > move_distance:
		global_position.x = start_position.x + sign(dx) * move_distance
		direction *= -1

	anim.flip_h = direction < 0
	if abs(velocity.x) > 0.1 and anim.sprite_frames and anim.sprite_frames.has_animation("walk"):
		if anim.animation != "walk":
			anim.play("walk")

# ---------- ตรวจจับผู้เล่นในเขตอันตราย ---------- #
func _on_detect_area_entered(area: Area2D) -> void:
	# สนใจเฉพาะ Player (ให้ทั้ง Player และ Hurtbox/Area ของ Player อยู่ในกลุ่ม "Player")
	if not area.is_in_group("Player"):
		return

	# อ่านสถานะล่องหนจาก node เองก่อน ถ้าไม่เจอให้ดูที่ parent
	var invis := false
	if "is_invis" in area:
		invis = area.get("is_invis")
	elif area.get_parent() and "is_invis" in area.get_parent():
		invis = area.get_parent().get("is_invis")

	# ถ้าผู้เล่นล่องหน: มอนตายทันที (ไม่มีอนิเมชัน)
	if invis:
		if debug_log: print("[monster] player invisible -> monster removed")
		queue_free()
		return

	# ผู้เล่นไม่ล่องหน → พยายามฆ่าผู้เล่นตามปกติ
	if area.has_method("die"):
		area.die()
	elif area.has_method("start_fall"):
		area.start_fall()
	elif area.get_parent() and area.get_parent().has_method("die"):
		area.get_parent().die()
	else:
		if debug_log: print("[monster] no die/start_fall on player")
