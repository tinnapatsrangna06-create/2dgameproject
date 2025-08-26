extends Area2D

@export var auto_hint: bool = true        # โชว์ "E" เมื่อผู้เล่นเข้ามา
var _player_in: bool = false
var _picked: bool = false

@onready var spr: AnimatedSprite2D     = $AnimatedSprite2D
@onready var col: CollisionShape2D     = $CollisionShape2D
@onready var hint: Label               = $Label
@onready var sfx: AudioStreamPlayer2D  = $Sfx   # มีหรือไม่มีก็ได้

func _ready() -> void:
	monitoring = true
	if hint: hint.visible = false
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation("idle"):
		spr.play("idle")

func _process(_delta: float) -> void:
	if _player_in and !_picked and Input.is_action_just_pressed("Interact"):
		_pickup()

func _pickup() -> void:
	_picked = true
	monitoring = false
	if col: col.disabled = true
	if hint: hint.visible = false
	if sfx: sfx.play()

	# เล่นอนิเมชันเก็บถ้ามี
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation("pickup"):
		spr.play("pickup")
		await spr.animation_finished
	else:
		# fallback ย่อหาย
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(0.0, 0.0), 0.2)
		await t.finished

	# === แจ้ง Player ให้ปลดล็อกสกิล 3 (Pread) ===
	var p := get_tree().get_first_node_in_group("Player")
	if p and p.has_method("unlock_pread"):
		p.unlock_pread()

	queue_free()

# --------- Signals ---------
func _on_area_entered(area: Area2D) -> void:
	if _is_player(area):
		_player_in = true
		if auto_hint and hint:
			hint.text = "Press \"E\" to ???"
			hint.visible = true

func _on_area_exited(area: Area2D) -> void:
	if _is_player(area):
		_player_in = false
		if hint: hint.visible = false

# --------- Helper ---------
func _is_player(n: Node) -> bool:
	if n.is_in_group("Player"): 
		return true
	var p := n.get_parent()
	return p != null and p.is_in_group("Player")
