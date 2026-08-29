extends BattleParticipant

signal play_correct_hit(toggled_state)
signal launch_rocket(battle_participant, skill_name)

const ROCKET_LAUNCHER_ENEMY_ID = "rocketlauncher"
const RocketLauncherSprite = preload("res://Nodes/Ui/Battle/RocketLauncherSprite.tscn")

var toggled := false
var _right_side := false
var _rockets_launched := 0
var _countdown_appeared := false

var countdown := 3

var _battle_obj

func _init(battle_obj, is_right := false)\
.(battle_obj, Enemy.new(ROCKET_LAUNCHER_ENEMY_ID), 1 if is_right else 0):
	_battle_obj = battle_obj
	if !is_right:
		rename_as_first_homonym()
	_right_side = is_right
	add_launcher_sprite(battle_obj.get_node("Enemies"), is_right)
	add_passive_skill("absorb_attacks")
	
	_connections(battle_obj)
	battle_obj.add_action(self, "advance_counter")
	immortal = true

func _connections(battle_obj):
	battle_obj.connect("round_done", self, "_on_round_done")
	connect("launch_rocket", battle_obj, "add_action", [false])
	connect("bp_hit", self, "_on_hit")

func add_launcher_sprite(container: Node, is_right := false):
	var texture = RocketLauncherSprite.instance()
	
	_battle_sprite = texture
	_battle_sprite.call_deferred("set_right", is_right)
	connect("play_correct_hit", _battle_sprite, "play_hit_anim")
	
	container.add_child(texture)

func _on_round_done(_turns_count: int):
	set_scripted_skill("advance_counter")

func advance_counter():
	if !_countdown_appeared:
		_countdown_appeared = true
		countdown = 3
		_set_rocket()
		yield(_battle_sprite.set_rocket_sprite(toggled), "completed")
		_battle_sprite.counter.show()
		_battle_sprite.set_counter_number(countdown)
	else:
		countdown -= 1
		_battle_sprite.set_counter_number(countdown)
		if countdown <= 0:
			yield(_battle_obj.get_tree().create_timer(0.1), "timeout")
			emit_signal("launch_rocket", self, "rocketLaunchBlue" if toggled else "rocketLaunchRed")
			

func _set_rocket():
	
	if _right_side and _rockets_launched % 2 == 0:
		toggled = false
	elif !_right_side and _rockets_launched % 2 == 1:
		toggled = false
	elif randi() % 2 == 1: toggled = not toggled

func _on_hit():
	if _countdown_appeared:
		toggled = not toggled
		emit_signal("play_correct_hit", toggled)

func launch():
	_battle_sprite.set_texture(_battle_sprite.ROCKET_LAUNCHER_SPRITE)
	_battle_sprite.counter.hide()
	_countdown_appeared = false
	_rockets_launched += 1


func is_targetable_for_action(action) -> bool:
	if action.skill == globaldata.get_battle_skill("rocketLaunchBlue"):
		return false
	return .is_targetable_for_action(action)
