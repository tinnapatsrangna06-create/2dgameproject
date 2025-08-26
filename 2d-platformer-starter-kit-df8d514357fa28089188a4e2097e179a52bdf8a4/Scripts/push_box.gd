# res://Scripts/push_box.gd
extends RigidBody2D

@export var max_speed_x: float = 260.0   # เพดานความเร็วแนวนอน
@export var max_angular: float = 4.0     # จำกัดความเร็วเชิงมุม (กันหมุนเกิน)
@export var extra_ground_damp: float = 0.0  # เสริมหนืดเมื่อบนพื้น (ออปชัน)

func _ready() -> void:
	add_to_group("Pushable")
	# เผื่อไม่มี material
	if physics_material_override == null:
		var pm := PhysicsMaterial.new()
		pm.friction = 2.0
		pm.bounce = 0.0
		physics_material_override = pm

func _physics_process(_delta: float) -> void:
	# จำกัดความเร็วแกน X ไม่ให้พุ่งเกินไป
	if abs(linear_velocity.x) > max_speed_x:
		linear_velocity.x = sign(linear_velocity.x) * max_speed_x

	# จำกัดความเร็วการหมุน (กันคว่ำเร็วๆ)
	if abs(angular_velocity) > max_angular:
		angular_velocity = sign(angular_velocity) * max_angular
