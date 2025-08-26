extends Node2D

@export var fall_speed: float = 1600.0
@export var delay_before_fall: float = 0.3
@export var debug_log: bool = false

var is_falling: bool = false
var _start_pos: Vector2

@onready var hitbox: Area2D      = $Hitbox
@onready var detect_area: Area2D = $DetectArea

func _ready() -> void:
	_start_pos = position
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	detect_area.body_entered.connect(_on_detect_body_entered)
	detect_area.area_entered.connect(_on_detect_area_entered)

func _physics_process(delta: float) -> void:
	if is_falling:
		position.y += fall_speed * delta

# ---------- ตรวจเจอผู้เล่น ----------
func _on_detect_body_entered(body: Node) -> void:
	if _is_player(body):
		# แทน has_variable → ใช้ get()
		var invis = body.get("is_invis")
		if invis == true:
			if debug_log: print("[trap] player is invisible -> ignore")
			return
		_start_fall()

func _on_detect_area_entered(area: Area2D) -> void:
	if _is_player(area):
		var invis = area.get("is_invis")
		if invis == true:
			if debug_log: print("[trap] player is invisible -> ignore")
			return
		_start_fall()

# ---------- ชนผู้เล่นแล้วฆ่า ----------
func _on_hitbox_body_entered(body: Node) -> void:
	if _is_player(body):
		if debug_log: print("[trap] kill player")
		body.call_deferred("death_tween")

func _on_hitbox_area_entered(area: Area2D) -> void:
	if _is_player(area):
		if debug_log: print("[trap] kill player")
		area.call_deferred("death_tween")

# ---------- เริ่มตก ----------
func _start_fall() -> void:
	if is_falling: return
	await get_tree().create_timer(delay_before_fall).timeout
	is_falling = true
	if debug_log: print("[trap] start falling")

# ---------- Helper ----------
func _is_player(n: Node) -> bool:
	return n.is_in_group("Player") or n.has_method("death_tween")
