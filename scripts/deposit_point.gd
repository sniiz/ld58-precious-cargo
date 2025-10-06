extends StaticBody3D
@onready var label: Label3D = $Label3D

@warning_ignore("unused_signal")
signal player_target
@warning_ignore("unused_signal")
signal player_untarget


func _on_player_target() -> void:
	label.visible = true

func _on_player_untarget() -> void:
	label.visible = false

func deposit(junk: Array[RigidBody3D], player: Node3D):
	var junk_weights := 0.0
	for item in junk:
		junk_weights += item.weight

	player.add_money(ceil(junk_weights * 2.5))
