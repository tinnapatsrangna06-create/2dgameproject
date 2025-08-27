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
@export var kuman_toggle_in_air := false  # อนุญาตสลับกลางอากาศไหม
var has_kuman: bool = false               # ได้ไอเท็มแล้วหรือยัง
var is_kuman_form: bool = false           # ตอนนี้อยู่ร่าง 1 บล็อกไหม

# --- Krahang (Skill2: rise 1 block, fly 3 tiles, drop 1 block) ---
const TILE_PX := 80
@export var has_krahang: bool = false          # ปลดล็อกจากไอเท็ม
var is_krahang_active: bool = false            # กำลังใช้สกิลอยู่ไหม

# ปรับระยะ/เวลาได้ตามชอบ
@export var kh_rise_px: float = TILE_PX        # ยกขึ้น 1 บล็อก
@export var kh_forward_px: float = TILE_PX # พุ่งไป 3 ช่อง
@export var kh_rise_time: float = 0.2
@export var kh_move_time: float = 0.5
@export var kh_fall_time: float = 0.2

# --- Pread (Skill3: climb 4 tiles up the cliff in front) ---
@export var has_pread: bool = false          # ปลดล็อกจากไอเท็ม
var is_pread_active: bool = false

@export var pread_up_px: float = TILE_PX * 4 # ปีนขึ้น 4 บล็อก
@export var pread_up_time: float = 0.35
@export var pread_over_px: float = TILE_PX   # ข้ามขอบผาไป 1 บล็อก
@export var pread_over_time: float = 0.20

# คอลลิเดอร์หลักสองขนาด (ตามโหนดที่คุณมี)
@onready var body_tall: CollisionShape2D  = $CollisionShape2D                 # ร่างสูง 2 บล็อก
@onready var body_small: CollisionShape2D = $"CollisionShape2D_kuman"
# --- Push settings ---
@export var push_force: float = 1400.0      # แรงผลักต่อเฟรมฟิสิกส์
@export var push_max_speed: float = 120.0   # เพดานความเร็วกล่องตอนผลัก
@export var require_on_floor: bool = true   # ต้องเหยียบพื้นถึงผลักได้
#
#func _try_push_boxes(delta: float) -> void:
	## ต้องมีแรงกดปุ่มซ้าย/ขวา และ (ถ้าตั้ง) ผู้เล่นเหยียบพื้น
	#var dir_input: int = int(sign(Input.get_axis("Left"dd, "Right")))
	#if dir_input == 0:
		#return
	#if require_on_floor and !is_on_floor():
		#return
#
	## ตรวจการชนจาก move_and_slide() ของเฟรมนี้
	#for i in range(get_slide_collision_count()):
		#var c: KinematicCollision2D = get_slide_collision(i)
		#if c == null:
			#continue
		## ชนด้านข้าง? (normal ประมาณซ้าย/ขวา)
		#if abs(c.get_normal().x) < 0.8:
			#continue
#
		#var rb := c.get_collider() as RigidBody2D
		#if rb and rb.is_in_group("Pushable"):
			## ทิศกำแพง/กล่อง (ตรงกับทิศที่ผู้เล่นกดหรือไม่)
			#var wall_dir: int = int(sign(-c.get_normal().x))
			#var same_side: bool = wall_dir == dir_input
			#if same_side:
				#var v: Vector2 = rb.linear_velocity
				#v.x = clamp(
					#v.x + push_force * dir_input * delta,
					#-push_max_speed, push_max_speed
				#)
				#rb.linear_velocity = v
				
func _try_push_boxes(delta: float) -> void:
	# ดันได้เฉพาะตอนเป็นควาย
	if !is_buffalo_form:
		return

	var dir_input: int = int(sign(Input.get_axis("Left", "Right")))
	if dir_input == 0:
		return
	if require_on_floor and !is_on_floor():
		return

	for i in range(get_slide_collision_count()):
		var c: KinematicCollision2D = get_slide_collision(i)
		if c == null:
			continue
		if abs(c.get_normal().x) < 0.8:
			continue

		var rb := c.get_collider() as RigidBody2D
		if rb and rb.is_in_group("Pushable"):
			var wall_dir: int = int(sign(-c.get_normal().x))
			if wall_dir == dir_input:
				var v: Vector2 = rb.linear_velocity
				v.x = clamp(
					v.x + push_force * dir_input * delta,
					-push_max_speed, push_max_speed
				)
				rb.linear_velocity = v


func _ready() -> void:
	floor_snap_length = 0
	player_sprite.animation_finished.connect(_on_anim_finished)
	add_to_group("Player")
	_toggle_invis_ui(false)

	# ให้แน่ใจว่าตอนเริ่มใช้ตัวชน "ร่างสูง"
	if body_tall:  body_tall.disabled  = false
	if body_small: body_small.disabled = true
	if body_buffalo: body_buffalo.disabled = true
		
func _physics_process(delta: float) -> void:
	if is_krahang_active or is_pread_active:
		return

	# --------- PHYSICS --------- #
	var g := base_gravity
	if velocity.y > 0.0:
		g *= fall_multiplier
	velocity.y += g * delta
	velocity.y = clamp(velocity.y, -INF, max_fall_speed)

	floor_snap_length = 6 if velocity.y > 0.0 else 0

	var inputAxis := Input.get_axis("Left", "Right")
	velocity.x = inputAxis * move_speed

	# อัปเดตการชนของเฟรมนี้
	move_and_slide()
	# ใช้ข้อมูลชนผลักกล่อง
	_try_push_boxes(delta)

	# --------- INPUT อื่น ๆ --------- #
	handle_invis_input()
	handle_skill_input()
	handle_buffalo_input()    # ← Skill4 ควาย (ใหม่)
	handle_krahang_input()
	handle_pread_input()

	# --------- UI/ANIM --------- #
	# ... (ส่วน UI/อนิเมของคุณเหมือนเดิม) ...


	# --------- UI: นับถอยหลังล่องหน --------- #
	if is_invis and invis_end_time > 0.0:
		var now_s: float = Time.get_ticks_msec() / 1000.0
		var sec_left: float = max(0.0, invis_end_time - now_s)
		if invis_label: invis_label.text = str(int(ceil(sec_left)))
		_toggle_invis_ui(true)
	else:
		_toggle_invis_ui(false)

	player_animations()
	flip_player()
	
# --- Buffalo (Skill4: form that can push boxes) ---
@export var has_buffalo: bool = false
var is_buffalo_form: bool = false
@onready var body_buffalo: CollisionShape2D = $"CollisionShape2D_buffalo"

func unlock_buffalo() -> void:
	has_buffalo = true

# สลับไป/กลับร่างควาย
func _set_buffalo_form(enable: bool) -> void:
	# ถ้าจะขยายกลับเป็นร่างสูง ให้เช็ค headroom กันหัวชนเพดาน
	if !enable: # กลับร่างคนสูง
		var headroom := 16.0
		if test_move(global_transform, Vector2(0, -headroom)):
			return

	is_buffalo_form = enable
	is_kuman_form = false  # ปิดร่างอื่นทันที (ร่างควาย exclusive)

	# คุม Collider แบบ deferred
	if body_tall:
		body_tall.set_deferred("disabled", enable) # เปิดร่างสูงเฉพาะตอนไม่ใช่ควาย
	if body_small:
		body_small.set_deferred("disabled", true)  # ร่างกุมานปิด
	if body_buffalo:
		body_buffalo.set_deferred("disabled", not enable)

	# ปรับสเตตัสตามร่าง
	if enable:
		move_speed = 150        # ร่างควายช้าลงนิด (ปรับได้)
	else:
		move_speed = 270        # ค่าปกติของคุณ

	# ช่วยยึดติดพื้น
	if is_on_floor():
		floor_snap_length = 12
		set_deferred("position", position + Vector2(0, 1))
		velocity.y = max(velocity.y, 0.0)

func handle_buffalo_input() -> void:
	if !has_buffalo:
		return
	# อนุญาตสลับเฉพาะตอน 'อยู่พื้น' แบบเดียวกับ Skill1
	if Input.is_action_just_pressed("Skill4"):
		if !is_on_floor():
			return
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

# ===== ปลดล็อกจากไอเท็ม =====
func unlock_pread() -> void:
	has_pread = true

# ===== ตรวจปุ่ม "3" =====
func handle_pread_input() -> void:
	if !has_pread or is_pread_active or is_invis or is_kuman_form:
		return
	if Input.is_action_just_pressed("Skill3"):
		# ✅ ใช้ได้ก็ต่อเมื่อ "ด้านหน้ามีกำแพง" สูงอย่างน้อยเท่าที่จะปีน (4 บล็อก)
		if _has_wall_in_front(pread_up_px):
			_do_pread_climb()
		else:
			# ไม่มีผนังขวางด้านหน้า -> ไม่ให้ใช้สกิล
			return

# ---------- PREAD HELPERS ----------
func _front_dir() -> float:
	return -1.0 if player_sprite.flip_h else 1.0

func _has_wall_in_front(height_px: float) -> bool:
	var dir := _front_dir()
	var xf := global_transform
	for y in range(0, int(height_px) + 1, 8):
		xf.origin = global_position + Vector2(0, -float(y))
		# ถ้าดันไปข้างหน้าแล้ว test_move() = true แปลว่าชน -> มีกำแพง
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

	# เปิดชดเชยภาพตอนปีน
	_apply_pread_visual_fix(true)

	# คำนวณตำแหน่งปลายทาง
	var rise := _sweep_dist(Vector2(0, -pread_up_px))
	if rise <= 0.0:
		_apply_pread_visual_fix(false)
		is_pread_active = false
		return
	var top_pos := start_pos + Vector2(0, -rise)
	var want_forward_pos := top_pos + Vector2(dir * pread_over_px, 0)
	var can_forward := _space_free_at(want_forward_pos) and _ground_below(want_forward_pos + Vector2(0, 1))

	# เล่นแอนิเมชั่นก่อนแล้ววาร์ปขึ้น (ไม่ใช้ทวีนเพื่อไม่ให้ “ลิฟต์”)
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("P_Climb"):
		player_sprite.play("P_Climb")
		await player_sprite.animation_finished

	global_position = want_forward_pos if can_forward else top_pos

	# ปิดชดเชยและคืนอนิเมปกติ
	_apply_pread_visual_fix(false)
	floor_snap_length = 12
	set_deferred("position", position + Vector2(0, 1))
	player_sprite.play("Idle")
	is_pread_active = false



# --- Pread visual fix (offset/scale เฉพาะอนิเม P_Climb) ---
const PREAD_VISUAL_OFFSET := Vector2(0, 1)   # เลื่อนลง (ลอง 50–70 ตามรูปจริง)
const PREAD_VISUAL_SCALE  := 0.70             # ลดขนาดให้พอๆ กับตัวหลัก

var _pread_orig_pos   : Vector2
var _pread_orig_scale : Vector2
# --- Pread visual fix (คำนวณ offset/scale ให้อัตโนมัติขณะ P_Climb) ---
const PREAD_SCALE := 1            # ถ้าตัว P_Climb ใหญ่มาก ลดขนาดลงหน่อย
const PREAD_EXTRA_OFFSET_Y := 0.0     # เผื่อปรับจูนเพิ่ม/ลดทีหลัง (+ลง, -ขึ้น)

var _pread_orig_offset: Vector2
var _pread_orig_centered: bool

func _apply_pread_visual_fix(enable: bool) -> void:
	if enable:
		_pread_orig_scale   = player_sprite.scale
		_pread_orig_offset  = player_sprite.offset
		_pread_orig_centered = player_sprite.centered

		# ใช้ centered เพื่อให้สูตรชดเชยเวิร์ก
		player_sprite.centered = true

		# ลดสเกลเฉพาะช่วงปีน
		player_sprite.scale = _pread_orig_scale * PREAD_SCALE

		# คำนวณ offset.y ให้ “ส้นเท้า” อยู่ baseline เดิม
		var frames := player_sprite.sprite_frames
		if frames and frames.has_animation("Idle") and frames.has_animation("P_Climb"):
			var idle_tex  := frames.get_frame_texture("Idle", 0)
			var climb_tex := frames.get_frame_texture("P_Climb", 0)
			if idle_tex and climb_tex:
				var idle_h  := float(idle_tex.get_height())
				var climb_h := float(climb_tex.get_height()) * PREAD_SCALE
				# ความสูงต่างกัน/2 เพราะ centered -> bottom = pos.y + height/2
				var delta_h := climb_h - idle_h
				var offset_y := -0.5 * delta_h + PREAD_EXTRA_OFFSET_Y
				player_sprite.offset = _pread_orig_offset + Vector2(0.0, offset_y)
	else:
		# คืนค่าเดิมทุกอย่าง
		player_sprite.scale    = _pread_orig_scale
		player_sprite.offset   = _pread_orig_offset
		player_sprite.centered = _pread_orig_centered

# เรียกจากไอเท็มเมื่อเก็บสำเร็จ
func unlock_krahang() -> void:
	has_krahang = true

# ตรวจปุ่ม "2"
func handle_krahang_input() -> void:
	# เงื่อนไขห้ามใช้: ยังไม่ปลดล็อก / กำลังใช้สกิล / ล่องหน / อยู่ร่างกุมาร
	if !has_krahang or is_krahang_active or is_invis or is_kuman_form or is_buffalo_form:
		return
	if Input.is_action_just_pressed("Skill2"):
		_do_krahang()


# ===== Helper: คำนวณระยะที่ขยับได้แบบไม่ชน =====
func _sweep_dist(motion: Vector2, step: float = 2.0) -> float:
	var total: float = motion.length()
	if total <= 0.0:
		return 0.0
	var dir: Vector2 = motion / total
	var traveled: float = 0.0
	while traveled < total:
		var next: float = min(step, total - traveled)  # 🔹 บังคับ type float
		# ถ้าขยับไปได้ถึงระยะ traveled + next แล้วชน → หยุด
		if test_move(global_transform, dir * (traveled + next)):
			break
		traveled += next
	return traveled

# ===== Krahang: ขึ้น → พุ่ง → ลง (ชนบล็อกจะหยุดทันที) =====
func _do_krahang() -> void:
	is_krahang_active = true
	velocity = Vector2.ZERO  # ไม่ให้ฟิสิกส์พาไป

	var dir := -1.0 if player_sprite.flip_h else 1.0
	var start_pos := global_position

	# 1) เล่นอนิเมเริ่ม (ถ้ามี)
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("KH_Start"):
		player_sprite.play("KH_Start")
		await player_sprite.animation_finished

	# 2) ลอยขึ้น (ตรวจชนเพดาน)
	var rise := _sweep_dist(Vector2(0, -kh_rise_px))
	var t := create_tween()
	t.tween_property(self, "global_position", start_pos + Vector2(0, -rise), kh_rise_time)
	await t.finished

	# 3) พุ่งไปข้างหน้า (ชนกำแพงจะหยุด)
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

	# 4) ลงพื้น (ไม่ทะลุพื้น)
	var end_pos := global_position
	var fall := _sweep_dist(Vector2(0, kh_rise_px))
	t = create_tween()
	t.tween_property(self, "global_position", end_pos + Vector2(0, fall), kh_fall_time)
	await t.finished

	# 5) จบสกิล → กลับสู่อนิเมปกติ
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("KH_End"):
		player_sprite.play("KH_End")
	else:
		player_sprite.play("Idle")

	# ช่วยให้ติดพื้นเฟรมถัดไป
	floor_snap_length = 12
	set_deferred("position", position + Vector2(0, 1))
	velocity = Vector2.ZERO
	is_krahang_active = false


# ================== KUMAN (form 1 block) ==================
# เรียกจากไอเท็มเมื่อเก็บสำเร็จ
func unlock_kuman() -> void:
	has_kuman = true

# ตรวจปุ่ม "1"
func handle_skill_input() -> void:
	if Input.is_action_just_pressed("Skill1") and has_kuman:
		if !kuman_toggle_in_air and !is_on_floor():
			return
		_set_kuman_form(!is_kuman_form)

# สลับร่าง + สลับคอลลิเดอร์หลัก
func _set_kuman_form(enable: bool) -> void:
	# ถ้าจะสลับเป็นร่างเตี้ย แต่ไม่มีคอลลิเดอร์ร่างเตี้ย → ยกเลิก (กันตก)
	if enable and body_small == null:
		push_warning("No CollisionShape2D_kuman found. Abort transform.")
		return

	# ถ้าจะขยายกลับเป็นร่างสูง ให้เช็ค headroom (กันหัวชนเพดาน)
	if !enable:
		var headroom := 16.0  # ปรับตามส่วนต่างความสูง (px)
		# ถ้ามีอะไรกีดขวางด้านบน ก็ไม่ให้ขยาย
		if test_move(global_transform, Vector2(0, -headroom)):
			return

	is_kuman_form = enable

	# สลับคอลลิเดอร์แบบ deferred เพื่อลดปัญหาชนกลางเฟรม
	if body_small:
		body_small.set_deferred("disabled", not enable)  # ร่างเตี้ยเปิดเมื่อ enable
	if body_tall:
		body_tall.set_deferred("disabled", enable)       # ร่างสูงปิดเมื่อ enable

	# จิ้มลงนิดหนึ่ง + เปิด snap ให้ติดพื้นแน่นอนเฟรมถัดไป
	if is_on_floor():
		floor_snap_length = 12
		set_deferred("position", position + Vector2(0, 1))
		velocity.y = max(velocity.y, 0.0)

	# ปรับสเตตัสตามร่าง (ออปชัน)
	if enable:
		move_speed = 130
	else:
		move_speed = 270


# ================== ANIM / FX ==================
func _on_anim_finished() -> void:
	if is_invis and player_sprite.animation == "Pre_Invisible" and player_sprite.speed_scale >= 0.0:
		if abs(velocity.x) > 0.0:
			player_sprite.play("Invisible", 1.5)
		else:
			player_sprite.play("Idle_Invis")

func player_animations():
	if is_krahang_active or is_pread_active:
		return  # อย่าทับ KH_Start / KH_Idle ระหว่างพุ่ง

	particle_trails.emitting = false

	if player_sprite.animation == "Pre_Invisible" and player_sprite.is_playing():
		return

	if is_invis:
		if abs(velocity.x) > 0:
			player_sprite.play("Invisible", 1.5)
		else:
			player_sprite.play("Idle_Invis")
		return

	# ----- รูปแบบร่างควาย -----
	if is_buffalo_form:
		var walk_name := "buffalo_walk"
		var idle_name := "buffalo_Idle"
		# กันกรณีสะกดไม่ตรง: ลองแอนิเม fallback
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
			# กลางอากาศ ใช้ idle ของควายแทนไปก่อน (หรือทำ buffalo_Fall เพิ่มได้)
			player_sprite.play(idle_name)
		return
		
	# === เลือกชุดอนิเมชันตามร่าง ===
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
	get_tree().reload_current_scene()   # รีสตาร์ตเลเวล → trap ทั้งหมดรีสปอน

func respawn_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

# ================== SIGNALS ==================
func _on_collision_body_entered(body):
	if body.is_in_group("Traps") or body.is_in_group("Monsters"):
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		death_tween()
