extends Node3D
@export var junk_cap := 40
@export var enemy_cap := 2

func _on_test_timer_timeout() -> void:
	$JunkSpawner.spawn(15)
	$EnemySpawner.spawn(1)

func _ready() -> void:
	$JunkSpawner.spawn(10)
