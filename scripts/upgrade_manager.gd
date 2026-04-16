extends Control

@onready var game : Node3D = get_parent().get_parent()
@onready var boss : Control = get_tree().get_first_node_in_group("dialog")

func r(value) -> String:
	if value is float:
		value = round(value * 100) / 100.0

	# surely there's a better way to do this
	var output_str = str(value)
	if output_str.ends_with(".0"):
		output_str = output_str.substr(0, output_str.length() - 2)

	return "[color=be3024]"+output_str+"[/color]"

func g(value) -> String:
	if value is float:
		value = round(value * 100) / 100.0

	var output_str = str(value)
	if output_str.ends_with(".0"):
		output_str = output_str.substr(0, output_str.length() - 2)

	return "[color=2effa1]"+output_str+"[/color]"

func get_player_property(property: StringName):
	if !is_inside_tree(): return 0
	var player := get_tree().get_first_node_in_group("player")
	if !player: return 0
	return player.get(property)

# dont do this
# this one time its allowed i made this with like 1 hour to spare before the jam deadline
var upgrades = {
	"junk_cap_up": {
		"title": "Resource Expansion",
		"description": func() -> String: return "Increase item spawn limit by 5 (%s -> %s)" % [r(game.junk_cap), g(game.junk_cap + 5)],
		"check": func() -> bool: return true,
		"execute": func() -> void: game.junk_cap = game.junk_cap + 5,
		"quotes": [
			"acquisition quota increased. do not make\nus regret the investment.",
			"more opportunities to prove yourself.\nsquander at your own risk.",
			"quantity is the new quality.",
			"management appreciates your\nappetite for overwork.",
		],
		"quotes_done": [],
	},
	"junk_spawn_rate": {
		"title": "Supply Chain Optimization",
		"description": func() -> String: return "Decrease item spawn interval by 20%% (%ss -> %ss)" % [r(game.junk_spawn_rate), g(game.junk_spawn_rate * 0.8)],
		"check": func() -> bool: return game.junk_spawn_rate > 0.5,
		"execute": func() -> void: game.junk_spawn_rate = game.junk_spawn_rate * 0.8,
		"quotes": [
			"procurement accelerated. keep up.",
			"the market moves faster than you.\nthat is not a compliment.",
			"idle hands reduce shareholder value.",
		],
		"quotes_done": [],
	},
	"open_window_longer": {
		"title": "Profit Opportunity",
		"description": func() -> String: return "Increase mailbox open time by 20%% (%ss -> %ss)" % [r(game.deposit_window), g(game.deposit_window * 1.2)],
		"check": func() -> bool: return true,
		"execute": func() -> void: game.deposit_window = game.deposit_window * 1.2,
		"quotes": [
			"more time to capitalize.\nno time to celebrate.",
			"take advantage of every opportunity.\nor we will find someone who will.",
			"corporate grace period increased.\nmake good use of it.",
		],
		"quotes_done": [],
	},
	"closed_window_shorter": {
		"title": "Rapid Turnover",
		"description": func() -> String: return "Decrease mailbox closed time by 15%% (%ss -> %ss)" % [r(game.closed_window), g(game.closed_window * 0.85)],
		"check": func() -> bool: return game.closed_window > 0.5,
		"execute": func() -> void: game.closed_window = game.closed_window * 0.85,
		"quotes": [
			"downtime is theft.\nwe are reducing theft.",
			"rapid turnover keeps morale high.\nmostly our morale though.",
			"if you cannot handle the pace,\nhandle your resignation.",
		],
		"quotes_done": [],
	},
	"throw_rate": {
		"title": "Disciplinary Action",
		 "description": func() -> String: return "Decrease throw cooldown by 3 frames (%s -> %s)" % [r(game.throw_cooldown), g(max(3, game.throw_cooldown - 3))],
		"check": func() -> bool: return game.throw_cooldown > 12,
		"execute": func() -> void: game.throw_cooldown = max(9, game.throw_cooldown - 3),
		"quotes": [
			"you are now statistically\nmore dangerous to others",
			"anger is a renewable resource.\nwe expect full utilization.",
			"fewer misses means fewer excuses.",
		],
		"quotes_done": [],
	},
	"move_speed": {
		"title": "Efficient Commute",
		"description": func() -> String: return "Increase movement speed by 10%% (+%s%% -> +%s%%)" % [r(100.0 * (game.move_speed_mult - 1.0)), g(100.0 * (game.move_speed_mult * 1.1 - 1.0))],
		"check": func() -> bool: return game.move_speed_mult < 2.0,
		"execute": func() -> void: game.move_speed_mult = game.move_speed_mult * 1.1,
		"quotes": [
			"speed is a competitive advantage.\nnot an excuse to wander.",
			"stationary assets depreciate rapidly.\nkeep moving.",
			"never stop moving.\nif you do, we will notice.",
		],
		"quotes_done": [],
	},
	"throw_speed": {
		"title": "Regular Exercise",
		"description": func() -> String: return "Increase throw force by 6u (%su -> %su)\n(increases throw distance and impact damage)" % [r(game.throw_speed), g(game.throw_speed + 6)],
		"check": func() -> bool: return true,
		"execute": func() -> void: game.throw_speed = game.throw_speed + 6,
		"quotes": [
			"physical improvement\nmandated by HR.",
			"you are now stronger.\ndo not start getting ideas.",
			"we invested in your body.\nwe expect a return on that investment.",
		],
		"quotes_done": [],
	},
	"enemy_payout": {
		"title": "Competitive Spirit",
		"description": func() -> String: return "Increase payout on\nenemy kill by 75%% (%s%% -> %s%%)" % [r(100.0 * (game.enemy_payout_mult)), g(100.0 * (game.enemy_payout_mult + 0.75))],
		"check": func() -> bool: return true,
		"execute": func() -> void: game.enemy_payout_mult = game.enemy_payout_mult + 0.75,
		"quotes": [
			"kill efficiently.\nprofit enthusiastically.",
			"do not sympathize\nwith your competition.",
			"we are all replaceable.\nincluding you.",
		],
		"quotes_done": [],
	},
	"loot_payout": {
		"title": "Yield Optimization",
		"description": func() -> String: return "Increase payout on item\ndeposit by 75%% (%s%% -> %s%%)" % [r(100.0 * (game.loot_payout_mult)), g(100.0 * (game.loot_payout_mult + 0.75))],
		"check": func() -> bool: return true,
		"execute": func() -> void: game.loot_payout_mult = game.loot_payout_mult + 0.75,
		"quotes": [
			"our analysts predict...\nmild success. prove them right.",
			"every little bit helps.\nbut bigger bits help more.",
			"if you are not making money,\nyou are losing money. our money.",
		],
		"quotes_done": [],
	},
	"heal": {
		"title": "Mandatory Recovery",
		"description": func() -> String: return "Gain 60HP instantly.\nUnlike other sources of healing, can %s 100HP." % g("exceed"),
		"check": func () -> bool: return !game.is_leech,
		"execute": func() -> void: get_tree().get_first_node_in_group("player").heal(60),
		"quotes": [
			"patch yourself up and get back to it.",
			"workplace injuries are\nan individual responsibility.",
			"be sure to avoid future\nbleeding incidents on company time.",
			"back on your feet.\nwork waits for no one.",
		],
		"quotes_done": [],
	},
	"leech": {
		"title": "Postmortem Dividend",
		# "description": func() -> String: return "Gain health equal to 100%% of kill payout.\n%s" % r("Mandatory Recovery (healing) no longer appears."),
		"description": func() -> String: return "Gain 6HP on kill, up to 100HP total.\n%s" % r("Mandatory Recovery (healing) no longer appears."),
		"check": func() -> bool: return !game.is_leech,
		"execute": func() -> void: game.is_leech = true,
		"quotes": [
			"self-sufficiency\nby any means necessary.",
			"your health insurance policy\nis no longer necessary.",
			"drain them before they drain you.\nwe respect the initiative.",
		],
		"quotes_done": [],
	},
	"weightless": {
		"title": "Burden Reassignment",
		"description": func() -> String: return "Decrease carry slowdown by 30%% (%s%% -> %s%%)" % [r(100.0 * (game.item_weight_mult)), g(100.0 * (game.item_weight_mult - 0.3))],
		"check": func() -> bool: return game.item_weight_mult >= 0.3,
		"execute": func() -> void: game.item_weight_mult -= 0.3,
		"quotes": [
			"lighter load. higher expectations.\nthe math works out",
			"carry your weight, and then some.",
		],
		"quotes_done": [],
	}
}

func reveal() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	selected_upgrades = pick_upgrades()
	get_tree().paused = true
	$VBoxContainer/UpgradeCard.title = _t(selected_upgrades[0])
	$VBoxContainer/UpgradeCard.description =  _d(selected_upgrades[0])
	$VBoxContainer/UpgradeCard2.title = _t(selected_upgrades[1])
	$VBoxContainer/UpgradeCard2.description = _d(selected_upgrades[1])
	$VBoxContainer/UpgradeCard3.title = _t(selected_upgrades[2])
	$VBoxContainer/UpgradeCard3.description =  _d(selected_upgrades[2])
	$AnimationPlayer.play("reveal")

func pick_upgrades(count := 3) -> Array:
	var available_upgrades = []
	for upgrade_name in upgrades.keys():
		if upgrades[upgrade_name]["check"].call():
			available_upgrades.append(upgrade_name)
	available_upgrades.shuffle()
	return available_upgrades.slice(0, count)

func apply_upgrade(upgrade_name: String) -> void:
	if upgrade_name == "":
		return
	upgrades[upgrade_name]["execute"].call()
	var quote_list = upgrades[upgrade_name]["quotes"]
	var quote_done_list = upgrades[upgrade_name]["quotes_done"]
	if quote_list.size() > 0:
		var quote = quote_list[randi() % quote_list.size()]
		boss.say(quote)
		quote_done_list.append(quote)
		quote_list.erase(quote)
	$AnimationPlayer.stop()

func _t(upgrade_name: String) -> String:
	return upgrades[upgrade_name]["title"]
func _d(upgrade_name: String) -> String:
	var desc = upgrades[upgrade_name]["description"]
	if desc is Callable:
		return desc.call()
	else: return desc

var selected_upgrades = []

func _on_upgrade_card_clicked() -> void:
	apply_upgrade(selected_upgrades[0])
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_upgrade_card_2_clicked() -> void:
	apply_upgrade(selected_upgrades[1])
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_upgrade_card_3_clicked() -> void:
	apply_upgrade(selected_upgrades[2])
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
