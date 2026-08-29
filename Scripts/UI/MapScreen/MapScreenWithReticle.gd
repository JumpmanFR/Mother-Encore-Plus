extends MapScreen

const RETICLE_DEAD_ZONE := Vector2(24, 24)

var _reticle_dead_zone_offset := Vector2.ZERO
var _position := Vector2.ZERO
var _current_target: TextureRect

# Override
func _on_ready():
	hide()
	$PlayerMarkerTemplate.hide()
	$Reticle.visible = true
	_load_map(MISSING_MAP)
	$Reticle/Area2D.connect("area_entered", self, "_on_reticle_entered")
	$Reticle/Area2D.connect("area_exited", self, "_on_reticle_exited")

# Override
func _handle_inputs(event):
	if event.is_action_pressed("ui_scope"):
		_toggle_markers()

	if event.is_action_pressed("ui_accept", false):
		var dialogue_id := "Testing/nuke_nothing"
		if _current_target:
			var target_id := _current_target.texture.resource_path.get_file().get_basename()
			dialogue_id = target_id.replace("marker_", "Testing/nuke_")
		
		uiManager.open_dialogue_box(dialogue_id, funcref(self, "_on_dialog_done"))
		_active = false

# Override
func _init_position():
	_move_to(Vector2.ZERO)
	_update_arrows()

# Override
func _move_to(pos: Vector2):
	var map_size := _get_map_size()

	var old_scroll_offset := _scroll_offset
	_scroll_offset = _clamp_position(pos, (map_size - SCREEN_SIZE) / 2)
	var pos_clamp_screen := _clamp_position(pos, map_size / 2 - _reticle_dead_zone_offset.abs())
	_loaded_map.rect_position = - _scroll_offset - _loaded_map.rect_size / 2 + SCREEN_SIZE / 2

	$MapArrows.point_dir_sum(_scroll_offset - old_scroll_offset)

	$Reticle.position = - _scroll_offset + _reticle_dead_zone_offset + pos_clamp_screen

	_position = pos_clamp_screen

	_update_arrows()
	_update_player_marker()

# Override
func _move_by(delta: Vector2):
	var new_reticle_offset_attempt := _reticle_dead_zone_offset + delta
	_reticle_dead_zone_offset = _clamp_position(new_reticle_offset_attempt, RETICLE_DEAD_ZONE)
	_move_to(_position + (new_reticle_offset_attempt - _reticle_dead_zone_offset))

# Override
func _update_prompts():
	$Prompts/PromptFast.visible = true
	$Prompts/PromptMarkers.visible = false
	$Prompts/PromptOK.visible = true

# Override
func _toggle_markers(show := !_markers_visible):
	_map_markers.visible = true
	_player_marker.visible = _is_current_scene()

func _on_dialog_done(response: int):
	match response:
		0: # Cancel
			_active = true
		1: # Confirm
			uiManager.open_dialogue_box("Testing/nuke_done", funcref(self, "_on_dialog_done"))
			_active = false
		2: # After nuke done
			_leave()

func _on_reticle_entered(area: Area2D):
	var target := area.get_parent()
	if target is TextureRect and target.texture:
		_current_target = target
		target.modulate = Color(1, 0.5, 0.5)

func _on_reticle_exited(area: Area2D):
	if _current_target == area.get_parent():
		_current_target.modulate = Color(1, 1, 1)
		_current_target = null
