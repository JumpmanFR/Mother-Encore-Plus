extends Area2D
class_name FogArea

export (NodePath)onready var _near_fog_zone_area = get_node(_near_fog_zone_area) as NearFogArea

onready var timer: Timer

const FADE_TIME := 2.0

var _fade: CanvasLayer
var _fade_in_progress: bool = false
var cut := 0

func _ready():
	timer = Timer.new()
	timer.wait_time = FADE_TIME / 2.0
	timer.one_shot = true
	timer.connect("timeout", self, "_pause_player")
	add_child(timer)

func _on_FogZone_body_entered(body):
	if not body is PartyMemberPlayer:
		return
	global.can_pause = false
	global.get_player().can_interact = false
	_fade = uiManager.get_fade()
	_fade_in_progress = true
	
	_fade.set_color(Color.white)
	_fade.set_cut(0.0, FADE_TIME, 0)
	_fade.connect("cut_done", self, "_on_fade_completed", [], CONNECT_ONESHOT)
	timer.start()

func _pause_player():
	if _fade_in_progress:
		global.get_player().pause()
	

func _on_fade_completed():
	_fade_in_progress = false
	global.get_player().position = _near_fog_zone_area.get_original_position()
	global.get_player().set_direction(_near_fog_zone_area.get_original_direction())
	if global.partySpace.size() > 1:
		for i in global.partySpace.size():
			global.partySpace.push_front(global.get_player().position)
			global.partySpace.pop_back()
		for i in range(1, global.partyObjects.size()):
			global.partyObjects[i].position = global.get_player().position
			global.partyObjects[i].reinit()
			global.partyObjects[i].disappear()
	
	_fade.set_cut(1.0, 1, 0)
	yield(_fade, "cut_done")
	
	global.get_player().unpause()
	global.can_pause = true
	global.get_player().can_interact = true

func _on_FogZone_body_exited(body):
	if not body is PartyMemberPlayer or not _fade_in_progress:
		return
	timer.stop()
	global.can_pause = true
	global.get_player().can_interact = true
	global.get_player().unpause()
	_fade_in_progress = false
	_fade.set_cut(1.0, 1, 0)
	if _fade.is_connected("cut_done", self, "_on_fade_completed"):
		_fade.disconnect("cut_done", self, "_on_fade_completed")
