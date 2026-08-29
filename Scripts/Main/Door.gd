extends Area2D

signal done
signal entered
signal moved_player

export var targetX := 0
export var targetY := 0
export var dir := Vector2.ZERO
export (String, "None", "M3/door_open.wav", "Stairs_Up.mp3", "Stairs_Down.mp3") var sound := "None"
export (String, "None", "Door_Short.mp3") var end_sound := "None"
export (String, "Fade", "Circle", "Circle Focus", "Circle Pop", "Cut") var transit_in_anim := "Fade"
export (String, "Fade", "Circle", "Circle Focus", "Circle Pop", "Cut") var transit_out_anim := "Fade"
export var transit_in_color := Color.black
export var transit_out_color := Color.black
export var fade_in_speed := 1.5
export var fade_out_speed := 1.5
export var fadeout_music_on_scene_change := true
export var fadeout_music_length := 0.8
export (String) var targetScene := ""
export (Array) var _target_scene_params := []
export var set_respawn := false
export var set_crumbs := false
export var unpause_player := true
export (String) var flag_set := ""
export (bool) var set_flag_state := true

var _fade_done := false
var _current_state := 0
var _player = null
var _same_scene := false
var _active_door := true
var _fade = null
#var _saved_running_state := false
#var _saved_anim_state := ""

onready var _new_pos = $Position2D


func _ready():
	set_process(false)

func _on_Door_body_entered(body):
	if body == global.get_player() and !global.entering_door:
		global.get_player().pause(false, true)
		yield(get_tree(), "idle_frame")
		enter(body)

func _process(_delta):
	if _current_state != 0:
		match _current_state:
			1:
				if _fade_done:
					_current_state = 2
			2:
				emit_signal("entered")
				global.get_player().camera.current = true
				global.get_player().visible = true
				_fade.init_cut()
				if !_same_scene:
					_change_scene()
					#_move_player()
					
				else :
					_goto()
				if dir != Vector2.ZERO:
					_player.set_direction_and_input(dir)
					#_player.set_anim_state(_saved_anim_state)					
				
				_current_state = 3
			3:
				yield(get_tree(), "idle_frame")
				_create_party()
				_fade_out()
				if end_sound != null and end_sound != "None":
					$AudioStreamPlayer.stream = load("res://Audio/Sound effects/" + end_sound)
					$AudioStreamPlayer.play()
				#_player.set_anim_state(_saved_anim_state)
				_current_state = 4
			4:
				if _fade_done:
					set_process(false)
					if !uiManager.is_in_cutscene() and unpause_player:
						if dir != Vector2.ZERO:
							_player.set_direction_and_input(dir)
							#_player.set_anim_state(_saved_anim_state)
							#_player.set_idle()
						#if set_crumbs and InventoryManager.crumbTrail.scene != "":
						#	InventoryManager.setCrumbs(global.currentScene.filename, _player.global_position)
						_player.unpause()
					if !_same_scene:
						global.remove_persistent(self)
						queue_free()
					else:
						_active_door = true
						_current_state = 0
					if set_respawn:
						global.set_respawn()
					global.entering_door = false
					emit_signal("done")

func _change_scene():
	global.goto_scene("res://Maps/" + targetScene + ".tscn", Vector2(targetX, targetY - 7), Vector2(0, 0), _target_scene_params)
	uiManager.clear_on_screen_enemies()

func _goto():
	_player.global_position.x = _new_pos.global_position.x
	_player.global_position.y = _new_pos.global_position.y - 7
	emit_signal("moved_player")
	#cam.limit_top = -10000000
	#cam.limit_left = -10000000
	#cam.limit_right = 10000000
	#cam.limit_bottom = 10000000
	#cam.smoothing_enabled = false

func _create_party():
	if global.partySpace.size() <= 1:
		return
	for i in global.partySpace.size():
		global.partySpace.push_front(_player.position)
		global.partySpace.pop_back()
	for i in range(1, global.partyObjects.size()):
		global.partyObjects[i].position = _player.position
		global.partyObjects[i].reinit()
		global.partyObjects[i].disappear()

func _fade_in():
	_fade_done = false
	_fade.fade_in(transit_in_anim, transit_in_color, fade_in_speed)
	yield(_fade, "fade_in_done")
	_fade_done = true
	

func _fade_out():
	_fade_done = false
	if transit_out_anim == "":
		transit_out_anim = transit_in_anim
	_fade.fade_out(transit_out_anim, transit_out_color, fade_out_speed)
	yield(_fade, "fade_out_mostly_done")
	_fade_done = true

func enter(player: = global.get_player()):
	if global.entering_door:
		return
	
	global.entering_door = true
	
	_player = player
	if uiManager.is_in_cutscene():
		return
	_set_flag()
	_fade = uiManager.get_fade()
	if not _active_door:
		return
	
	if global.currentScene.get_name() == targetScene or targetScene == "":
		_same_scene = true
	else:
		if fadeout_music_on_scene_change:
			for musicChanger in audioManager.musicChangers:
				musicChanger.stop_music(fadeout_music_length)
		global.add_persistent(self)
	_active_door = false
	if sound != null and sound != "None":
		$AudioStreamPlayer.stream = load("res://Audio/Sound effects/" + sound)
		$AudioStreamPlayer.play()
	_fade_in()
	_current_state = 1
	set_process(true)
#	Ao oni code
#	var rand = RandomNumberGenerator.new()
#	rand.randomize()
#	var random = rand.randi_range(1, 1000)
#	if random == 1 and !OS.is_debug_build():
#		if _same_scene:
#			_special_guest(false)
#		else:
#			_special_guest()


func _set_flag():
	if flag_set != "":
		if globaldata.flags.has(flag_set):
			globaldata.flags[flag_set] = set_flag_state

#Ao oni spawner
func _special_guest(new_scene := true):
	var checkScene
	checkScene = global.currentScene
	if not checkScene.get_name() in ["Disclaimer", "Title screen", "SaveSelect", "Control", "Naming screen", "Introduction"]:
		var _special_guest = load("res://Nodes/Overworld/Enemies/AoOni.tscn").instance()
		if !new_scene:
			yield(self, "moved_player")
		checkScene.get_node("Objects").add_child(_special_guest)
