extends Control

onready var hpPlate = $PartyInfoPlate

func _ready():
	hpPlate._max_hp = 100
	hpPlate.set_instant_hp(100)
	hpPlate._max_pp = 100
	hpPlate.set_instant_pp(100)

func _input(event):
	if event.is_action_pressed("ui_right"):
		$PartyInfoPlate.set_target_hp(hpPlate.get_target_hp() + 1)
	if event.is_action_pressed("ui_left"):
		$PartyInfoPlate.set_target_hp(hpPlate.get_target_hp() - 1)
	if event.is_action_pressed("ui_up"):
		$PartyInfoPlate.set_target_pp(hpPlate.get_target_pp() + 1)
	if event.is_action_pressed("ui_down"):
		$PartyInfoPlate.set_target_pp(hpPlate.get_target_pp() - 1)
