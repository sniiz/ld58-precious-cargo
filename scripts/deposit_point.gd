extends StaticBody3D
@onready var label: Label3D = $Label3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bounce_animation: AnimationPlayer = $BounceAnimation

@warning_ignore("unused_signal")
signal player_target
@warning_ignore("unused_signal")
signal player_untarget

@export var is_closed := true:
	set(value):
		if !value:
			animation_player.play("enable")
			label.modulate = Color("ffffff")
			label.text = "/F/ Deposit Items"
			if label.visible:
				bounce_animation.play("hover")
		else:
			label.text = "deposit closed"
			label.modulate = Color("be3024")
			animation_player.play("disable")
		is_closed = value

func _on_player_target() -> void:
	label.visible = true
	if !is_closed:
		bounce_animation.play("hover")

func _on_player_untarget() -> void:
	label.visible = false

func fake_on_damage() -> void:
	var boss := get_tree().get_first_node_in_group("dialog")
	if !boss.is_revealed: boss.say("refrain from treating the\ndeposit point so carelessly.")

func deposit(junk: Array[RigidBody3D], player: Node3D) -> bool:
	if is_closed: return false
	bounce_animation.stop()
	bounce_animation.play("active")
	label.visible = false
	var mult : float = get_parent().loot_payout_mult
	var junk_weights := 0.0
	for item in junk:
		junk_weights += item.weight

	player.add_money(ceil(junk_weights * 25.0 * mult))
	return true
