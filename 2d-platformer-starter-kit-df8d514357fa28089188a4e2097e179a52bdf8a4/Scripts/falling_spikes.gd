extends Node2D

@export var speed: float = 160.0
var current_speed: float = 0.0

@export var shake_time: float = 0.35   # ระยะเวลาเขย่าก่อนตก
@export var shake_amp: float = 4.0     # ระยะสั่นซ้าย-ขวา (พิกเซล)
@export var debug_log: bool = true

@onready var anim: AnimationPlayer = $AnimationPlayer   # มีหรือไม่มีก็ได้
var _orig_pos: Vector2

func _ready() -> void:
	_orig_pos = position

func _physics_process(delta: float) -> void:
	# ตกลงตามความเร็ว (ถ้ายังไม่ถูกสั่งตก current_speed จะเป็น 0)
	position.y += current_speed * delta

# ================== SIGNALS (ชนหนาม) ==================
func _on_hitbox_area_entered(area: Area2D) -> void:
	var p := _find_player(area)
	if p:
		if debug_log: print("[spike] hit (area) -> kill")
		p.call_deferred("die")
		queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	var p := _find_player(body)
	if p:
		if debug_log: print("[spike] hit (body) -> kill")
		p.call_deferred("die")
		queue_free()

# ====== SIGNALS (ตรวจพบผู้เล่น -> เขย่าแล้วตก) ======
func _on_player_detect_area_entered(area: Area2D) -> void:
	if _find_player(area):
		if debug_log: print("[spike] detect (area) -> shake & fall")
		_shake_then_fall()

func _on_player_detect_body_entered(body: Node) -> void:
	if _find_player(body):
		if debug_log: print("[spike] detect (body) -> shake & fall")
		_shake_then_fall()
 
# ================== BEHAVIOR ==================
func _shake_then_fall() -> void:
	# กันเรียกซ้ำ
	if current_speed != 0.0: return

	# ถ้ามี AnimationPlayer ที่ชื่อ "shake" จะเล่นด้วย (เสริม)
	if anim and anim.has_animation("shake"):
		anim.play("shake")

	# ทำทวีนเขย่าแบบสคริปต์ (ไม่ต้องพึ่ง AnimationPlayer)
	var t := create_tween().set_parallel(false)
	var cycles := 6
	var seg := shake_time / float(cycles)
	for i in cycles:
		t.tween_property(self, "position:x", _orig_pos.x + shake_amp, seg * 0.5)
		t.tween_property(self, "position:x", _orig_pos.x - shake_amp, seg * 0.5)
	t.tween_property(self, "position:x", _orig_pos.x, 0.05)
	await t.finished

	fall()  # สั่งตกจริง

func fall() -> void:
	if current_speed != 0.0: return
	current_speed = speed
	if debug_log: print("[spike] start falling, speed=", speed)
	await get_tree().create_timer(5.0).timeout
	queue_free()

# ================== HELPERS ==================
func _find_player(n: Node) -> Node:
	var cur := n
	while cur:
		if cur.is_in_group("Player"):   # แนะนำให้ใส่กลุ่ม Player ที่โหนดรากผู้เล่น
			return cur
		if cur.has_method("die"):       # กันพลาด ถ้ามีเมธอด die() ก็ถือว่าใช่
			return cur
		cur = cur.get_parent()
	return null
