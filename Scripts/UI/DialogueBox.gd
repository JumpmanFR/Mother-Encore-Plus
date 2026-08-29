extends AbstractDialogueBox

signal done(result)

# node refs
onready var _name_label := $Dialoguebox/Namebox/ClipBox/Name
onready var _options_grid := $Dialoguebox/Options
onready var _camera := $Camera2D
onready var ActorChar := preload("res://Nodes/Reusables/actor.tscn")

var _actors := {}
var _item_not_given := false
var _options_count := 0
var _options := []
var _dialog_response := 0
var _can_input := true
var _set_respawn := false
var _dialogue_box_shown := false
var _name_box_shown := false
var _sub_menu_result # any type

var _queued_battle := false
var _post_battle_cutscenes := {}
var _battle_win_flag := ""

func _ready():
	_dialogue_box_node = $Dialoguebox
	_dialogue_label = $Dialoguebox/ClipBox/HBoxContainer/Dialogue
	_bullet_label = $Dialoguebox/ClipBox/HBoxContainer/DippinDots
	_cursor_down_sprite = $Dialoguebox/Cursor_Down

func start_from_id(dialogue_id: String, npc = null):
	var dialogue_path := "res://Data/Dialogue/%s.yaml" % dialogue_id
	if !File.new().file_exists(dialogue_path):
		return start_from_id("Reusable/error", npc)
	start_from_dict(YAMLParser.parse_file(dialogue_path), npc)

func start_from_dict(dialogue_dict: Dictionary, npc = null):
	global.in_cutscene = true
	uiManager.info_plates_hide()
	_dialog = dialogue_dict
	global.talker = npc
	_name_label.connect("item_rect_changed", self, "_set_nametag")
	Input.action_release("ui_cancel")
	Input.action_release("ui_accept")
	$Dialoguebox/Arrow.hide()
	_dialogue_label.visible_characters = 0
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_handle_phrase()

# Override
func _advance_printing(delta: float):
	._advance_printing(delta)
	if global.talker != null:
		if !_dialogue_label.visible_characters >= len(_get_no_br_dialog_content()):
			if _curr_phrase.has("text") and _curr_phrase["text"] != "":
				if _get_last_visible_char() == TextTools.CHAR_WAIT:
					global.talker.talking = false
				else:
					global.talker.talking = true
		else:
			if global.talker != null:
				global.talker.talking = false

func _print_new_line():
	_dialogue_label.bbcode_text += "\n"
	_bullet_label.bbcode_text += "\n"

func _finish_phrase():
	_finished = true
	_add_dialog_options()
	if $WaitTimer.time_left == 0 and _can_input:
		_cursor_down_sprite.show()
		if _auto_advance:
			_next_phrase()

# Override
func _action_press(btn_next := false, btn_cancel := false):
	if !$AnimationPlayer.is_playing() and $WaitTimer.time_left == 0 and _can_input:
		if !_finished and !_stopped:
			if btn_cancel:
				_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_B
			else:
				_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_A
		elif btn_next:
			if _finished:
				if _curr_phrase.has("options"):
					var option = _options[$Dialoguebox/Arrow.cursor_index]
					if btn_cancel and _curr_phrase["options"].has("cancel"):
						option = "cancel"
					if _curr_phrase["options"][option]:
						_phrase_num = _curr_phrase["options"][option]
					else:
						_end_dialogue()
					$Dialoguebox/Arrow.hide()
					for i in _options_grid.get_children():
						i.hide()
					_options_count = 0
					_options.clear()
					_clear_dialogue()
					_handle_phrase()
					$InputSound.play()
				else:
					_next_phrase(true)
			elif _stopped:
				_stopped = false
				$InputSound.play()

# Override
func _handle_phrase() -> void:
	$WaitTimer.stop()
	_can_input = true
	_auto_advance = false
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1
	_t = 0
	
	$Dialoguebox/Arrow.cursor_index = 0
	_curr_phrase = _dialog.get(str(_phrase_num), {})
	
	_options_count = 0
	_finished = false
	
	if _phrase_num == "0":
		_dialogue_label.remove_line(1)
		_bullet_label.remove_line(1)
	
	
	#Give Item (this has to be handled before the text, in case the [ItemReceiver] is mentionned in dialogue)
	if _curr_phrase.has("cleardialog"):
		if _curr_phrase["cleardialog"]:
			_clear_dialogue()
	
	
	if _curr_phrase.has("item"):
		var item_data = globaldata.get_item_data(_curr_phrase["item"])
		_item_not_given = true #check if the item is given or not, if the item is not given, it will go to "inv_full" instead of "goto"
		if Inventory.has_inventory_space():
			_item_not_given = false
		if item_data.get("keyitem", false):
			_item_not_given = false
		global.item = Inventory.add_item_available(_curr_phrase["item"])
	
	
	# Set Dialogue
	if _curr_phrase.has("text"):
		_curr_phrase["text"] = TextTools.add_line_breaks(TextTools.replace_text(_curr_phrase["text"]), _dialogue_label)

		_show_box(true, _curr_phrase.get("boxsound", true))
		
		_print_dialogue_segment(true)
	elif _curr_phrase.has("wait") or _curr_phrase.has("autowait"):
		_show_box(false, _curr_phrase.get("boxsound", true))
	
	
	
	if _curr_phrase.has("changescene"):
		_change_scene(_curr_phrase["changescene"])
		yield(global, "scene_changed")
	
	
		
		
		
		
		
		
		
		
		
	if _curr_phrase.has("actors"):
		var actor_paths = _curr_phrase["actors"]

		for actor_name in actor_paths:
			var npc := _actor_strings_to_node(actor_paths[actor_name])
			var new_actor := ActorChar.instance()
			if !npc:
				print("Could not create actor %s: %s" % [actor_name, actor_paths[actor_name]])
			else:
				new_actor.init(npc, true)
				npc.get_parent().call_deferred("add_child_below_node", npc, new_actor)
				yield(new_actor, "actor_ready")
				new_actor.make_persistent()
				_actors[actor_name] = new_actor
		yield(get_tree(), "idle_frame")
	
	
	
	
	
	
	if _curr_phrase.has("autowait"):
		$WaitTimer.start(_curr_phrase["autowait"])
		_can_input = false
		_auto_advance = true
	else:
		if _curr_phrase.has("wait"):
			$WaitTimer.start(_curr_phrase["wait"])
		
		if _curr_phrase.has("caninput"):
			_can_input = _curr_phrase["caninput"]
		else:
			_can_input = true
		
		if _curr_phrase.has("autoadvance"):
			_auto_advance = _curr_phrase["autoadvance"]
		else:
			_auto_advance = false
		
		
	
	
	
	
	if _curr_phrase.has("showbox"):
		_show_box(_curr_phrase["showbox"], _curr_phrase.get("boxsound", true))
	
	# Parse Commands
	if _curr_phrase.has("commands"):
		for command in _curr_phrase["commands"]:
			var expression = Expression.new()
			expression.parse(command)
			var result = expression.execute([], self)
			print(result)  # 20
			
	
	
	
		
		
	
		
		
	if _curr_phrase.has("objectsfunction"):
		var objects = _curr_phrase["objectsfunction"]
		for i in objects:
			var object = global.currentScene.get_node_or_null(i)
			var func_name = objects[i].get_slice("(", 0)
			
			if object != null and object.has_method(func_name):
				
				
				
				if (objects[i].ends_with(")")):
					var args_str = objects[i].get_slice("(", 1).trim_suffix(")")
					var args = args_str.split(",")
					
					
					if args_str != "":
						object.callv(func_name, args)
					else:
						object.call_deferred(func_name)
				
				
				else:
					object.call_deferred(objects[i])
	
	
		
			
			
			
			
			
			
	if _curr_phrase.has("tweenpos"):
		
		for i in _curr_phrase["tweenpos"]:
			var object = global.currentScene.get_node_or_null(i)
			var is_global_position_type = _curr_phrase["tweenpos"][i].get(["globalposition"], true)
			var position_type = "global_position" if is_global_position_type else "position"
			var initial_value = object.global_position if is_global_position_type else object.get_position_in_parent()
			var x = _curr_phrase["tweenpos"][i].get("x", initial_value.x)
			var y = _curr_phrase["tweenpos"][i].get("y", initial_value.y)
			var new_value = Vector2(x, y)
			var duration = _curr_phrase["tweenpos"][i].get("duration", 1)
			var delay = _curr_phrase["tweenpos"][i].get("delay", 0)
			var ease_type = _curr_phrase["tweenpos"][i].get("ease", "linear")
			var trans = Tween.TRANS_LINEAR if ease_type == "linear" else Tween.TRANS_QUART
			var ease_match = {
				"linear": Tween.EASE_IN, 
				"in": Tween.EASE_IN, 
				"out": Tween.EASE_OUT, 
				"inout": Tween.EASE_IN_OUT, 
				"outin": Tween.EASE_OUT_IN
			}
			var easing = ease_match[ease_type]
			
			var tween = create_tween()
			tween.tween_property(object, position_type, 
				new_value, duration)\
				.set_trans(trans).set_ease(easing).set_delay(delay)
	
	
		
		
	if _curr_phrase.has("objectsteleport"):
		for i in _curr_phrase["objectsteleport"]:
			var object = global.currentScene.get_node_or_null(i)
			var is_global_position_type = _curr_phrase["objectsteleport"][i].get(["globalposition"], true)
			var position_type = "global_position" if is_global_position_type else "position"
			var initial_value = object.global_position if is_global_position_type else object.get_position_in_parent()
			var x = _curr_phrase["objectsteleport"][i].get("x", initial_value.x)
			var y = _curr_phrase["objectsteleport"][i].get("y", initial_value.y)
			var new_value = Vector2(x, y)
			object.global_position = new_value
	
	
	if _curr_phrase.has("ovbattlemusic"):
		audioManager.overworldBattleMusic = _curr_phrase["ovbattlemusic"]
	
	if _curr_phrase.has("musicloop"):
		var music = ""
		if _curr_phrase.has("music"):
			music = _curr_phrase["music"]
		if audioManager.get_audio_player(0).playing:
			audioManager.add_audio_player()
		audioManager.play_music_on_latest_player(music, _curr_phrase["musicloop"])
	elif _curr_phrase.has("music"):
		if _curr_phrase["music"] != "":
			if audioManager.get_audio_player(0).playing:
				audioManager.add_audio_player()
			audioManager.play_music_on_latest_player(_curr_phrase["music"], "")
		else:
			audioManager.music_fadeout(0, 2)
	
	if _curr_phrase.has("musicvolume"):
		yield(get_tree(), "idle_frame")
		audioManager.music_fadeto(0, _curr_phrase["musicvolume"])
	
	if _curr_phrase.get("sound", null):
		if !_curr_phrase["sound"].begins_with("res://"):
			_curr_phrase["sound"] = "res://Audio/Sound effects/text/" + _curr_phrase["sound"]
		$AudioStreamPlayer.stream = load(_curr_phrase["sound"] +".mp3")
	else:
		$AudioStreamPlayer.stream = null
	
	if _curr_phrase.has("soundeffect"):
		if !_curr_phrase["soundeffect"].begins_with("res://"):
			_curr_phrase["soundeffect"] = "res://Audio/Sound effects/" + _curr_phrase["soundeffect"]
		audioManager.play_sfx(load(_curr_phrase["soundeffect"]), "dialogBoxSound")
	
	if _curr_phrase.has("font"):
		if _curr_phrase["font"] == "EBZ" or _curr_phrase["font"] == "Saturn":
			_dialogue_label.add_font_override("normal_font",load("res://Fonts/saturn.tres"))
			_bullet_label.add_font_override("normal_font",load("res://Fonts/saturn.tres"))
	
	var party_changed := false
	
	
	#add a party member
	if _curr_phrase.has("setpartymembers"):
		set_party_members(_curr_phrase["setpartymembers"])
		party_changed = true
	
	
	#add a npc party member
	if _curr_phrase.has("setpartynpcs"):
		set_party_npcs(_curr_phrase["setpartynpcs"])
		party_changed = true
	
	if party_changed:
		global.create_party_followers()
	
	#change the npc an actor replaces
	if _curr_phrase.has("changereplaced"):
		_add_partymember_actors(_curr_phrase["changereplaced"])
		for i in _curr_phrase["changereplaced"]:
			if _actors.has(i):
				var replacement := _actor_strings_to_node(_curr_phrase["changereplaced"][i])
				if replacement in global.partyObjects:
					replacement.hide()
				_actors[i].change_replaced(replacement)
	
	
	
	if _curr_phrase.has("mutetalker"):
		if global.talker != null:
			global.talker.mute = _curr_phrase["mutetalker"]
	
	#Change talker
	if _curr_phrase.has("talker"):
		if _curr_phrase["talker"] and _actors.has(_curr_phrase["talker"]):
			if global.talker: global.talker.talking = false
			global.talker = _actors[_curr_phrase["talker"]]
		else:
			if global.talker: global.talker.talking = false
			global.talker = null
	
	
	#teleports an actor to a spot instantly
	if _curr_phrase.has("teleportactors"):
		for i in _curr_phrase["teleportactors"]:
			if _actors.has(i):
				_actors[i].global_position = Vector2(_curr_phrase["teleportactors"][i]["x"], _curr_phrase["teleportactors"][i]["y"])
	
	
		
			
	if _curr_phrase.has("actorsvisible"):
		for i in _curr_phrase["actorsvisible"]:
			if _actors.has(i):
				_actors[i].visible = _curr_phrase["actorsvisible"][i]
	
	
	
		
		
		
	
	#teleports the party to a location on the map
	if _curr_phrase.has("teleportparty"):
		var new_pos = Vector2.ZERO
		var disappear = true
		if _curr_phrase["teleportparty"].has("x"):
			new_pos.x = _curr_phrase["teleportparty"]["x"]
		if _curr_phrase["teleportparty"].has("y"):
			new_pos.y = _curr_phrase["teleportparty"]["y"]
		if _curr_phrase["teleportparty"].has("disappear"):
			disappear = _curr_phrase["teleportparty"]["disappear"]
		global.get_player().position = new_pos
		if global.partySpace.size() > 1:
			for i in global.partySpace.size():
				global.partySpace.push_front(global.get_player().position)
				global.partySpace.pop_back()
			for i in range(1, global.partyObjects.size()):
				global.partyObjects[i].position = global.get_player().position
				if disappear:
					global.partyObjects[i].reinit()
					global.partyObjects[i].disappear()
	
	#For setting multiple actor's 
	if _curr_phrase.has("actorsdir"):
		for i in _curr_phrase["actorsdir"]:
			if _actors.has(i):
				var turner = _actors[i]
				var direction = Vector2.ZERO
				if _curr_phrase["actorsdir"][i].has("x"):
					direction.x = _curr_phrase["actorsdir"][i]["x"]
				if _curr_phrase["actorsdir"][i].has("y"):
					direction.y = _curr_phrase["actorsdir"][i]["y"]
				turner.set_direction(direction)
	
	
		
	if _curr_phrase.has("stopactorsloop"):
		for i in _curr_phrase["stopactorsloop"]:
			if _actors.has(i):
				_actors[i].stop_loop()
	
	
	
	#set if the actor's direction is set to their walk direction
	if _curr_phrase.has("actorsblend"):
		for i in _curr_phrase["actorsblend"]:
			if _actors.has(i):
				_actors[i].set_blending(_curr_phrase["actorsblend"][i])
	
	#set an actor's shadow
	if _curr_phrase.has("actorsshadow"):
		for i in _curr_phrase["actorsshadow"]:
			if _actors.has(i):
				_actors[i].set_shadow(_curr_phrase["actorsshadow"][i])
	
	
	
	#actor movements
	if _curr_phrase.has("actorsmove"):
		for i in _curr_phrase["actorsmove"]:
			if _actors.has(i):
				var character = _curr_phrase["actorsmove"][i]
				var movingActor = _actors[i]
				var move_queue := []
				var animation := ""
				var speed: float = 64.0
				var type := "0"
				var moonwalk := false
				var loop := false
				var queue := false
				if character.has("movement"):
					for j in character["movement"]:
						var action
						
						if j.has("wait"):
							action = Actor.WaitAction.new(j["wait"])
						
						elif j.has("turnto"):
							var dir = Vector2.ZERO
							if j["turnto"].has("actor"):
								dir = movingActor.position.direction_to(_actors[j["turnto"]["actor"]].position)
							if j["turnto"].has("x"):
								dir.x = j["turnto"]["x"]
							if j["turnto"].has("y"):
								dir.y = j["turnto"]["y"]
							var turnSpeed = j["turnto"].get("speed", 0.05)
							action = Actor.TurnToAction.new(dir, turnSpeed)
						
						elif j.has("setdir"):
							var dir = Vector2.ZERO
							if j["setdir"].has("actor"):
								dir = movingActor.position.direction_to(_actors[j["setdir"]["actor"]].position)
							if j["setdir"].has("x"):
								dir.x = j["setdir"]["x"]
							if j["setdir"].has("y"):
								dir.y = j["setdir"]["y"]
							action = Actor.SetDirAction.new(dir)
						
						elif j.get("turnaround", false):
							action = Actor.TurnAroundAction.new()
						
						elif j.has("spin"):
							var dir = Vector2.ZERO
							var enabled = j["spin"].get("enabled", true)
							var spinSpeed = j["spin"].get("speed", 0.05)
							var anticlockwise = j["spin"].get("anticlockwise", false)
							action = Actor.SpinAction.new(enabled, spinSpeed, anticlockwise)
						
						elif j.has("shake"):
							var offset = Vector2(j["shake"].get("x", 0), j["shake"].get("y", 0))
							var length = j["shake"].get("length", 1.0)
							var async = j["shake"].get("async", false)
							action = Actor.ShakeAction.new(offset, length, async)
						
						elif j.has("jump"):
							var height = j["jump"].get("height", 8)
							var length = j["jump"].get("length", 0.2)
							var times = j["jump"].get("times", 1)
							var shadow = j["jump"].get("shadow", true)
							var crouch = j["jump"].get("crouch", false)
							var async = j["jump"].get("async", false)
							action = Actor.JumpAction.new(height, length, times, shadow, crouch, async)
						
						elif j.has("playanim"):
							var anim_speed = j["playanim"].get("speed", 1.0)
							var anim_type = j["playanim"].get("type", 0)
							var newidle = j["playanim"].get("newidle", true)
							var async = j["playanim"].get("async", true if anim_type == 0 else false)
							action = Actor.AnimAction.new(j["playanim"]["anim"], anim_speed, anim_type, newidle, async)
						
						elif j.has("visible"):
							action = Actor.VisibilityAction.new(j["visible"])
						
						elif j.has("emote"):
							action = Actor.EmoteAction.new(j["emote"])
						
						elif j.has("playsound"):
							action = Actor.SoundEffectAction.new(j["playsound"])
						
						elif j.has("blend"):
							action = Actor.BlendAction.new(j["blend"])
						
						elif j.has("shadow"):
							action = Actor.ShadowAction.new(j["shadow"])
						
						elif j.has("moonwalk"):
							action = Actor.MoonwalkAction.new(j["moonwalk"])
						
						elif j.has("movespeed"):
							action = Actor.MoveSpeedAction.new(j["movespeed"])
						
						elif j.has("animspeed"):
							action = Actor.AnimSpeedAction.new(j["animspeed"])
						
						elif j.has("teleport"):
							var pos = movingActor.global_position
							if j["teleport"].has("x"):
								pos.x = j["teleport"]["x"]
							if j["teleport"].has("y"):
								pos.y = j["teleport"]["y"]
							action = Actor.TeleportAction.new(pos)
						
						else:
							var vector2 := Vector2(j["x"], j["y"])
							action = Actor.MoveAction.new(vector2)
						
						move_queue.append(action)
				if character.has("animation"):
					animation = character["animation"]
				if character.has("speed"):
					speed = character["speed"]
				if character.has("type"):
					type = character["type"]
				if character.has("moonwalk"):
					moonwalk = character["moonwalk"]
				if character.has("loop"):
					loop = character["loop"]
				if character.has("queue"):
					queue = character["queue"]
				movingActor.move_queue(move_queue, animation, speed, type, moonwalk, loop, queue)
	
	
		
			
			
			
			
			
	if _curr_phrase.has("actorsturn"):
		for i in _curr_phrase["actorsturn"]:
			if _actors.has(i):
				var turner = _actors[i]
				var direction = Vector2.ZERO
				var speed = 0.08
				var queue = false
				if _curr_phrase["actorsturn"][i].has("actor"):
					direction = turner.position.direction_to(_actors[_curr_phrase["actorsturn"][i]["actor"]].position)
				if _curr_phrase["actorsturn"][i].has("x"):
					direction.x = _curr_phrase["actorsturn"][i]["x"]
				if _curr_phrase["actorsturn"][i].has("y"):
					direction.y = _curr_phrase["actorsturn"][i]["y"]
				if _curr_phrase["actorsturn"][i].has("speed"):
					speed = _curr_phrase["actorsturn"][i]["speed"]
				if _curr_phrase["actorsturn"][i].has("queue"):
					queue = _curr_phrase["actorsturn"][i]["queue"]
				turner.turn_to(direction, speed, queue)
	
	
		
			
			
			
			
	if _curr_phrase.has("actorsshake"):
		for i in _curr_phrase["actorsshake"]:
			if _actors.has(i):
				var shaked = _actors[i]
				var length = 1.0
				var magnitude = Vector2.ZERO
				var queue = false
				if _curr_phrase["actorsshake"][i].has("x"):
					magnitude.x = _curr_phrase["actorsshake"][i]["x"]
				if _curr_phrase["actorsshake"][i].has("y"):
					magnitude.y = _curr_phrase["actorsshake"][i]["y"]
				if _curr_phrase["actorsshake"][i].has("length"):
					length = _curr_phrase["actorsshake"][i]["length"]
				if _curr_phrase["actorsshake"][i].has("queue"):
					queue = _curr_phrase["actorsshake"][i]["queue"]
				shaked.shake(magnitude, length, queue)
	
	
		
			
			
			
			
			
			
	if _curr_phrase.has("actorsjump"):
		for i in _curr_phrase["actorsjump"]:
			if _actors.has(i):
				var jumper = _actors[i]
				var height = 8
				var speed = 0.2
				var times = 1
				var queue = false
				var crouch = false
				var shadow = true
				if _curr_phrase["actorsjump"][i].has("height"):
					height = _curr_phrase["actorsjump"][i]["height"]
				if _curr_phrase["actorsjump"][i].has("speed"):
					speed = _curr_phrase["actorsjump"][i]["speed"]
				if _curr_phrase["actorsjump"][i].has("length"):
					speed = _curr_phrase["actorsjump"][i]["length"]
				if _curr_phrase["actorsjump"][i].has("times"):
					times = _curr_phrase["actorsjump"][i]["times"]
				if _curr_phrase["actorsjump"][i].has("queue"):
					queue = _curr_phrase["actorsjump"][i]["queue"]
				if _curr_phrase["actorsjump"][i].has("shadow"):
					shadow = _curr_phrase["actorsjump"][i]["crouch"]
				if _curr_phrase["actorsjump"][i].has("crouch"):
					crouch = _curr_phrase["actorsjump"][i]["crouch"]
				jumper.jump(height, speed, times, queue, shadow, crouch)
	
	
	
		
			
			
			
			
			
	if _curr_phrase.has("actorsanim"):
		for i in _curr_phrase["actorsanim"]:
			if _actors.has(i):
				var animated = _actors[i]
				var speed := 1.0
				var queue := false
				var type := 0
				var newidle := false
				if _curr_phrase["actorsanim"][i].has("speed"):
					speed = _curr_phrase["actorsanim"][i]["speed"]
				if _curr_phrase["actorsanim"][i].has("queue"):
					queue = _curr_phrase["actorsanim"][i]["queue"]
				if _curr_phrase["actorsanim"][i].has("type"):
					type = _curr_phrase["actorsanim"][i]["type"]
				if _curr_phrase["actorsanim"][i].has("newidle"):
					newidle = _curr_phrase["actorsanim"][i]["newidle"]
				animated.play_anim(_curr_phrase["actorsanim"][i]["anim"], speed, queue, type, newidle)
	
	
		
	if _curr_phrase.has("eraseactors"):
		for i in _curr_phrase["eraseactors"]:
			if _curr_phrase["eraseactors"][i] == true:
				if global.talker == _actors[i]:
					global.talker = null
				_actors[i].erase()
				_actors.erase(i)
	
	
		
	#Make the player emote
	if _curr_phrase.has("playeremote"):
		global.get_player().emotes.animaPlayer.play(_curr_phrase["playeremote"])
	
	#A simple way of getting the talker to emote
	if _curr_phrase.has("talkeremote"):
		if global.talker != null:
			global.talker.emotes.animaPlayer.play(_curr_phrase["talkeremote"])
	
	#Make specific actor play an emote
	if _curr_phrase.has("actorsemote"):
		for i in _curr_phrase["actorsemote"]:
			if _actors.has(i):
				var emoter = _actors[i]
				emoter.emotes.animaPlayer.play(_curr_phrase["actorsemote"][i])
	
	
	#Shake camera
	if _curr_phrase.has("shakecam"):
		var size = str(_curr_phrase["shakecam"].get(["size"], "small"))
		var length = 0.2
		var direction = Vector2.RIGHT
		if _curr_phrase["shakecam"].has("length"):
			length = _curr_phrase["shakecam"]["length"]
		if _curr_phrase["shakecam"].has("x"):
			direction.x = _curr_phrase["shakecam"]["x"]
		if _curr_phrase["shakecam"].has("y"):
			direction.y = _curr_phrase["shakecam"]["y"]
		match size:
			"small":
				global.start_joy_vibration(0, 0.4, 0.3, length)
				global.currentCamera.shake_camera(4, length, direction)
			"medium":
				global.start_joy_vibration(0, 0.5, 0.6, length)
				global.currentCamera.shake_camera(6, length, direction)
			"big":
				global.start_joy_vibration(0, 0.7, 0.8, length)
				global.currentCamera.shake_camera(8, length, direction)
	
	#Set current camera
	if _curr_phrase.has("changecam"):
		if !_curr_phrase["changecam"]:
			_camera.set_current()
		elif _actors.has(_curr_phrase["changecam"]):
			_actors[_curr_phrase["changecam"]].camera.set_current()
		yield(get_tree(), "idle_frame")
	
	
	
	#Move camera to a position on the map. 
	#You can set it to an actor to move the camera to the actor's position
	#Or you can set it to a coordinate on the map with "x" and "y". If one of them isn't there, it'll just default to the currentCamera's x or y
	if _curr_phrase.has("movecam"):
		var cam_pos = global.currentCamera.global_position
		var time = 1.0
		if _curr_phrase["movecam"].has("actor"): #moves camera to actor
			if _curr_phrase["movecam"]["actor"] == "parent":
				cam_pos = global.currentCamera.get_parent().global_position
			elif _actors.has(_curr_phrase["movecam"]["actor"]):
				
				cam_pos = _actors[_curr_phrase["movecam"]["actor"]].global_position
		if _curr_phrase["movecam"].has("x"):
			cam_pos.x = _curr_phrase["movecam"]["x"]
		if _curr_phrase["movecam"].has("y"):
			cam_pos.y = _curr_phrase["movecam"]["y"]
		if _curr_phrase["movecam"].has("length"):
			time = _curr_phrase["movecam"]["length"]
		global.currentCamera.move_camera(cam_pos, time)
	
	#Return camera to parent. "returncam" is equal to the time it takes for the camera to go back to the original position
	if _curr_phrase.has("returncam"):
		global.currentCamera.return_camera(_curr_phrase["returncam"])
	
	#make fade focus on a position or actor
	if _curr_phrase.has("fadefocus"):
		uiManager.get_fade().focus_object(_actors[_curr_phrase["fadefocus"]])
	
	#Fade in
	if _curr_phrase.has("fadein"):
		var color = Color.black
		var speed = 1.0
		if _curr_phrase["fadein"].has("speed"):
			speed = _curr_phrase["fadein"]["speed"]
		if _curr_phrase["fadein"].has("color"):
			color = Color(_curr_phrase["fadein"]["color"])
		uiManager.get_fade().fade_in(_curr_phrase["fadein"]["anim"],color, speed)
	
	#Fade out
	if _curr_phrase.has("fadeout"):
		var color = Color.black
		var speed = 1
		if _curr_phrase["fadeout"].has("speed"):
			speed = _curr_phrase["fadeout"]["speed"]
		if _curr_phrase["fadeout"].has("color"):
			color = Color(_curr_phrase["fadeout"]["color"])
		uiManager.get_fade().fade_out(_curr_phrase["fadeout"]["anim"],color, speed)
	
	#Set fade cut
	if _curr_phrase.has("fadesize"):
		var speed = _curr_phrase["fadesize"].get("speed", 1.0)
		
		uiManager.get_fade().set_cut(_curr_phrase["fadesize"]["size"])
	
	#make the fade spin, only works if it's a circle fade.
	if _curr_phrase.has("fadespin"):
		var enabled = _curr_phrase["fadespin"].get("enabled", true)
		var speed = _curr_phrase["fadespin"].get("speed", 1.0)
		uiManager.get_fade().set_spin(enabled, speed)
	
	
	
	
	#disable/enable telepathy effect 
	#telepathyeffect: null (disable telepathy)
	#telepathyeffect: actorName (enable telepathy and focus towards actor)
	if _curr_phrase.has("telepathyeffect"):
		if _curr_phrase["telepathyeffect"] == null:
			uiManager.set_telepathy_effect(false)
		else:
			uiManager.set_telepathy_effect(true, _actors[_curr_phrase["telepathyeffect"]])
	
	#Enable flags
	if _curr_phrase.has("setflags"):
		_change_flags(_curr_phrase["setflags"], true)

	#Disable flags
	if _curr_phrase.has("unsetflags"):
		_change_flags(_curr_phrase["unsetflags"], false)
	
	#set respawn point at the end of the cutscene
	if _curr_phrase.has("setrespawn"):
		_set_respawn = _curr_phrase["setrespawn"]
	
	#set respawn point at the end of the cutscene
	if _curr_phrase.has("name") and _curr_phrase.has("text"):
		_curr_phrase["name"] = TextTools.replace_text(_curr_phrase["name"])
		var old_name = _name_label.text
		_name_label.text = str(_curr_phrase["name"])
		if !_name_box_shown:
			$NameAnim.play("Open")
			_name_box_shown = true
			if !_curr_phrase.has("cleardialog"):
				_clear_dialogue()
				_print_dialogue_segment(true)
		
		elif old_name != _curr_phrase["name"]:
			if _phrase_num != "0":
				if !_curr_phrase.has("cleardialog"):
					_clear_dialogue()
					_print_dialogue_segment(true)
	elif ( not _curr_phrase.has("name") and !(_curr_phrase.has("wait") and _curr_phrase.has("autoadvance")) and !_curr_phrase.has("autowait")) or not _dialogue_box_shown:
		var old_name = _name_label.text
		_name_label.text = ""
		if _name_box_shown:
			$NameAnim.play("Close")
			_name_box_shown = false
		if old_name != _name_label.text and _phrase_num != "0":
			if !_curr_phrase.has("cleardialog"):
				_clear_dialogue()
			if _curr_phrase.has("text"):
				_print_dialogue_segment(true)
	
	#Save game
	if _curr_phrase.has("save"):
		uiManager.open_save(SaveSelect.Type.SAVE, funcref(self, "_try_resume_dialogue"))
	
	#Toggle cashBox
	if _curr_phrase.has("cash"):
		if _curr_phrase["cash"] == false:
			uiManager.get_cash_box().close()
		else:
			uiManager.get_cash_box().open()
	#Give/Remove Money
	if _curr_phrase.has("givecash"):
		var cash = _curr_phrase["givecash"]
		if cash is String:
			match cash:
				"+all":
					cash = globaldata.cash
				"-all":
					cash = - globaldata.cash
				"+half":
					cash = int(globaldata.cash/2)
				"-half":
					cash = - int(globaldata.cash/2)
				_:
					cash = int(cash)
		globaldata.cash += cash
		uiManager.get_cash_box().update()
	
	
		
		
	if _curr_phrase.has("cure"):
		var char_value := str(_curr_phrase["cure"]["character"])
		var status := str(_curr_phrase["cure"]["status"])
		for party_mem in _get_party_mem_from_dict(char_value):
			if status != "all":
				party_mem.remove_status(status)
				if status == Status.AILMENT_UNCONSCIOUS and party_mem.get_hp() <= 0:
					party_mem.set_hp(1)
			else:
				party_mem.remove_all_statuses()
				if party_mem.get_hp() <= 0:
					party_mem.set_hp(1)
		
		for obj in global.partyObjects:
			obj.spritesheet()
	
	
		
		
		
		
	if _curr_phrase.has("givestatus"):
		for character in _curr_phrase["givestatus"]:
			var character_name = character
			var status = str(_curr_phrase["givestatus"][character])
			if character == "leader":
				character_name = global.party[0].get_name()
			globaldata.characters[character_name].add_status(status)
	
	
	
	
	
	#Heal Party Members
	if _curr_phrase.has("heal"):
		var char_value := str(_curr_phrase["heal"])
		for party_mem in _get_party_mem_from_dict(char_value):
			if !party_mem.is_unconscious():
				party_mem.set_hp(party_mem.get_stat(Character.MAXHP))

	
	
	
	
	#Restore PP
	if _curr_phrase.has("restorepp"):
		var char_value := str(_curr_phrase["restorepp"])
		for party_mem in _get_party_mem_from_dict(char_value):
			party_mem.set_pp(party_mem.get_stat(Character.MAXPP))
	
	
		
		
		
		
	if _curr_phrase.has("resetpartymembers"):
		for character in _curr_phrase["resetpartymembers"]:
			var character_name = character
			if character == "leader":
				character_name = global.party[0].get_name()
			if _curr_phrase["resetpartymembers"][character]:
				globaldata.characters[character_name].reset(false, true)
	
	
		
		
		
		
	if _curr_phrase.has("setpartymemberlevel"):
		for character in _curr_phrase["setpartymemberlevel"]:
			var character_name = character
			var level = _curr_phrase["setpartymemberlevel"][character]
			if character == "leader":
				character_name = global.party[0].get_name()
			globaldata.characters[character_name].set_level(level)

	
	
	
	if _curr_phrase.has("setpartyleader"):
		global.set_party_leader(_curr_phrase["setpartyleader"])
	
	
	
	
	if _curr_phrase.has("open_shop"):
		uiManager.open_shop(_curr_phrase.open_shop, true, funcref(self, "_try_resume_dialogue"))
	
	if _curr_phrase.has("open_nosell_shop"):
		uiManager.open_shop(_curr_phrase.open_nosell_shop, false, funcref(self, "_try_resume_dialogue"))
	
	if _curr_phrase.get("open_storage", false):
		uiManager.open_storage(false, funcref(self, "_try_resume_dialogue"))
	
	if _curr_phrase.get("use_atm", false):
		uiManager.open_atm(funcref(self, "_try_resume_dialogue"))
	
	if _curr_phrase.has("keyboard"):
		uiManager.open_keyboard(_curr_phrase["keyboard"], funcref(self, "_try_resume_dialogue"))
	
	if _curr_phrase.get("open_ocarina"):
		uiManager.open_ocarina_screen(funcref(self, "_try_resume_dialogue"))
		uiManager.toggle_black_bars(false)
	
	
	
	




	#Take Item
	if _curr_phrase.has("removeitem"):
		if Inventory.party_has_item(_curr_phrase["removeitem"]):
			Inventory.remove_item_from_party(_curr_phrase["removeitem"])
	
	
	if _curr_phrase.has("addstorageitem"):
		globaldata.storage.add_item_by_name(_curr_phrase["addstorageitem"])
	
	
	
	if _curr_phrase.has("transformitem"):
		Inventory.transform_items_for_all(_curr_phrase["transformitem"])

	if _curr_phrase.has("repairitem"):
		var char_value = _curr_phrase["repairitem"]
		for inv_holder in _get_party_mem_from_dict(char_value, true):
			var new_item: Item = inv_holder.inv.repair_one_item()
			if new_item != null:
				global.item = new_item
				break
	
	
		
			
				
				
		
			
		
		
		
		
	if _curr_phrase.has("startbattle"):
		var battle = _curr_phrase["startbattle"]
		if battle.has("battlers"):
			var enemies = battle["battlers"]
			for dict in enemies:
				for enemy in dict:
					var actor = dict[enemy]
					var battler = Enemy.new(enemy)
					var actor_node: Actor
					print("enemy " + enemy)
					print("actor " + actor)
					if actor != null:
						if actor == "talker":
							actor_node = global.talker
						else:
							actor_node = _actors[actor]
						actor_node.add_battle(battler)
					else:
						uiManager.add_on_screen_enemy(battler, null)
		
		if battle.has("actorskeep"):
			for actor in battle["actorskeep"]:
				_actors[actor].keepAfterBattle = battle["actorskeep"][actor]
		
		# Play cutscene after winning (1), fleeing (0) or losing (-1) after the battle
		# Can’t use BattleSystem.Result enum because of those stupid cyclic dependencies
		if battle.has("wincutscene"):
			_post_battle_cutscenes[1] = battle["wincutscene"]
		if battle.has("fleecutscene"):
			_post_battle_cutscenes[0] = battle["fleecutscene"]
		if battle.has("losecutscene"):
			_post_battle_cutscenes[ - 1] = battle["losecutscene"]
		
		if battle.has("winflag"):
			_battle_win_flag = battle["winflag"]
		
		_queued_battle = true
		print("queuing battle")
	
	
		
	if _curr_phrase.has("learnskills"):
		var skill_per_members = _curr_phrase["learnskills"]
		for member in skill_per_members:
			var skill = skill_per_members[member]
			if skill == "all":
				for existing_skill in globaldata.get_all_battle_skills():
					globaldata.characters[member].add_skill(existing_skill)
			else:
				globaldata.characters[member].add_skill(skill)
	
	
	
	if !_curr_phrase.has("text") and !_curr_phrase.has("wait") and !_curr_phrase.has("autowait"):
		_next_phrase()

func _get_party_mem_from_dict(yaml_value: String, include_key_items := false) -> Array:
	var ret
	if yaml_value == "all":
		ret = global.party.duplicate()
	else:
		ret = [Inventory.get_inventory_holder(yaml_value)]
	if include_key_items:
		ret += [Inventory.get_inventory_holder(Inventory.INV_NAME_KEY)]
	return ret

func _add_dialog_options():
	# Parse Options
	if _curr_phrase.has("options"):
		for i in _options_grid.get_children():
			i.hide()
		_options.clear()
		_print_new_line()
		var optionNode = load("res://Nodes/Ui/DialogueOptions.tscn")
		_options_count = 0

		var visibleOptions = {}

		for i in _curr_phrase["options"]:
			var nickname = ""
			var canAppend = true
			if i == "chkninten" or i == "chklloyd" or i == "chkana" or i == "chkteddy" or i == "chkpippi":
				var actualName
				canAppend = false
				nickname = i.replace("chk", "")
				for member in global.party.size():
					if global.party[member].get_name() == nickname:
						nickname = global.party[member].get_nickname()
						canAppend = true
						break
			if nickname == "":
				nickname = i
			if canAppend and i != "cancel":
				# Bulding a dictionary with all the _options that will actually appear in the dialogue box
				visibleOptions[i] = nickname

		# Now we know the exact number of visible _options because they are stored inside visibleOptions
		_options_count = visibleOptions.size()

		if _options_count == 4:					# 2×2 layout if 4 _options
			_options_grid.columns = 2
		else:
			_options_grid.columns = 3
		if _options_count > 3:
			_print_new_line()

		# The nodes already exist, we’re just showing them
		# (it works better that way, especially the cursor positionning)
		var idx = 0
		for i in visibleOptions:
			var option = _options_grid.get_child(idx)
			var nickname = visibleOptions[i]
			option.text = nickname
			option.set_name(nickname)
			option.show()
			_options.append(i)
			idx += 1

		$Dialoguebox/Arrow.show()
		$Dialoguebox/Arrow.on = true
		$Dialoguebox/Arrow.set_cursor_from_index(0, false)
		_options_grid.show()
		_cursor_down_sprite.hide()
	else:
		$Dialoguebox/Arrow.hide()
		$Dialoguebox/Arrow.on = false
		_options_grid.hide()

func _try_resume_dialogue(result = 0):
	if _finished:
		_end_dialogue()
	else:
		_sub_menu_result = result
		uiManager.toggle_black_bars(true)
		_next_phrase()

# Override
func _end_dialogue():
	Input.action_release("ui_cancel")
	Input.action_release("ui_accept")
	_clear_dialogue()
	
	global.set_phone_location("")
	
	$AudioStreamPlayer.volume_db = -80
	_dialogue_label.hide()
	if is_instance_valid(global.talker) and global.talker != null:
		global.talker.stop_interaction()
	global.talker = null
	if _name_label.text != "":
		$NameAnim.play("Close")
	uiManager.get_cash_box().close()
	uiManager.set_telepathy_effect(false)
	
	if _actors.size() != 0:
		for i in _actors:
			if !_queued_battle:
				_actors[i].update_npcs()
			elif !_actors[i].drafted:
				_actors[i].update_npcs()
			else:
				_actors[i].unmake_persistent()
		
		#update partyMember path
		if global.partySpace.size() > 1:
			var partyMembers = global.partyObjects.duplicate()
			
			partyMembers.invert()
			for i in global.partySpace.size():
				global.partySpace.push_front(partyMembers[0].position)
				global.partySpace.pop_back()
			
			for i in partyMembers.size() - 1:
				var maxDist = round(max(abs(partyMembers[i].position.x-partyMembers[i + 1].position.x), abs(partyMembers[i].position.y-partyMembers[i + 1].position.y)))
				if maxDist > 0:
					for dist in maxDist + 1:
						global.partySpace.push_front(lerp(partyMembers[i].position, partyMembers[i+1].position.round(), (dist+1)/maxDist))
						global.partySpace.pop_back()
				
				partyMembers[i].set_physics_process(true)
				partyMembers[i].find_path()
				partyMembers[i].active = true
	
	uiManager.update_key_indicator()
	global.emit_signal("cutscene_ended")
	global.in_cutscene = false
	_phrase_num = "0"
	_close_dialog_box()
	emit_signal("done", _dialog_response)
	if _queued_battle:
		uiManager.start_battle(0, false, [], _post_battle_cutscenes, _battle_win_flag)
		if global.currentCamera.tween: global.currentCamera.tween.pause()
	else:
		global.currentCamera.return_camera(0.5)
		global.currentCamera.return_offset(0.5)
		if _set_respawn:
			global.set_respawn()

func _clear_dialogue():
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_dialogue_label.visible_characters = 0

# Override
func _next_phrase(with_sound := false):
	_dialog_response = _curr_phrase.get("set_response", _dialog_response)
	
	
	
		
		
			
		
		
		
		
		
		
			
		
		
		
			
			
		
			
			
		
		
		
	if _curr_phrase.has("if"):
		var all_ifs = _curr_phrase["if"]
		if !all_ifs is Array:
			all_ifs = [_curr_phrase["if"]]

		for curr_if in all_ifs:
			var condition := true
			for cond in curr_if:
				var is_actual_condition = !cond in ["or", "goto", "redirect"]
				if curr_if.has("or") and is_actual_condition:
					condition = true
				#Check if the player does or doesn't have enough inventory space
				if "hascash" in cond:
					if globaldata.cash < curr_if["hascash"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the player does or doesn't have enough inventory space
				if "invspace" in cond:
					if Inventory.has_inventory_space() != curr_if["invspace"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the player has a certain item
				if "hasitem" in cond:
					if !Inventory.party_has_item(curr_if[cond]):
						condition = false
						if !curr_if.has("or"):
							break
				#Check if an item is in storage
				if "hasinstorage" in cond:
					if !globaldata.storage.has_item(curr_if[cond]):
						condition = false
						if !curr_if.has("or"):
							break
				if "hasrepairableitem" in cond:
					var char_value = curr_if[cond]
					var item = null
					for inv_holder in _get_party_mem_from_dict(char_value, true):
						item = inv_holder.inv.find_repairable_item()
						if item:
							global.item = item
							break
					if !item:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the leader is a certain character
				if "leader" in cond:
					if global.party[0].get_name() != curr_if["leader"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the player has certain party members (including party NPCs)
				if "haspartymembers" in cond:
					var hasPartyMember = true
					for memberName in curr_if["haspartymembers"]:
						var hasMember = false
						var all_party = global.party + global.partyNpcs
						for member in all_party.size():
							if all_party[member].get_name() == memberName:
								hasMember = true
								if !curr_if.has("or"):
									break
						if hasMember != curr_if["haspartymembers"][memberName]:
							condition = false
							hasPartyMember = false
							if !curr_if.has("or"):
								break
					if !hasPartyMember:
						if !curr_if.has("or"):
							break
				if "iscolliding" in cond:
					if global.get_player().is_colliding() != curr_if["iscolliding"]:
						condition = false
						if !curr_if.has("or"):
							break
				if "submenuresult" in cond:
					if _sub_menu_result != curr_if["submenuresult"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the party has enough members
				if "partysize" in cond:
					condition = false
					match curr_if[cond]["symbol"]:
						">":
							if global.party.size() > curr_if[cond]["size"]:
								condition = true
						">=":
							if global.party.size() >= curr_if[cond]["size"]:
								condition = true
						"<":
							if global.party.size() < curr_if[cond]["size"]:
								condition = true
						"<=":
							if global.party.size() <= curr_if[cond]["size"]:
								condition = true
						"=":
							if global.party.size() == curr_if[cond]["size"]:
								condition = true
					if !condition:
						if !curr_if.has("or"):
							break
				#Check if character has status
				if "hasstatus" in cond:
					var has_status = true
					var status = curr_if[cond]["status"]
					var character = curr_if[cond]["character"]
					for member in global.party.size():
						if global.party[member].get_name() == character:
							if status != "":
								if !global.party[member].has_status(status.to_lower()):
									condition = false
									has_status = false
									break
							else:
								if global.party[member].get_status_ailments().size() != 0:
									condition = false
									has_status = false
									break
					if !has_status:
						if !curr_if.has("or"):
							break
							
				#Check if certain flags in globalData are true or false
				if "flags" in cond:
					var flag_correct = true
					for flagName in curr_if["flags"]:
						if globaldata.flags[flagName] != curr_if["flags"][flagName]:
							condition = false
							flag_correct = false
							if !curr_if.has("or"):
								break
					if !flag_correct:
						if !"or" in curr_if:
							break
				if curr_if.has("or") and is_actual_condition:
					if condition:
						break					

			if condition: #check if all of these are true to go to this "goto"
				_handle_gotos(curr_if, with_sound)
				return

	if _curr_phrase.has("redirect") or _curr_phrase.has("goto"):
		_handle_gotos(_curr_phrase, with_sound)
	else:
		_end_dialogue()

func _handle_gotos(phrase: Dictionary, with_sound := false):
	if phrase.has("redirect"):
		if with_sound:
			$InputSound.play()
		_phrase_num = "0"
		_dialog = YAMLParser.parse_file("res://Data/Dialogue/%s.yaml" % phrase["redirect"])
		_handle_phrase()
	elif phrase.has("goto"):
		if with_sound:
			$InputSound.play()
		_phrase_num = phrase["goto"]
		_handle_phrase()

func get_actors() -> Dictionary:
	return _actors

# Override
func _show_box(show: bool, sfx = true):
	if show and !_dialogue_box_shown:
		_dialogue_box_shown = true
		$AnimationPlayer.play("Open")
		if sfx:
			audioManager.play_sfx_by_name("menu_open", "menu_open")
		set_process_input(true)
		set_physics_process(true)
	if !show and _dialogue_box_shown:
		_dialogue_box_shown = false
		$AnimationPlayer.play("Close")
		if sfx:
			audioManager.play_sfx_by_name("menu_close", "menu_close")
		_clear_dialogue()
		set_process_input(false)
		set_physics_process(false)

func _set_nametag():
	var new_size = _name_label.rect_size.x + 20
	var old_size = $Dialoguebox/Namebox.rect_size.x 
	if new_size != old_size:
		create_tween().tween_property($Dialoguebox/Namebox, "rect_size", Vector2(new_size, 47), 0.2) \
				.from(Vector2(old_size, 47)).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	else:
		$Dialoguebox/Namebox.rect_size.x = _name_label.rect_size.x + 20

func _close_dialog_box():
	if $Dialoguebox.rect_position.y != 180:
		$AnimationPlayer.play("Close")
		audioManager.play_sfx_by_name("menu_close", "menu_close")
		yield($AnimationPlayer, "animation_finished")
	uiManager.remove_ui(self)
	
	#if !global.dialogue.empty():
	#	uiManager.open_dialogue_box()

func _on_WaitTimer_timeout():
	if _finished:
		_cursor_down_sprite.show()
	if _auto_advance:
		_next_phrase()

func _change_scene(targetScene):
	global.goto_scene("res://Maps/" + targetScene + ".tscn")
	
	var cam = global.currentCamera
	cam.limit_top = -10000000
	cam.limit_left = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000

func _actor_strings_to_node(actors_strings) -> Node2D:
	if !actors_strings is Array:
		actors_strings = [actors_strings]

	for actor_str in actors_strings:
		if actor_str == "leader" or actor_str == "player":
			return global.get_player()
		elif actor_str == "talker":
			return global.talker
		elif actor_str in globaldata.characters:
			var party = global.party + global.partyNpcs
			for i in global.partyObjects.size():
				if party[i].get_name() == str(actor_str):
					return global.partyObjects[i]
		else:
			var node = global.currentScene.get_node_or_null(str2var(actor_str))
			if node != null:
				return node
	return null

func _add_partymember_actors(actors):
	var present_party_members := {}
	var present_party_npcs := {}
	for actors_strings in actors:
		if typeof(actors_strings) != TYPE_ARRAY:
			actors_strings = [actors_strings]
		for actor_str in actors_strings:
			var actor_path = actors[actor_str]
			if actor_path in globaldata.characters:
				if globaldata.characters[actor_path].get_character_type() == Character.Type.PARTY_NPC:
					present_party_npcs[actor_path] = true
					break
				elif globaldata.characters[actor_path].get_character_type() == Character.Type.PARTY_MEMBER:
					present_party_members[actor_path] = true
					break
	set_party_members(present_party_members)
	set_party_npcs(present_party_npcs)
	global.create_party_followers()
	

func set_party_members(party_members: Dictionary):
	for i in party_members:
		if globaldata.characters.get(i) in global.party:
			if global.partyObjects.size() > 1 and !party_members[i]:
				global.party.erase(globaldata.characters.get(i))
		elif party_members[i]:
			global.party.append(globaldata.characters.get(i))
	

func set_party_npcs(party_npcs: Dictionary):
	for i in party_npcs:
		if globaldata.characters.get(i) in global.partyNpcs:
			if global.partyObjects.size() > 1 and !party_npcs[i]:
				global.partyNpcs.erase(globaldata.characters.get(i))
		elif party_npcs[i]:
			global.partyNpcs.append(globaldata.characters.get(i))

func _change_flags(flags, value):
	if !flags is Array:
		flags = [flags]
	for flag in flags:
		globaldata.set_flag(flag, value)
