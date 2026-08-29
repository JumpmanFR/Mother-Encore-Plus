extends BattleMenuBox

signal fail()

export (NodePath) var _name_box
export (NodePath) var _bg_darkinator
export (NodePath) var _note_spawner

var _party_BPs := []
var _enemy_BPs := []
var _battle_system

const _targetables := []
var _target_type: int
var _target_all := false
onready var _pointer := get_node("TargetPointer")
var _pointer_index := 0

func _ready():
	_name_box = get_node_or_null(_name_box)
	_bg_darkinator = get_node_or_null(_bg_darkinator)
	_note_spawner = get_node_or_null(_note_spawner)
	_battle_system = get_parent()

func init(party_BPs: Array, enemy_BPs: Array):
	_party_BPs = party_BPs
	_enemy_BPs = enemy_BPs

func _process(delta):
	if visible:
		if !_target_all and _targetables.size() > 1:
			var direction = controlsManager.get_controls_vector(true).x
			
			if direction != 0 and _pointer.get_node("Timer").time_left == 0:
				_pointer_move(direction)
				_pointer.get_node("Timer").start()
				return

func _input(event):
	if visible:
		if event.is_action_pressed("ui_accept"):
			get_tree().set_input_as_handled()
			_pointer_select()

func enter(reset := false, _action = null):
	.enter(reset, _action)
	_targetables.clear()
	_target_all = _action.target_type in [BattleSystem.TargetType.ALL_ENEMIES, BattleSystem.TargetType.ALL_ALLIES]
	_target_type = _action.target_type
	match(_action.target_type):
		BattleSystem.TargetType.ENEMY:
			_targetables.append_array(_get_all_targetable(_enemy_BPs, _action))
		BattleSystem.TargetType.ALL_ENEMIES:
			_targetables.append_array(_get_all_targetable(_enemy_BPs, _action))
		BattleSystem.TargetType.SELF:
			_targetables.append_array(_get_all_targetable([action.user], _action))
		BattleSystem.TargetType.ALLY:
			_targetables.append_array(_get_all_targetable(_party_BPs, _action))
		BattleSystem.TargetType.ALLY_EXCEPT_SELF:
			var party_without_self := _party_BPs.duplicate()
			party_without_self.erase(_action.user)
			_targetables.append_array(_get_all_targetable(_party_BPs, _action))
		BattleSystem.TargetType.ALL_ALLIES:
			_targetables.append_array(_get_all_targetable(_party_BPs, _action))
		BattleSystem.TargetType.RANDOM_ENEMY:
			var targetable_enemies := _get_all_targetable(_enemy_BPs, _action)
			action.targets = [targetable_enemies[randi() % targetable_enemies.size()]]
			self.call_deferred("emit_signal", "next")
			return
		BattleSystem.TargetType.RANDOM_ENEMIES_2:
			var targetable_enemies := _get_all_targetable(_enemy_BPs, _action)
			action.targets = [targetable_enemies[randi() % targetable_enemies.size()]]
			action.targets += [targetable_enemies[randi() % targetable_enemies.size()]]
			self.call_deferred("emit_signal", "next")
			return
		BattleSystem.TargetType.RANDOM_ENEMIES_UNTIL_MISS:
			var targetable_enemies := _get_all_targetable(_enemy_BPs, _action)
			action.targets = []
			for i in 100:
				action.targets.append(targetable_enemies[randi() % targetable_enemies.size()])
			self.call_deferred("emit_signal", "next")
			return
		BattleSystem.TargetType.RANDOM_ALLY:
			var targetable_ally := _get_all_targetable(_party_BPs, _action)
			action.targets = [targetable_ally[randi() % targetable_ally.size()]]
			self.call_deferred("emit_signal", "next")
			return
	
	_targetables.sort_custom(self, "_sort_targetables")

	if reset:
		_pointer_index = (_targetables.size() - 1) / 2 if _action.target_type == BattleSystem.TargetType.ENEMY\
		else 0
		_name_box.show()
		if !_note_spawner.are_notes_visible(): 
			darken_bg()
		if !_targetables.empty():
			if _target_all:
				var i := 0
				for target in _targetables:
					var next_pointer := _create_or_get_pointer(i)
					next_pointer.show()
					next_pointer.get_node("AnimationPlayer").play("point")
					next_pointer.rect_position = target.get_target_position() - _pointer.rect_size/1.5
					target.select(!_can_receive_item_action(target))
					i += 1
				_battle_system.tilt_bars(_targetables[i - 1].get_target_center())
			else:
				var target = _targetables[_pointer_index]
				target.select(!_can_receive_item_action(target))
				_pointer.show()
				_pointer.get_node("AnimationPlayer").play("point")
				_pointer.rect_position = target.get_target_position() - _pointer.rect_size / 1.5
				_battle_system.tilt_bars(target.get_target_center())

	_name_box_refresh()

func _sort_targetables(bp1, bp2):
	return bp1.get_sprite().rect_global_position < bp2.get_sprite().rect_global_position

func darken_bg():
	_bg_darkinator.play("darken")

func undarken_bg():
	_bg_darkinator.play("undarken")

func hide():
	.hide()
	_name_box.hide()
	if !_note_spawner.are_notes_visible():
		undarken_bg()
	for p in get_children():
		if p is CanvasItem:
			p.hide()
	for target in _targetables:
		target.deselect()
	_battle_system.tilt_bars(Vector2(160, 90))

func _create_or_get_pointer(num: int) -> Node:
	if num >= get_child_count():
		var new_pointer = _pointer.duplicate()
		add_child(new_pointer)
		return new_pointer
	else:
		return get_child(num)

func _get_all_targetable(bp_array: Array, _action = null) -> Array:
	var arr = []
	for bp in bp_array:
		if bp.is_targetable_for_action(_action):
			arr.append(bp)
	return arr

func _pointer_move(dir: int):
	if dir != 0:
		audioManager.play_sfx_by_name("cursor1", "cursor")
	_targetables[_pointer_index].deselect()
	_pointer_index = _targetables.size() - 1 if dir == - 1 and _pointer_index == 0\
	else 0 if dir == 1 and _pointer_index == _targetables.size() - 1\
	else int(clamp(_pointer_index + dir, 0, _targetables.size() - 1))
	var new_target = _targetables[_pointer_index]
	new_target.select(!_can_receive_item_action(new_target))
	_battle_system.tilt_bars(new_target.get_target_center())
	create_tween().tween_property(_pointer, "rect_position", new_target.get_target_position() - _pointer.rect_size/1.5, 0.2) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	_name_box_refresh()

func _pointer_select():
	action.targets = _targetables if _target_all else [_targetables[_pointer_index]]
	
	if action.targets.size() == 1 and !_can_receive_item_action(action.targets[0]):
		audioManager.play_sfx_by_name("restricted", "cursor")
		emit_signal("fail")
	else:
		audioManager.play_sfx_by_name("cursor2", "cursor")
		emit_signal("next")

func _can_receive_item_action(target: BattleParticipant) -> bool:
	return !("item" in action) or target.character.can_receive_item(action.item)

func _name_box_refresh():
	match _target_type:
		BattleSystem.TargetType.ENEMY:
			if _targetables.size() > 0:
				_name_box.get_child(0).text = _targetables[_pointer_index].get_name()
		BattleSystem.TargetType.ALL_ENEMIES:
			_name_box.get_child(0).text = "BATTLE_TARGET_ALL_ENEMIES"
		BattleSystem.TargetType.SELF:
			_name_box.get_child(0).text = action.user.get_name()
		BattleSystem.TargetType.ALLY, BattleSystem.TargetType.ALLY_EXCEPT_SELF:
			if _targetables.size() > 0:
				_name_box.get_child(0).text = _targetables[_pointer_index].get_name()
		BattleSystem.TargetType.ALL_ALLIES:
			_name_box.get_child(0).text = "BATTLE_TARGET_ALL_ALLIES"
