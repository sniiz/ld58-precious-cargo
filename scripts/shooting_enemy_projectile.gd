extends Node3D

@export var damage := 35.0
@export var travel_speed := 25.0

@export var max_lifetime := 3.0
var lifetime := 0.0

var is_explode := false
var is_activated := false

func _explode() -> void:
	if is_explode: return
	is_explode = true
	$MeshInstance3D.hide()
	$OmniLight3D.hide()
	$CPUParticles3D.emitting = true

func _on_detector_area_entered(area: Area3D) -> void:
	if is_explode || !is_activated: return

	var area_owner : Node3D = area.get_parent()
	if area_owner.is_in_group("player"):
		area_owner.on_damage(damage)
		_explode()

func _on_detector_body_entered(body: Node3D) -> void:
	if is_explode || !is_activated: return
	if body.is_in_group("player"):
		body.on_damage(damage)
	_explode()

func _on_cpu_particles_3d_finished() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	if is_explode || !is_activated: return
	lifetime += delta
	global_position -= global_transform.basis.z * delta * travel_speed
	if lifetime >= max_lifetime: _explode()

func activate(pos: Vector3, rot: Vector3):
	if is_explode: return
	global_position = pos
	global_rotation = rot
	reset_physics_interpolation()
	#await get_tree().physics_frame
	is_activated = true
