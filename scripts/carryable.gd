extends RigidBody3D

@export var is_carryable := true
@export var throw_force := 30.0
@export var weight := 0.7
@onready var throwable_timer: Timer = $ThrowableTimer
@export var mini_mesh : Mesh
@export var mini_mesh_scale := 0.2
@export var mini_mesh_offset := Vector3.ZERO

@export var possible_meshes : Array[Mesh]
@export var possible_mesh_scales : Array[float]
@export var possible_mesh_offsets : Array[Vector3]

@onready var particles: CPUParticles3D = $CPUParticles3D
@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	var mesh_index = randi_range(0, len(possible_meshes) - 1)
	$Mesh.mesh = possible_meshes[mesh_index]
	$Mesh.position = possible_mesh_offsets[mesh_index]
	mini_mesh = possible_meshes[mesh_index]
	mini_mesh_scale = possible_mesh_scales[mesh_index]
	mini_mesh_offset = possible_mesh_offsets[mesh_index] * mini_mesh_scale

func throw(facing_rotation : Vector3, velocity : Vector3):
	reset_physics_interpolation()
	var throw_direction = Vector2.UP.rotated(-facing_rotation.y)
	#throw_direction = Vector3(throw_direction.x, 0.0, throw_direction.y)
	throw_direction = Vector3(throw_direction.x, facing_rotation.x + 0.05, throw_direction.y)
	var throw_velocity : Vector3 = throw_direction.normalized() * throw_force
	#throw_velocity.y = 0.0
	var projected_velocity : Vector3 = throw_direction.normalized().dot(velocity) * throw_direction.normalized()
	linear_velocity = projected_velocity + throw_velocity
	#linear_velocity = throw_velocity

	throwable_timer.start()

func _on_player_detected(area: Area3D) -> void:
	if !is_carryable: return
	area.get_parent().carry_junk(self)
	#is_carryable = false
	#throwable_timer.stop()

func _on_throwable_timer_timeout() -> void:
	is_carryable = true

func _on_hit_detected(area: Area3D) -> void:
	if freeze: return
	var damage := linear_velocity.length()
	if damage < 2.0: return
	var possible_target := area.get_parent()
	if "on_damage" in possible_target:
		freeze = true
		$PhysicsCollider.disabled = true
		throwable_timer.stop()
		is_carryable = false
		possible_target.on_damage(damage)
		mesh.visible = false
		particles.emitting = true

func _on_particles_finished() -> void:
	queue_free()

func _on_hit_detector_body_detected(body: Node3D) -> void:
	if freeze: return
	var damage := linear_velocity.length()
	if damage < 2.0: return
	var possible_target := body
	if "on_damage" in body:
		freeze = true
		throwable_timer.stop()
		is_carryable = false
		possible_target.on_damage(damage)
		mesh.visible = false
		particles.emitting = true
