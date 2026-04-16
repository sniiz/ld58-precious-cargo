extends CharacterBody3D

var bullet_prefab = preload("res://scenes/game/shooting_enemy_projectile.tscn")

var health := 100
@onready var nozzle: Marker3D = $Nozzle
@onready var sprite: AnimatedSprite3D = $Sprite
@onready var target: CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var hurt: AnimationPlayer = $Hurt
@onready var cam := get_viewport().get_camera_3d()

@onready var healthbar: ProgressBar = $Health

@export var base_shoot_interval := 1.2
@export var wander_radius := 10.0
@export var wander_interval := 2.0
@export var move_speed := 3.0
@export var close_range := 20.0
@export var far_range := 30.0

var shoot_timer := base_shoot_interval * 1.5
var wander_timer := 0.0
var wander_target: Vector3
var wandering := false

func _ready() -> void:
	healthbar.hide()

func on_damage(damage: float) -> void:
	#healthbar.visible = true
	health -= ceil(damage)
	healthbar.value = health
	hurt.stop()
	hurt.play("hurt")
	if health <= 0:
		var payout := ceili(randi_range(6, 8) * get_parent().enemy_payout_mult)
		target.add_money(payout)
		if get_parent().is_leech: target.heal(10, false)
		queue_free()

func _physics_process(delta: float) -> void:
	var t := Time.get_ticks_msec()
	if not target or not target.is_inside_tree():
		return

	var to_player = (target.global_position - global_position)
	look_at(target.global_position, Vector3.UP)

	var dist = to_player.length()
	var wander_chance = clamp(1.0 - (dist / far_range), 0.0, 1.0)
	var shoot_interval = lerp(base_shoot_interval * 2.0, base_shoot_interval, 1.0 - wander_chance)

	shoot_timer -= delta * (1.0 if wandering else 0.5)
	wander_timer -= delta

	if wandering:
		var to_target = wander_target - global_position
		if to_target.length() < 0.5:
			wandering = false
			velocity = Vector3.ZERO
		else:
			var move_dir = to_target.normalized()
			velocity = move_dir * move_speed
	else:
		velocity = Vector3.ZERO
		if wander_timer <= 0.0 and randf() < wander_chance * 0.7:
			start_wandering()
			wander_timer = wander_interval

	move_and_slide()

	sprite.position.y = 1.9 + sin(t * 0.004) * 0.1

	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = shoot_interval

	if health < 100:
		healthbar.visible = !cam.is_position_behind(global_position + Vector3.UP * 4.0)
		if healthbar.visible:
			healthbar.position = cam.unproject_position(global_position + Vector3.UP * 4.0) + Vector2(-healthbar.size.x/2, 0)


func start_wandering() -> void:
	wandering = true
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	wander_target = global_position + random_dir * randf_range(1.0, wander_radius)


func shoot() -> void:
	if not is_instance_valid(nozzle):
		return
	sprite.play("attack")
	await get_tree().create_timer(0.2).timeout
	var bullet = bullet_prefab.instantiate()
	add_sibling(bullet)
	bullet.activate(nozzle.global_position, nozzle.global_rotation)
	await get_tree().create_timer(0.3).timeout
	sprite.stop()
	sprite.play("default")
