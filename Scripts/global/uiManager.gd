extends Node

signal menu_flavor_updated
signal ov_to_battle
signal battle_to_ov

const GameOverRes := preload("res://Nodes/Ui/GameOver.tscn")

onready var CommandsMenuRes := preload("res://Nodes/Ui/Pause menu.tscn")
var DialogueBoxRes := preload("res://Nodes/Ui/DialogueBox.tscn")
var BattleDialogueBoxRes := preload("res://Nodes/Ui/Battle/BattleDialogueBox.tscn")
var BattleSceneRes := preload("res://Nodes/Ui/Battle/Battle.tscn")
var BlackBarsRes := preload("res://Nodes/Ui/Blackbars.tscn")
var ATMMenuRes := preload("res://Nodes/Ui/ATM/ATM Menu.tscn")
var CashBoxRes := preload("res://Nodes/Ui/CashBox.tscn")
var PhoneUnitsBoxRes := preload("res://Nodes/Ui/PhoneUnitsBox.tscn")
var KeyIndicatorRes := preload("res://Nodes/Ui/KeyCount.tscn")
var ShopRes := preload("res://Nodes/Ui/Shop/ShopUI.tscn")
var StorageRes := preload("res://Nodes/Ui/Storage.tscn")
var SaveSelectRes := preload("res://Maps/SaveSelect.tscn")
var OcarinaScreenRes := preload("res://Nodes/Ui/OcarinaScreen/OcarinaScreen.tscn")
var KeyboardRes := preload("res://Maps/Naming screen.tscn")
var MapScreenRes := preload("res://Nodes/Ui/MapScreen/MapScreen.tscn")
var TrainCutscene := preload("res://Maps/misc/TrainCutscene.tscn")
var PartyInfoRes := preload("res://Nodes/Ui/PartyInfo.tscn")
var BattleTransitionRes := preload("res://Nodes/Ui/Battle/Battle Transition.tscn")
onready var _cash: CanvasLayer = CashBoxRes.instance()
onready var _phone_units: CanvasLayer = PhoneUnitsBoxRes.instance()
onready var _key: CanvasLayer = KeyIndicatorRes.instance()
onready var _party_info_view: CanvasLayer = PartyInfoRes.instance()
onready var _black_bars: CanvasLayer = BlackBarsRes.instance()
onready var _commands_menu: CanvasLayer = CommandsMenuRes.instance()
onready var _map_screen: Control = MapScreenRes.instance()

var _fixed_camera: Camera2D
var _battle_bgs := {}
var _ui_stack := []
var _stable_canvas_layer: CanvasLayer = null
var _menu_flavor_shader = preload("res://Shaders/MenuFlavors.tres")
var _fade: CanvasLayer = null
var _dialogue_box: AbstractDialogueBox = null
var _pause_menu_active := false
var _game_over := false
var _in_battle := false
var _battle_queued := false
var _cutscene := false
var _current_shop := ""
var _party_info_timer: Timer

var _onScreenEnemies := []

# Menu flavor colors, First is Border, Second is Darker Border, Third is InnerBorder, Fourth is Interior, Fifth is Highlight and Sixth is Interior Secondary Tone (seen in the party plate of the pause menu)
var menuFlavors := [
	["f3f2f4", "bfb4cd", "7a6c86", "141117", "ba53e4", "d6cedf", "332943"],	# Plain
	["a9fff1", "4ca8b0", "5d6fa5", "230c24", "945ffa", "69c3c4", "36182e"],	# Mint
	["ffa2b5", "e47089", "b8425a", "361115", "2fc05c", "ee8399", "4f1e15"],	# Strawberry
	["ffd152", "d4722c", "ad552f", "220a07", "d85123", "e08b37", "3c1a14"],	# Banana
	["fa8a52", "c2473c", "993131", "33161a", "c92727", "d86146", "432822"],	# Peanut
	["eab3ff", "a669c6", "304280", "171b32", "de3995", "b97ed6", "2e2743"],	# Grape
	["81e06e", "4bb367", "963948", "29101c", "ff4f75", "a8c469", "362126"]	# Melon
]


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	set_menu_flavors(globaldata.menu_flavor)
	
	
	# Load all the battle bgs
	_load_battle_bgs()
	
	_stable_canvas_layer = load("res://Nodes/Ui/mainCanvasLayer.tscn").instance()
	global.currentScene.add_child(_stable_canvas_layer)
	global.add_persistent(_stable_canvas_layer)
	_add_to_canvas(_black_bars, 1)
	_add_to_canvas(_key, 1)
	_add_to_canvas(_party_info_view, 2)
	_add_to_canvas(_commands_menu, 3)
	_add_to_canvas(_cash, 3)
	_add_to_canvas(_phone_units, 3)
	_add_to_canvas(_map_screen, 0)
	
	var transition_node := load("res://Nodes/Ui/effects/Fade.tscn")
	var transition: CanvasLayer = transition_node.instance()
	transition.set_name("fade")
	_stable_canvas_layer.add_child(transition)
	_fade = transition

	_fixed_camera = load("res://Nodes/Ui/Camera.tscn").instance()
	call_deferred("add_child", _fixed_camera)

func set_menu_flavors(flavor: String):
	var flavor_index := globaldata.FLAVORS.find(flavor)
	for i in 7:
		_menu_flavor_shader.set_shader_param("NEWCOLOR%s" % (i+1), Color(menuFlavors[flavor_index][i]))
	emit_signal("menu_flavor_updated")

func get_flavor_color(index: int, is_new: bool = false) -> Color:
	var param := "%sCOLOR%s" % ["NEW" if is_new else "OLD", index]
	return _menu_flavor_shader.get_shader_param(param)

func add_ui(ui: Node, add_child = true):
	_ui_stack.push_front(ui)
	if add_child:
		_stable_canvas_layer.call_deferred("add_child", ui)

func remove_ui(ui: Node = _ui_stack[0]):
	if ui in _ui_stack:
		_ui_stack.erase(ui)
		if is_instance_valid(ui):
			close_item(ui)

func is_pause_menu_active() -> bool:
	return _pause_menu_active

func is_stack_empty() -> bool:
	return _ui_stack.size() == 0

func fix_camera():
	_fixed_camera.set_current()

func close_item(item: Node):
	item.call("close" if item.has_method("close") else "queue_free")

func open_dialogue_box_and_unpause(dialogue_id: String, npc = null):
	var on_finished := funcref(global.get_player(), "on_dialogue_done")
	yield(open_dialogue_box(dialogue_id, on_finished, npc), "completed")

func open_dialogue_box(dialogue_id: String, on_finished: FuncRef = null, npc = null):
	var was_paused := global.get_player().is_paused()
	if !was_paused:
		global.get_player().pause(true, true)
	_dialogue_box = DialogueBoxRes.instance()
	_pause_menu_active = false
	add_ui(_dialogue_box)
	yield(_dialogue_box, "ready")
	_cutscene = true
	close_key_indicator()
	toggle_black_bars(true)
	_dialogue_box.start_from_id(dialogue_id, npc)
	var result: bool = yield(_dialogue_box, "done")
	_dialogue_box = null
	toggle_black_bars(false)
	_cutscene = false
	if !was_paused:
		global.get_player().unpause()
	if on_finished and on_finished.is_valid():
		on_finished.call_func(result)

func get_dialogue_actors() -> Dictionary:
	return _dialogue_box.get_actors() if _dialogue_box else {}

func is_in_cutscene() -> bool:
	return _cutscene

func set_cutscene(value: bool):
	_cutscene = value

func open_battle_dialogue_box(dialog: = {}):
	var battle_dialogue_box = BattleDialogueBoxRes.instance()
	_pause_menu_active = false
	add_ui(battle_dialogue_box)
	yield(battle_dialogue_box, "ready")
	if dialog:
		battle_dialogue_box.start_from_scripted_dialog(dialog)
		yield(battle_dialogue_box, "done")
		remove_ui(battle_dialogue_box)
	else:
		battle_dialogue_box.connect("done", self, "remove_ui", [battle_dialogue_box], CONNECT_ONESHOT)
		return battle_dialogue_box

func get_key_count() -> int:
	if global.currentScene.has_method("get_region_name"):
		return globaldata.keys.get(global.currentScene.get_region_name(), 0)
	return 0

func try_alter_key_count(delta: int) -> bool: #Increases or decreases the amount of keys collected. Returns true if and only if it succeeds.
	var key_count := get_key_count()
	if key_count >= 0 and key_count + delta >= 0:
		globaldata.keys[global.currentScene.get_region_name()] = globaldata.keys.get(global.currentScene.get_region_name(), 0) + delta
		return true
	else:
		return false

func add_cash(amount):
	globaldata.cash += amount

func remove_cash(amount):
	globaldata.cash -= amount

func open_commands_menu():
	global.get_player().pause(false, true)
	_commands_menu.open()
	_pause_menu_active = true

func close_commands_menu(keep_pause := false, remove_bars := false, silent := false, called_from_pause := false):
	_party_info_view.close()
	_pause_menu_active = false
	if !keep_pause:
		global.get_player().unpause()
	if remove_bars:
		toggle_black_bars(false)
	if !called_from_pause:
		var flags: int = 0
		if silent: flags |= _commands_menu.CloseFlags.SILENT
		if !keep_pause: flags |= _commands_menu.CloseFlags.UNPAUSE
		if remove_bars: flags |= _commands_menu.CloseFlags.HIDE_BARS
		_commands_menu.close(flags, true)

func toggle_black_bars(show: bool):
	_black_bars.toggle(show)

func set_battle_queued(enabled: bool):
	_battle_queued = enabled

func is_battle_queued() -> bool:
	return _battle_queued

func start_battle(advantage := 0, can_run := true, enemies_to_join := [], post_battle_cutscenes := {}, win_flag := ""):
	if _in_battle:
		return
	
	info_plates_hide()
	
	emit_signal("ov_to_battle")
	global.get_player().pause(true)
	
	# hoooo boy this is gonna be some funky code right here.
	var root := get_tree().root
	var battle_ui: BattleSystem = BattleSceneRes.instance()
	
	if !enemies_to_join:
		
		for enemy in _onScreenEnemies:
			if enemy.overworld_object != null:
				if enemy.overworld_object.get("eventRayCaster") != null and !enemy.overworld_object.drafted:
					enemy.overworld_object.eventRayCaster.look_at(global.get_player().global_position + global.get_player().get_node("CollisionShape2D").position * 2)
					var collider = enemy.overworld_object.eventRayCaster.get_collider()
					if collider is PartyObject or collider is OverworldEnemy:
						enemy.overworld_object.emotes.hide()
						enemy.overworld_object.emotes.frame = 0
						enemies_to_join.append(enemy)
				else:
					enemy.overworld_object.emotes.hide()
					enemy.overworld_object.emotes.frame = 0
					enemies_to_join.append(enemy)
					enemy.overworld_object.drafted = false
			else:
				enemies_to_join.append(enemy)
	
	_in_battle = true
	
	if global.currentCamera.is_shaking():
		yield(global.currentCamera, "stopped_shaking")
	
	#and lastly, add to UI canvas
	
	var transition = BattleTransitionRes.instance()
	
	battle_ui.init_battle_params(enemies_to_join, advantage, can_run, _battle_bgs, transition, post_battle_cutscenes, win_flag)
	
	
	
	add_ui(battle_ui)
	
	# THEN a back buffer copy to the root, right before the current scene
	# This captures the BG as the SCREEN_TEXTURE, which is used by the transition shader
	
	
	
	var bg = _add_black_rect()
	
	
	
	var backBuffer := BackBufferCopy.new()
	backBuffer.copy_mode = BackBufferCopy.COPY_MODE_RECT
	
	var backBufferPosition = - get_viewport().canvas_transform.origin
	
	backBuffer.rect = get_viewport().get_visible_rect()
	root.add_child(backBuffer)
	root.move_child(backBuffer, root.get_children().size() - 2)
	backBuffer.z_index = - 128
	
	yield(get_tree(), "idle_frame")
	
	
	# add the transition ui, keep at the end of the draw order. So it draws on top of everything else
	root.call_deferred("add_child", transition)
	# Set the position to the VIEWPORT POSITION (aka, so it lines up with the camera)
	transition.position = -get_viewport().canvas_transform.origin
	
	var transparency := 130
	transition.set_color(ColorN("green" if advantage == BattleSystem.Advantage.PLAYER\
	else "red" if advantage == BattleSystem.Advantage.ENEMY else "blue", transparency / 255 as float))
	
	
	transition.connect("done", backBuffer, "queue_free")
	transition.connect("done", bg, "queue_free")
	
	battle_ui.connect("battle_to_ov", self, "emit_signal", ["battle_to_ov"], CONNECT_ONESHOT)
	battle_ui.connect("battle_ended", self, "_on_battle_ended", [battle_ui], CONNECT_ONESHOT)

func _add_black_rect() -> Node2D:
	
	var bg = Node2D.new()
	bg.z_index = - 100
	global.currentScene.add_child(bg)
	global.currentScene.move_child(bg, 0)
	
	var blackRect = ColorRect.new()
	blackRect.color = global.currentScene.area_bg_color
	blackRect.rect_size = get_viewport().get_visible_rect().size
	blackRect.rect_global_position = global.currentCamera.get_camera_screen_center() - blackRect.rect_size / 2.0
	
	bg.add_child(blackRect)
	return bg

func is_in_battle() -> bool:
	return _in_battle

func _on_battle_ended(result: int, battle_ui: Node):
	_in_battle = false
	remove_ui(battle_ui)

func _add_to_canvas(node: Node, layer: int = 0):
	_stable_canvas_layer.add_child(node)
	if layer != - 1:
		_stable_canvas_layer.move_child(node, int(min(layer, _stable_canvas_layer.get_child_count() - 1)))
		if node is CanvasLayer: node.layer = layer

func _load_battle_bgs():
	var dir := Directory.new()
	var path := "res://Graphics/Battle BGS/"
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".scn"):					
					var key = file_name.get_basename()
					_battle_bgs[key] = load(path + file_name)
				elif file_name.ends_with(".dsp.scn"):
					var key = file_name.replace(".dsp.scn", "")
					_battle_bgs[key] = load(path + file_name)
			file_name = dir.get_next()
	
	dir.list_dir_end()

func update_key_indicator():
	if get_key_count() <= 0:
		_key.close()
	else:
		_key.open()

func close_key_indicator():
	_key.close()

func set_current_shop(shop: String):
	_current_shop = shop

func open_shop(shop = null, can_sell = true, callback: FuncRef = null):
	var shop_ui: Control = ShopRes.instance()
	if shop == null:
		shop = _current_shop
	shop_ui.setup(shop, can_sell, callback)
	_pause_menu_active = false
	add_ui(shop_ui)

func open_storage(god_mode = false, callback: FuncRef = null):
	var storage_ui: Control = StorageRes.instance()
	storage_ui.god_mode = god_mode
	storage_ui.setup(callback)
	_pause_menu_active = false
	add_ui(storage_ui)

func open_atm(callback: FuncRef = null):
	var atm_ui: Control = ATMMenuRes.instance()
	atm_ui.setup(callback)
	_pause_menu_active = false
	add_ui(atm_ui)

func open_save(type := SaveSelect.Type.SAVE, callback: FuncRef = null):
	var save_ui: SaveSelect = SaveSelectRes.instance()
	_pause_menu_active = false
	save_ui.init(type, globaldata.save_file, true, callback)
	add_ui(save_ui)

func open_keyboard(scenario_id: String, callback: FuncRef = null):
	var keyboard_ui: Control = KeyboardRes.instance()
	_pause_menu_active = false
	keyboard_ui.init(scenario_id, true, callback)
	add_ui(keyboard_ui)

func open_ocarina_screen(callback: FuncRef = null):
	var ocarina_ui: CanvasLayer = OcarinaScreenRes.instance()
	_fade.fade_in("Circle Focus")
	yield(_fade, "fade_in_done")
	ocarina_ui.init(callback)
	_pause_menu_active = false
	add_ui(ocarina_ui)
	_fade.fade_out("Circle Focus")

func open_current_map(is_reticle_mode := false, callback: FuncRef = null):
	var map_name := ""
	var nameplate_name := ""
	if global.currentScene is AreaRoom:
		map_name = global.currentScene.get_map_name(true, true)
		nameplate_name = global.currentScene.get_region_name()
	open_map_screen(map_name, nameplate_name, is_reticle_mode, callback)

func open_map_screen(area_name: String, name_plate_name: String, is_reticle_mode := false, callback: FuncRef = null):
	global.get_player().pause(true)
	MapScreen.set_reticle_mode(_map_screen, is_reticle_mode)
	_pause_menu_active = false
	add_ui(_map_screen, false)
	_map_screen.enter(area_name, name_plate_name, callback)

func set_telepathy_effect(enabled: bool, object = global.get_player()):
	if enabled:
		_fade.focus_object(object)
		_fade.set_color(Color(0, 0, 0, 0.5))
		_fade.set_cut(0.1, 0.3, 1, Tween.EASE_OUT)
		_fade.set_spin(true, 0.5)
	else:
		_fade.set_cut(1, 0.3, 1, Tween.EASE_IN)
		yield(_fade, "cut_done")
		_fade.set_spin(false)

func get_fade() -> CanvasLayer:
	return _fade

func info_plates_update(scroll := false):
	_party_info_view.refresh_stats(scroll)

func info_plates_highlight(characters: Array):
	_party_info_view.select_characters(characters)

func info_plates_show(show_max_num := true, auto_hide := false, update_info := false, ignore_if_already_open := false, with_sfx := false):
	var already_open := false
	if is_instance_valid(_party_info_timer):
		already_open = true
	if ignore_if_already_open and already_open:
		return
	if update_info: info_plates_update()
	if already_open:
		_party_info_timer.stop()
		_party_info_timer.queue_free()
	_party_info_view.open(show_max_num)
	if with_sfx:
		audioManager.play_sfx_by_name("menu_open", "plate")
	if auto_hide:
		var timer := Timer.new()
		_party_info_timer = timer
		if _party_info_view.is_any_plate_scrolling():
			yield(_party_info_view, "scroll_done")
		yield(global.get_player(), "moved")
		if is_instance_valid(timer):
			timer.wait_time = 1.0
			timer.one_shot = true
			add_child(timer)
			timer.connect("timeout", self, "info_plates_hide")
			timer.start()

func info_plates_hide():
	if is_instance_valid(_party_info_timer):
		_party_info_timer.stop()
		_party_info_timer.queue_free()
	_party_info_view.close()

func get_cash_box(is_phone_units := false) -> CanvasLayer:
	return _phone_units if is_phone_units else _cash

func create_flying_num(text, target_pos: Vector2):
	var FlyingNumTscn := load("res://Nodes/Ui/Battle/FlyingNumber.tscn")
	var flying_num: Label = FlyingNumTscn.instance()
	flying_num.text = str(text)
	global.currentScene.add_child(flying_num)
	flying_num.rect_position = target_pos - Vector2(16, 0)
	flying_num.run()

func clear_on_screen_enemies():
	print("Before clear size: %s" % _onScreenEnemies.size())
	
	for enemy in _onScreenEnemies:
		if enemy.overworld_object and is_instance_valid(enemy.overworld_object) and enemy.overworld_object.has_method("remove_battle"):
			enemy.overworld_object.remove_battle()
	_onScreenEnemies.clear()
	
	print("Onscreen Enemy Count: %s" % _onScreenEnemies.size())
	

func add_on_screen_enemy(enemy: Enemy, overworld_object: Node2D = null) -> OnScreenEnemy:
	var new_enemy = OnScreenEnemy.new(enemy, overworld_object)
	
	_onScreenEnemies.append(new_enemy)
	print("Onscreen Enemy Count: %s" % _onScreenEnemies.size())
	
	return new_enemy

func erase_on_screen_enemy(onscreen_enemy: OnScreenEnemy) -> void :
	if has_on_screen_enemy(onscreen_enemy):
		_onScreenEnemies.erase(onscreen_enemy)
	print("Onscreen Enemy Count: %s" % _onScreenEnemies.size())

func add_on_screen_enemy_to_front(enemy: Enemy, overworld_object: Node2D = null) -> OnScreenEnemy:
	var new_enemy = OnScreenEnemy.new(enemy, overworld_object)
	
	_onScreenEnemies.push_front(new_enemy)
	
	print("Onscreen Enemy Count: %s" % _onScreenEnemies.size())
	return new_enemy

func move_on_screen_enemy_to_front(onscreen_enemy: OnScreenEnemy):
	if has_on_screen_enemy(onscreen_enemy):
		erase_on_screen_enemy(onscreen_enemy)
		_onScreenEnemies.push_front(onscreen_enemy)

func has_on_screen_enemy(onscreen_enemy: OnScreenEnemy) -> bool:
	return _onScreenEnemies.has(onscreen_enemy)

func get_on_screen_enemies() -> Array:
	return _onScreenEnemies

func game_over(play_sfx := true):
	if play_sfx:
		audioManager.play_sfx(load("res://Audio/Sound effects/PartyLose.mp3"), "PartyLose")
	var game_over = GameOverRes.instance()
	game_over.connect("done", self, "_on_game_over_done", [game_over], CONNECT_ONESHOT)
	add_ui(game_over)
	_game_over = true
	yield(game_over, "fade_done")

func is_game_over() -> bool:
	return _game_over

func _on_game_over_done(instance: Node):
	_game_over = false 
	remove_ui(instance)
