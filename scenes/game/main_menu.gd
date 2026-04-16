extends Node3D

@onready var version_label: Label = $Menu/Menu/Logo/VersionLabel


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")

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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var config := ConfigFile.new()
	var _error := config.load("user://pref.cfg")
	var best : int = config.get_value("data", "high_score", 0)
	if best > 0:
		$Menu/Menu/PanelContainer.show()
		$Menu/Menu/PanelContainer/Label.text = "personAl best: %s" % humanize_number(str(best))

	version_label.text = "POST-JAM v%s" % ProjectSettings.get("application/config/version")
