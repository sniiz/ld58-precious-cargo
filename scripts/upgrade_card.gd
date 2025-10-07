extends Control

@export var title : String:
	set(value):
		title = value
		$PanelContainer/MarginContainer/VBoxContainer/Label.text = value
@export var description : String:
	set(value):
		description = value
		$PanelContainer/MarginContainer/VBoxContainer/RichTextLabel.text = value

var is_moused := false

signal clicked

func _on_mouse_entered() -> void:
	is_moused = true
	pivot_offset = size / 2.0
	var tween := get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_SPRING)

func _on_mouse_exited() -> void:
	is_moused = false
	var tween := get_tree().create_tween()
	tween.tween_property(self, "scale",  Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)

func _process(_delta: float) -> void:
	if is_moused and Input.is_action_just_pressed("throw"):
		clicked.emit()
