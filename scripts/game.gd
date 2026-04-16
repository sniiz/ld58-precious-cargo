extends Node3D

@export var active := true

@export var junk_cap := 40
@export var junk_spawn_rate := 5.0
@export var enemy_cap := 2
@export var deposit_window := 8.0
@export var closed_window := 6.0
@export var throw_cooldown := 18.0
@export var move_speed_mult := 1.0:
	set(value):
		move_speed_mult = value
		get_tree().get_first_node_in_group("player").base_speed = 15.0 * move_speed_mult
@export var item_weight_mult := 1.0
@export var throw_speed := 30.0
@export var enemy_payout_mult := 1.0
@export var loot_payout_mult := 1.0
@export var is_leech := false

@onready var deposit_point: StaticBody3D = $DepositPoint
@onready var deposit_closed_time: Timer = $DepositClosedTime
@onready var deposit_open_time: Timer = $DepositOpenTime
@onready var transition_animator: AnimationPlayer = $CanvasLayer/TransitionAnimator
@onready var junk_timer: Timer = $JunkTimer
@onready var junk_spawner: Node3D = $JunkSpawner

@onready var player := get_tree().get_first_node_in_group("player")

func _on_test_timer_timeout() -> void:
	$JunkSpawner.spawn(15)
	junk_timer.start(junk_spawn_rate)

func _ready() -> void:
	$JunkSpawner.spawn(10)

func _on_deposit_open_time_timeout() -> void:
	#if !active: return
	deposit_point.is_closed = true
	if active: player.start_deposit(closed_window, true)
	deposit_closed_time.start(closed_window)

func _on_deposit_closed_time_timeout() -> void:
	deposit_point.is_closed = false
	if active: player.start_deposit(deposit_window, false)
	deposit_open_time.start(deposit_window)

func handle_upgrade(level: int) -> void:
	if !active: return
	$CanvasLayer/UpgradeManager.reveal()
	enemy_cap = 2 + floor(level / 5)

func _on_enemy_timer_timeout() -> void:
	if !active: return
	$EnemySpawner.spawn(1)

func transition() -> void:
	$CanvasLayer/TransitionAnimator.play("ttb", -1, 0.4)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/game/main_menu.tscn")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_WINDOWED)
