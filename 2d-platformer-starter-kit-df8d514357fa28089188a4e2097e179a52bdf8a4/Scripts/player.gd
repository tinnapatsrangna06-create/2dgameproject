extends CharacterBody2D

@export_category("Player Properties")
@export var move_speed : float = 270
@export var base_gravity : float = 1600.0
@export var fall_multiplier : float = 1.8
@export var max_fall_speed : float = 2400.0
@onready var invis_sfx: AudioStreamPlayer2D = $InvisSfx

# --- Invisibility ---
@export var invis_duration: float = 5
var is_invis: bool = false
var _invis_timer: SceneTreeTimer
var invis_end_time: float = -1.0

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

@onready var invis_label: Label       = get_node_or_null("%InvisLabel")
@onready var invis_text: Label        = get_node_or_null("%invis")
@onready var invis_frame: CanvasItem  = get_node_or_null("%กรอบ")
@onready var invis_icon: CanvasItem   = get_node_or_null("%3656384-201")

# --- Kuman (ร่าง 1 บล็อก) ---
@export var kuman_toggle_in_air := false
var has_kuman: bool = false
var is_kuman_form: bool = false

# --- Krahang (Skill2) ---
const TILE_PX := 80
@export var has_krahang: bool = false
var is_krahang_active: bool = false
@export var kh_rise_px: float = TILE_PX
@export var kh_forward_px: float = TILE_PX+100
@export var kh_rise_time: float = 0.2
@export var kh_move_time: float = 0.5
@export var kh_fall_time: float = 0.2

# --- Pread (Skill3) ---
@export var has_pread: bool = false
var is_pread_active: bool = false
@export var pread_up_px: float = TILE_PX * 4
@export var pread_up_time: float = 0.35
@export var pread_over_px: float = TILE_PX
@export var pread_over_time: float = 0.20

# คอลลิเดอร์หลัก
@onready var body_tall: CollisionShape2D  = $CollisionShape2D
@onready var body_small: CollisionShape2D = $"CollisionShape2D_kuman"

# --- Push settings ---
@export var push_force: float = 1400.0
@export var push_max_speed: float = 120.0
@export var require_on_floor: bool = true

# --- Buffalo (Skill4: push boxes) ---
@export var has_buffalo: bool = false
var is_buffalo_form: bool = false
@onready var body_buffalo: CollisionShape2D = $"CollisionShape2D_buffalo"

func _try_push_boxes(delta: float) -> void:
	if !is_buffalo_form:
		return
	var dir_input: int = int(sign(Input.get_axis("Left", "Right")))
	if dir_input == 0:
		return
	if require_on_floor and !is_on_floor():
		return
	for i in range(get_slide_collision_count()):
		var c: KinematicCollision2D = get_slide_collision(i)
		if c == null: continue
		if abs(c.get_normal().x) < 0.8: continue
		var rb := c.get_collider() as RigidBody2D
		if rb and rb.is_in_group("Pushable"):
			var wall_dir: int = int(sign(-c.get_normal().x))
			if wall_dir == dir_input:
				var v: Vector2 = rb.linear_velocity
				v.x = clamp(v.x + push_force * dir_input * delta, -push_max_speed, push_max_speed)
				rb.linear_velocity = v

func _ready() -> void:
	floor_snap_length = 0
	player_sprite.animation_finished.connect(_on_anim_finished)
	add_to_group("Player")
	_toggle_invis_ui(false)
	if body_tall:    body_tall.disabled    = false
	if body_small:   body_small.disabled   = true
	if body_buffalo: body_buffalo.disabled = true

func _physics_process(delta: float) -> void:
	if is_krahang_active or is_pread_active:
		return

	# --------- PHYSICS --------- #
	var g := base_gravity
	if velocity.y > 0.0: g *= fall_multiplier
	velocity.y += g * delta
	velocity.y = clamp(velocity.y, -INF, max_fall_speed)
	floor_snap_length = 6 if velocity.y > 0.0 else 0

	var inputAxis := Input.get_axis("Left", "Right")
	velocity.x = inputAxis * move_speed

	move_and_slide()
	_try_push_boxes(delta)

	# --------- INPUT --------- #
	handle_invis_input()
	handle_skill_input()      # Skill1: Kuman
	handle_buffalo_input()    # Skill4: Buffalo
	handle_krahang_input()    # Skill2
	handle_pread_input()      # Skill3

	# --------- UI invis countdown --------- #
	if is_invis and invis_end_time > 0.0:
		var now_s: float = Time.get_ticks_msec() / 1000.0
		var sec_left: float = max(0.0, invis_end_time - now_s)
		if invis_label: invis_label.text = str(int(ceil(sec_left)))
		_toggle_invis_ui(true)
	else:
		_toggle_invis_ui(false)

	player_animations()
	flip_player()

func unlock_buffalo() -> void:
	has_buffalo = true

func _set_buffalo_form(enable: bool) -> void:
	if !enable:
		var headroom := 16.0
		if test_move(global_transform, Vector2(0, -headroom)):
			return
	is_buffalo_form = enable
	is_kuman_form = false
	if body_tall:    body_tall.set_deferred("disabled", enable)
	if body_small:   body_small.set_deferred("disabled", true)
	if body_buffalo: body_buffalo.set_deferred("disabled", not enable)
	move_speed = 150 if enable else 270
	if is_on_floor():
		floor_snap_length = 12
		set_deferred("position", position + Vector2(0, 1))
		velocity.y = max(velocity.y, 0.0)

func handle_buffalo_input() -> void:
	if !has_buffalo: return
	if Input.is_action_just_pressed("Skill4"):
		if !is_on_floor(): return
		_set_buffalo_form(!is_buffalo_form)

# ================== INVIS ==================
func handle_invis_input():
	if is_kuman_form or is_pread_active or is_buffalo_form:
		return
	if Input.is_action_just_pressed("Invis") and !is_invis and player_sprite.animation != "Pre_Invisible":
		_start_invis()

func _start_invis():
	if is_kuman_form: return
	is_invis = true
	player_sprite.speed_scale = 1.0
	player_sprite.play("Pre_Invisible")
	if invis_sfx: invis_sfx.play()
	invis_end_time = Time.get_ticks_msec() / 1000.0 + float(invis_duration)
	_invis_timer = get_tree().create_timer(float(invis_duration))
	_invis_timer.timeout.connect(_end_invis)

func _end_invis() -> void:
	var frames := player_sprite.sprite_frames.get_frame_count("Pre_Invisible")
	player_sprite.animation = "Pre_Invisible"
	player_sprite.speed_scale = -1.0
	player_sprite.frame = max(0, frames - 1)
	player_sprite.play()
	await player_sprite.animation_finished
	player_sprite.speed_scale = 1.0
	is_invis = false
	invis_end_time = -1.0
	_toggle_invis_ui(false)

func _toggle_invis_ui(show: bool) -> void:
	if invis_label: invis_label.visible = show
	if invis_text:  invis_text.visible  = show
	if invis_frame: invis_frame.visible = show
	if invis_icon:  invis_icon.visible  = show

# ===== Skill3: Pread =====
func unlock_pread() -> void:
	has_pread = true

func handle_pread_input() -> void:
	if !has_pread or is_pread_active or is_invis or is_kuman_form:
		return
	if Input.is_action_just_pressed("Skill3"):
		if _has_wall_in_front(pread_up_px):
			_do_pread_climb()
		else:
			return

func _front_dir() -> float:
	return -1.0 if player_sprite.flip_h else 1.0

func _has_wall_in_front(height_px: float) -> bool:
	var dir := _front_dir()
	var xf := global_transform
	for y in range(0, int(height_px) + 1, 8):
		xf.origin = global_position + Vector2(0, -float(y))
		if test_move(xf, Vector2(dir * 8.0, 0)):
			return true
	return false

func _space_free_at(pos: Vector2) -> bool:
	var xf := global_transform
	xf.origin = pos
	return !test_move(xf, Vector2.ZERO)

func _ground_below(pos: Vector2) -> bool:
	var xf := global_transform
	xf.origin = pos
	return test_move(xf, Vector2(0, 4))

func _do_pread_climb() -> void:
	is_pread_active = true
	velocity = Vector2.ZERO
	var dir := _front_dir()
	var start_pos := global_position
	_apply_pread_visual_fix(true)
	var rise := _sweep_dist(Vector2(0, -pread_up_px))
	if rise <= 0.0:
		_apply_pread_visual_fix(false)
		is_pread_active = false
		return
	var top_pos := start_pos + Vector2(0, -rise)
	var want_forward_pos := top_pos + Vector2(dir * pread_over_px, 0)
	var can_forward := _space_free_at(want_forward_pos) and _ground_below(want_forward_pos + Vector2(0, 1))
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("P_Climb"):
		player_sprite.play("P_Climb")
		await player_sprite.animation_finished
	global_position = want_forward_pos if can_forward else top_pos
	_apply_pread_visual_fix(false)
	floor_snap_length = 12
	set_deferred("position", position + Vector2(0, 1))
	player_sprite.play("Idle")
	is_pread_active = false

const PREAD_SCALE := 1
const PREAD_EXTRA_OFFSET_Y := 0.0
var _pread_orig_scale : Vector2
var _pread_orig_offset: Vector2
var _pread_orig_centered: bool

func _apply_pread_visual_fix(enable: bool) -> void:
	if enable:
		_pread_orig_scale    = player_sprite.scale
		_pread_orig_offset   = player_sprite.offset
		_pread_orig_centered = player_sprite.centered
		player_sprite.centered = true
		player_sprite.scale = _pread_orig_scale * PREAD_SCALE
		var frames := player_sprite.sprite_frames
		if frames and frames.has_animation("Idle") and frames.has_animation("P_Climb"):
			var idle_tex  := frames.get_frame_texture("Idle", 0)
			var climb_tex := frames.get_frame_texture("P_Climb", 0)
			if idle_tex and climb_tex:
				var idle_h  := float(idle_tex.get_height())
				var climb_h := float(climb_tex.get_height()) * PREAD_SCALE
				var delta_h := climb_h - idle_h
				var offset_y := -0.5 * delta_h + PREAD_EXTRA_OFFSET_Y
				player_sprite.offset = _pread_orig_offset + Vector2(0.0, offset_y)
	else:
		player_sprite.scale    = _pread_orig_scale
		player_sprite.offset   = _pread_orig_offset
		player_sprite.centered = _pread_orig_centered

# ===== Skill2: Krahang =====
func unlock_krahang() -> void:
	has_krahang = true

func handle_krahang_input() -> void:
	if !has_krahang or is_krahang_active or is_invis or is_kuman_form or is_buffalo_form:
		return
	if Input.is_action_just_pressed("Skill2"):
		_do_krahang()

func _sweep_dist(motion: Vector2, step: float = 2.0) -> float:
	var total: float = motion.length()
	if total <= 0.0: return 0.0
	var dir: Vector2 = motion / total
	var traveled: float = 0.0
	while traveled < total:
		var next: float = min(step, total - traveled)
		if test_move(global_transform, dir * (traveled + next)):
			break
		traveled += next
	return traveled

func _do_krahang() -> void:
	is_krahang_active = true
	velocity = Vector2.ZERO
	var dir := -1.0 if player_sprite.flip_h else 1.0
	var start_pos := global_position
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("KH_Start"):
		player_sprite.play("KH_Start")
		await player_sprite.animation_finished
	var rise := _sweep_dist(Vector2(0, -kh_rise_px))
	var t := create_tween()
	t.tween_property(self, "global_position", start_pos + Vector2(0, -rise), kh_rise_time)
	await t.finished
	if player_sprite.sprite_frames:
		if player_sprite.sprite_frames.has_animation("KH_Idle"):
			player_sprite.play("KH_Idle")
		elif player_sprite.sprite_frames.has_animation("KH_Glide"):
			player_sprite.play("KH_Glide")
	var mid_pos := global_position
	var forward := _sweep_dist(Vector2(kh_forward_px * dir, 0))
	t = create_tween()
	t.tween_property(self, "global_position", mid_pos + Vector2(forward * dir, 0), kh_move_time)
	await t.finished
	var end_pos := global_position
	var fall := _sweep_dist(Vector2(0, kh_rise_px))
	t = create_tween()
	t.tween_property(self, "global_position", end_pos + Vector2(0, fall), kh_fall_time)
	await t.finished
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("KH_End"):
		player_sprite.play("KH_End")
	else:
		player_sprite.play("Idle")
	floor_snap_length = 12
	set_deferred("position", position + Vector2(0, 1))
	velocity = Vector2.ZERO
	is_krahang_active = false

# ================== KUMAN (form 1 block) ==================
func unlock_kuman() -> void:
	has_kuman = true

func handle_skill_input() -> void:
	if Input.is_action_just_pressed("Skill1") and has_kuman:
		if !kuman_toggle_in_air and !is_on_floor():
			return
		_set_kuman_form(!is_kuman_form)

func _set_kuman_form(enable: bool) -> void:
	if enable and body_small == null:
		push_warning("No CollisionShape2D_kuman found. Abort transform.")
		return
	if !enable:
		var headroom := 16.0
		if test_move(global_transform, Vector2(0, -headroom)):
			return
	is_kuman_form = enable
	if body_small: body_small.set_deferred("disabled", not enable)
	if body_tall:  body_tall.set_deferred("disabled", enable)
	if is_on_floor():
		floor_snap_length = 12
		set_deferred("position", position + Vector2(0, 1))
		velocity.y = max(velocity.y, 0.0)
	move_speed = 130 if enable else 270

# ================== ANIM / FX ==================
func _on_anim_finished() -> void:
	if is_invis and player_sprite.animation == "Pre_Invisible" and player_sprite.speed_scale >= 0.0:
		if abs(velocity.x) > 0.0:
			player_sprite.play("Invisible", 1.5)
		else:
			player_sprite.play("Idle_Invis")

func player_animations():
	if is_krahang_active or is_pread_active:
		return
	particle_trails.emitting = false
	if player_sprite.animation == "Pre_Invisible" and player_sprite.is_playing():
		return
	if is_invis:
		if abs(velocity.x) > 0:
			player_sprite.play("Invisible", 1.5)
		else:
			player_sprite.play("Idle_Invis")
		return
	if is_buffalo_form:
		var walk_name := "buffalo_walk"
		var idle_name := "buffalo_Idle"
		if !player_sprite.sprite_frames.has_animation(walk_name) and player_sprite.sprite_frames.has_animation("buffalo_Walk"):
			walk_name = "buffalo_Walk"
		if !player_sprite.sprite_frames.has_animation(idle_name) and player_sprite.sprite_frames.has_animation("buffalo_idle"):
			idle_name = "buffalo_idle"
		if is_on_floor():
			if abs(velocity.x) > 0:
				player_sprite.play(walk_name, 1.2)
			else:
				player_sprite.play(idle_name)
		else:
			player_sprite.play(idle_name)
		return
	if is_kuman_form:
		if !is_on_floor():
			if player_sprite.sprite_frames.has_animation("K_Fall"):
				player_sprite.play("K_Fall")
			else:
				player_sprite.play("K_Idle")
		else:
			if abs(velocity.x) > 0:
				if player_sprite.sprite_frames.has_animation("K_Walk"):
					player_sprite.play("K_Walk", 1.5)
				else:
					player_sprite.play("K_Idle")
			else:
				player_sprite.play("K_Idle")
	else:
		if !is_on_floor():
			if player_sprite.sprite_frames.has_animation("Fall"):
				player_sprite.play("Fall")
			else:
				player_sprite.play("Idle")
		else:
			if abs(velocity.x) > 0:
				particle_trails.emitting = false
				player_sprite.play("Walk", 1.5)
			else:
				player_sprite.play("Idle")

func flip_player():
	if velocity.x < 0:
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

# ================== TWEENS / DEATH ==================
func death_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	AudioManager.respawn_sfx.play()
	get_tree().reload_current_scene()

func respawn_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

# ====== เรียกเมื่อตัวผู้เล่นถูกฆ่า ======
func die() -> void:
	if is_invis:    # ล่องหนอยู่: ไม่ตาย
		return
	AudioManager.death_sfx.play()
	death_particles.emitting = true
	death_tween()

func start_fall() -> void:
	die()

# ================== SIGNALS ==================
# เชื่อมสัญญาณ body_entered จาก Area2D/CollisionArea ของ Player มาที่ฟังก์ชันนี้
func _on_collision_body_entered(body):
	# ล่องหน: ชน "มอนสเตอร์" → ฆ่ามอนแล้วจบ
	if is_invis:
		if body and body.is_in_group("Monsters"):
			body.queue_free()
		return

	# ปกติ: ชนกับดักหรือมอน → ผู้เล่นตาย
	if body and (body.is_in_group("Traps") or body.is_in_group("Monsters")):
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		death_tween()
