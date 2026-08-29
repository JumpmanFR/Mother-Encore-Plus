class_name Credits
extends Control

export (NodePath)onready var _anim_player = get_node(_anim_player) as AnimationPlayer
export (NodePath)onready var _door = get_node(_door) as Area2D
export (NodePath)onready var _encore_logo = get_node(_encore_logo) as Control
export (NodePath)onready var _credits_content = get_node(_credits_content) as Control
export (NodePath)onready var _encore_dev_container = get_node(_encore_dev_container) as VBoxContainer
export (NodePath)onready var _canvas_group = get_node(_canvas_group) as CanvasLayer
export (NodePath)onready var _player_container_path: NodePath
export (NodePath)onready var _player_label_path: NodePath
export var _text_alignment := Label.ALIGN_LEFT
export var _credits_music: String
export var _credits_volume: int
export var _act_credit := 0
export var _wait_until_start := 3.0

onready var _header_font := preload("res://Fonts/BottleRocket.tres")
onready var _text_font := preload("res://Fonts/EBMainOutline.tres")
onready var _content_start_pos = _credits_content.rect_position.y

const CREDITS_FILE_PATH := "res://Data/Credits - Credits Per Role.dat"
const SKIP_FADEIN_SPEED := 0.9

var playing = false
var _canvas_group_original_layer: int

func _enter_tree():
	if globaldata.player_name:
		get_node(_player_label_path).text = globaldata.player_name
	else:
		get_node(_player_container_path).hide()

func _ready():
	global.stop_playtime()
	global.get_player().hide()
	global.get_player().pause(true)
	_fill_credits()
	_init_credits_content()
	global.connect("locale_changed", self, "_init_credits_content")
	_start_credits()
	_canvas_group_original_layer = _canvas_group.layer
	


func _start_credits():
	global.get_player().pause()
	playing = true
	yield(get_tree().create_timer(_wait_until_start), "timeout")
	play_music()
	yield(_encore_logo.form_logo(), "completed")
	_anim_player.play("Scroll")

# Overridden
func _init_credits_content():
	_refresh_scrolling_amount()

func _refresh_scrolling_amount():
	yield(get_tree(), "idle_frame")
	var credits_height = _credits_content.rect_size.y
	var scroll_amount = credits_height + _content_start_pos - 180/2 - 3
	var scroll_animation = _anim_player.get_animation("Scroll")
	print("Credits scroll height: %s" % scroll_amount)
	scroll_animation.track_set_key_value(0, 2, -scroll_amount)

func play_music():
	audioManager.stop_all_music()
	audioManager.add_audio_player()
	audioManager.play_music_on_latest_player(_credits_music, "")
	audioManager.set_audio_player_volume(audioManager.get_latest_audio_player_index(), _credits_volume)

func _on_AnimationPlayer_animation_finished(anim_name):
	playing = false
	_reset_canvas_group_layer()
	_door.enter()
	global.currentCamera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER

func _get_act_credit_idx():
	var start_idx = 2
	return _act_credit + start_idx

func _input(event):
	
	if event.is_action_pressed("ui_select") and playing:
		Input.action_release("ui_select")
		_anim_player.stop()
		audioManager.fadeout_all_music(1)
		_door.fade_in_speed = SKIP_FADEIN_SPEED
		_on_AnimationPlayer_animation_finished("Scroll")

func _reset_canvas_group_layer():
	_canvas_group.layer = _canvas_group_original_layer

func _fill_credits():
	var file = File.new()
	if file.file_exists(CREDITS_FILE_PATH):
		file.open(CREDITS_FILE_PATH, File.READ)
		var file_content = file.get_as_text()
		var act_idx = _get_act_credit_idx()
		
		
		
		
		
		
		
		file.get_csv_line()
		while not file.eof_reached():
			var csv = file.get_csv_line()
			var devs = String(csv[act_idx]).split("; ", false)
			
			if devs.size() > 0:
				
				var vbox = VBoxContainer.new()
				_encore_dev_container.add_child(vbox)
				
				var role_label = Label.new()
				
				role_label.text = tr(String(csv[1]))
				
				
				role_label.add_font_override("font", _header_font)
				role_label.add_color_override("font_color", Color("#ffaa66"))
				role_label.align = _text_alignment
				
				
				vbox.add_child(role_label)
				
				
				for dev in devs:
					var dev_label = Label.new()
					dev_label.text = dev
					dev_label.add_font_override("font", _text_font)
					dev_label.align = _text_alignment
					vbox.add_child(dev_label)
	file.close()
	
