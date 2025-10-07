@tool
extends Node3D

@export var spawn_area := Vector3.ONE:
	set(value):
		$MeshInstance3D.scale = value
		spawn_area = value
@export var enemies : Array[PackedScene]

func _ready() -> void:
	if !Engine.is_editor_hint():
		$MeshInstance3D.visible = false

func spawn(count : int) -> void:
	if get_tree().get_node_count_in_group("enemy") >= get_parent().enemy_cap: return
	for _i in count:
		var prefab : PackedScene = enemies.pick_random()
		var junk_instance := prefab.instantiate()
		add_sibling(junk_instance)
		junk_instance.global_position = global_position + Vector3(randf_range(-spawn_area.x, spawn_area.x), randf_range(-spawn_area.y, spawn_area.y), randf_range(-spawn_area.z, spawn_area.z)) / 2.0;
