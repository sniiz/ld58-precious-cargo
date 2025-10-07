extends CharacterBody3D

@export var base_speed := 15.0

@export var acceleration := 5.0
@export var slowdown := 12.0

@export var jump_velocity := 5.5
@export var in_air_speed_rate := 0.3
@export var mouse_sensitivity := 0.08

@export var max_health := 100.0
@export var health := max_health
var display_health := max_health

@export var speed_mod := 0.0
@export var accel_mod := 0.0
@export var hurt_speed_mod := 0.0

@export var target_fov := 90.0:
	set(value):
		target_fov = value
		camera.fov = target_fov + fov_mod
@export var fov_mod := 0.0:
	set(value):
		fov_mod = value
		camera.fov = target_fov + fov_mod

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/CamContainer/Camera3D
@onready var head_anim: AnimationPlayer = $HeadAnimation
@onready var jump_anim: AnimationPlayer = $JumpAnimation
@onready var throw_marker: Marker3D = $Head/ThrowMarker
@onready var raycast: RayCast3D = $Head/CamContainer/Camera3D/RayCast3D
@onready var arm: Node3D = $Head/CamContainer/Camera3D/Arm
@onready var junk_anchor: Marker3D = $Head/CamContainer/Camera3D/Arm/Junk
@onready var arm_flash_anim: AnimationPlayer = $ArmFlashAnimator
@onready var hand_animator: AnimationPlayer = $HandAnimator
@onready var money_container: PanelContainer = $CanvasLayer/Control/Money
@onready var money_label: Label = $CanvasLayer/Control/Money/MarginContainer/Label
@onready var money_animator: AnimationPlayer = $CanvasLayer/Control/Money/MarginContainer/MoneyAnimator
@onready var health_progress: TextureProgressBar = $CanvasLayer/Control2/TextureProgressBar
@onready var pts_progress: TextureProgressBar = $CanvasLayer/Control/TextureProgressBar
@onready var deposit_progress: TextureProgressBar = $CanvasLayer/Control/TextureProgressBar2
@onready var deposit_progress_label: Label = $CanvasLayer/Control/Money2/MarginContainer/Label

@export var carried_junk : Array[RigidBody3D]
@export var carried_junk_offsets : Array[Vector3]
@export var carried_junk_spin : Array[float]

@export var cash := 0
@export var actual_cash := 0
@export var add_speed := 10.0

@export var deposit_progress_sec := 0.0

var knockback_strength := 2.0

var mouse_input : Vector2
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var was_on_floor := true
var current_speed : float = 0.0
var tangent_speed : float = 0.0
var air_time := 0.0

var headbob_enabled := true
var jump_anim_enabled := true

var targeted_node : Node3D
var junk_offset : Vector2

@export var level := 0
@onready var next_required_points := calculate_required_points(0)
var level_progress := 0
var display_level_progress := 0

@export var throw_cooldown_frames := 18
var throw_cooldown_counter := throw_cooldown_frames

func _ready() -> void:
	var config := ConfigFile.new()
	var _error := config.load("user://pref.cfg")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_sensitivity = config.get_value("conf", "mouse_sensitivity", 0.08)
	headbob_enabled = config.get_value("conf", "headbob", true)
	jump_anim_enabled = config.get_value("conf", "jump_anim", true)
	start_deposit(6.0, true)

func start_deposit(wait_time: float, is_closed: bool) -> void:
	deposit_progress_sec = 0.0
	deposit_progress_label.text = "CLOSED" if is_closed else "OPEN"
	deposit_progress.max_value = wait_time
	deposit_progress.tint_progress = Color("be3024") if is_closed else Color("286ded")
	deposit_progress_label.modulate = Color("be3024") if is_closed else Color("286ded")

func _handle_head_rotation() -> void:
	head.rotation_degrees.y -= mouse_input.x * mouse_sensitivity
	arm.rotation_degrees.y -= mouse_input.x * mouse_sensitivity * 0.3
	junk_offset.x -= mouse_input.x * mouse_sensitivity * 0.001
	head.rotation_degrees.x -= mouse_input.y * mouse_sensitivity
	arm.rotation_degrees.x -= mouse_input.y * mouse_sensitivity * 0.3
	mouse_input = Vector2.ZERO
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func humanize_number(number : String) -> String:
	var to_return : String
	var decimals : String
	if "." in number:
		decimals = "." + number.split(".", false, 0)[1]
	if len(number.replace(decimals, "")) < 4:
		return number
	else:
		var i : int = 0
		for item in number.replace(decimals, "").reverse():
			if i == 3:
				item += ","
				i = 0
			to_return = item + to_return
			i += 1
		return to_return + decimals

func add_money(money : int) -> void:
	cash += money
	money_animator.play("add")

	level_progress += money
	if level_progress >= next_required_points:
		level += 1
		level_progress = 0
		next_required_points = calculate_required_points(level)
		pts_progress.max_value = next_required_points
		await get_tree().create_timer(0.3).timeout
		get_parent().handle_upgrade(level)

@warning_ignore("shadowed_variable")
func calculate_required_points(level: int) -> int:
	return floor(110 * pow(1.45, level))

func _handle_movement(delta: float, input_dir: Vector2) -> void:
	var rotated_direction := input_dir.rotated(-head.rotation.y)
	var direction := Vector3(rotated_direction.x, 0, rotated_direction.y)

	var real_speed : float = max(0.0, base_speed + speed_mod + hurt_speed_mod)

	if is_on_floor():
		if rotated_direction.is_equal_approx(Vector2.ZERO):
			velocity.x = lerp(velocity.x, direction.x * real_speed, (slowdown + accel_mod) * delta)
			velocity.z = lerp(velocity.z, direction.z * real_speed, (slowdown + accel_mod) * delta)
		else:
			velocity.x = lerp(velocity.x, direction.x * real_speed, (acceleration + accel_mod) * delta)
			velocity.z = lerp(velocity.z, direction.z * real_speed, (acceleration + accel_mod) * delta)
	else:
		velocity.x = lerp(velocity.x, direction.x * real_speed, (acceleration + accel_mod) * delta * in_air_speed_rate)
		velocity.z = lerp(velocity.z, direction.z * real_speed, (acceleration + accel_mod) * delta * in_air_speed_rate)

func _handle_jumping() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_velocity
		if jump_anim_enabled: jump_anim.play("jump")

func _handle_headbob(delta: float, no_input: bool) -> void:
	if !headbob_enabled: return
	var playback_speed := current_speed / base_speed
	if playback_speed >= 0.1 and is_on_floor() and !no_input:
		if !head_anim.is_playing():
			head_anim.play("run")
		head_anim.speed_scale = playback_speed * 1.5
	else:
		if head_anim.is_playing():
			head_anim.stop(true)
		camera.position = lerp(camera.position, Vector3.ZERO, delta * 20.0)

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("pause"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("forward"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input.x += event.relative.x
		mouse_input.y += event.relative.y

func carry_junk(junk_node: RigidBody3D) -> void:
	if len(carried_junk) >= 10:
		arm_flash_anim.play("no_space")
		return
	carried_junk.push_back(junk_node)
	carried_junk_spin.push_back(randf_range(-1.0, -2.0))
	junk_node.is_carryable = false
	speed_mod -= junk_node.weight
	var junk_mesh = MeshInstance3D.new()
	junk_mesh.mesh = junk_node.mini_mesh
	junk_mesh.scale = Vector3(junk_node.mini_mesh_scale, junk_node.mini_mesh_scale, junk_node.mini_mesh_scale)
	junk_anchor.add_child(junk_mesh)
	var offset := Vector3(junk_node.mini_mesh_offset.x, junk_node.mini_mesh_offset.y + 0.12 * (len(carried_junk) - 1), junk_node.mini_mesh_offset.z)
	junk_mesh.position = offset
	carried_junk_offsets.push_back(offset)
	junk_node.get_parent().call_deferred("remove_child", junk_node) # ew

func _throw() -> void:
	if len(carried_junk) == 0: return
	var junk : RigidBody3D = carried_junk.pop_back()
	carried_junk_spin.pop_back()
	carried_junk_offsets.pop_back()
	#junk.reparent(get_parent(), false)
	speed_mod += junk.weight
	add_sibling(junk)
	junk_anchor.get_child(-1).queue_free()
	junk.global_position = throw_marker.global_position
	junk.throw(head.rotation, get_real_velocity())

	var look_dir := -head.global_transform.basis.z.normalized()
	velocity -= look_dir * knockback_strength

	hand_animator.stop()
	hand_animator.play("recoil")
	junk_offset.y -= 0.075

func _handle_throwing() -> void:
	throw_cooldown_counter = min(throw_cooldown_frames, throw_cooldown_counter + 1)
	if Input.is_action_pressed("throw") and throw_cooldown_counter >= throw_cooldown_frames:
		throw_cooldown_counter = 0
		_throw()

func on_damage(damage: float) -> void:
	health -= damage
	arm_flash_anim.stop()
	arm_flash_anim.play("hurt")
	health_progress.max_value = max_health
	if health <= 0:
		var config := ConfigFile.new()
		var _error := config.load("user://pref.cfg")
		var new_best : int = max(config.get_value("data", "high_score", 0), cash)
		config.set_value("data", "high_score", new_best)
		config.save("user://pref.cfg")
		get_parent().transition()

func heal(damage: float) -> void:
	health += damage

func _handle_raycast() -> void:
	if raycast.is_colliding():
		if !targeted_node:
			targeted_node = raycast.get_collider()
			if targeted_node.has_signal("player_target"): targeted_node.emit_signal("player_target")
	else:
		if targeted_node:
			if targeted_node.has_signal("player_untarget"): targeted_node.emit_signal("player_untarget")
			targeted_node = null

func _physics_process(delta: float) -> void:
	deposit_progress_sec += delta
	deposit_progress.value = deposit_progress_sec

	if actual_cash < cash:
		actual_cash = ceil(lerp(actual_cash, cash, delta * add_speed))
		money_label.text = humanize_number(str(actual_cash))

	if display_health != health:
		display_health = round(lerp(display_health, health, delta * 15.0))
		health_progress.value = display_health
		health_progress.max_value = max_health

	if level_progress == 0:
		display_level_progress = 0
		pts_progress.value = display_level_progress
	elif display_level_progress != level_progress:
		display_level_progress = ceil(lerp(display_level_progress, level_progress, delta * 15.0))
		pts_progress.value = display_level_progress

	if not is_on_floor() and gravity:
		velocity.y -= gravity * delta * 1.2

	var input_dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input_dir = Input.get_vector("left", "right", "forward", "back")

	_handle_head_rotation()
	_handle_movement(delta, input_dir)
	_handle_jumping()

	var real_velocity := get_real_velocity()
	tangent_speed = Vector3.ZERO.distance_to(Vector3(real_velocity.x, 0.0, real_velocity.z))
	current_speed = Vector3.ZERO.distance_to(real_velocity)
	_handle_headbob(delta, input_dir.is_equal_approx(Vector2.ZERO))
	_handle_throwing()

	if Engine.get_physics_frames() % 2: _handle_raycast()

	if targeted_node and Input.is_action_just_pressed("deposit") and targeted_node.is_in_group("deposit"):
		if targeted_node.deposit(carried_junk, self):
			for node in junk_anchor.get_children():
				node.queue_free()
			speed_mod = 0.0
			carried_junk = []
			carried_junk_spin = []
			carried_junk_offsets = []

	if !is_on_floor():
		air_time += delta
	elif !was_on_floor:
		if air_time >= 0.5 and jump_anim_enabled:
			jump_anim.play("land")
		air_time = 0.0

	var t := Time.get_ticks_msec()
	for i in range(len(carried_junk)):
		var child := junk_anchor.get_child(i)
		child.position.x = junk_offset.x * (i + 1) * 0.75
		child.position.z = junk_offset.y * (i + 1) * 0.2
		child.rotation_degrees.y += carried_junk_spin[i]
		child.position.y = sin(t * carried_junk_spin[i] * 0.002) * 0.01 + carried_junk_offsets[i].y

	junk_offset.x = lerp(junk_offset.x, 0.0, 40.0 * delta)
	junk_offset.y = lerp(junk_offset.y, 0.0, 12.0 * delta)

	arm.rotation_degrees.y = lerp(arm.rotation_degrees.y, 0.0, 20.0 * delta)
	arm.rotation_degrees.x = lerp(arm.rotation_degrees.x, 0.0, 20.0 * delta)

	if !jump_anim.is_playing():
		arm.position = lerp(arm.position, Vector3.ZERO, delta * 20.0)

	fov_mod = clampf(tangent_speed * 4 / base_speed, 0, 5)

	was_on_floor = is_on_floor()

	move_and_slide()
