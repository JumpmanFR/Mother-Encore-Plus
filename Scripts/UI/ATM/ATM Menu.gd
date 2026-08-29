extends Control

var withdraw := true
var digit_limit: int = 0
var selected_digit: int = 5
var actual_digit: int = 1

var mainTab_root_pos := Vector2.ZERO
var subTab_root_pos := Vector2.ZERO

var _callback: FuncRef = null
var _cursor_tween: SceneTreeTween
var _tab_tween: SceneTreeTween

func setup(callback: FuncRef = null):
	_callback = callback

# Called when the node enters the scene tree for the first time.
func _ready():
	mainTab_root_pos = $TabMain.rect_position
	subTab_root_pos = $TabSub.rect_position
	$background / userAmount / ArrowL.playing = true
	$background / userAmount / ArrowR.playing = true
	$background / userAmount / ArrowU.playing = true
	$background / userAmount / ArrowD.playing = true
	global.get_player().pause()
	_refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var arrow_U = $background / userAmount / ArrowU
	var arrow_D = $background / userAmount / ArrowD
	var usrAmt = $background / userAmount
	
	var direction = controlsManager.get_controls_vector(true)

	if direction.x < 0:
		move_digit( - 1)
		_play_sfx("cursor1")
	elif direction.x > 0:
		move_digit(1)
		_play_sfx("cursor1")
	
	if direction.y < 0:
		usrAmt.add_digit(1, actual_digit)
		_play_sfx("cursor1")
	elif direction.y > 0:
		usrAmt.add_digit( - 1, actual_digit)
		_play_sfx("cursor1")
	
func _input(event: InputEvent):
	if event.is_action_pressed("ui_focus_prev"):
		_switch_tab()
	elif event.is_action_pressed("ui_focus_next"):
		_switch_tab()
	
	if event.is_action_pressed("ui_accept"):
		make_transfer()
	if event.is_action_pressed("ui_cancel"):
		_play_sfx("back")
		uiManager.call_deferred("remove_ui", self)

func _switch_tab():
	withdraw = not withdraw
	_refresh()
	_play_sfx("menu_open")

func make_transfer():
	if $background / userAmount.money <= 0:
		_play_sfx("restricted")
		return
	if withdraw:
		globaldata.bank -= $background / userAmount.money
		globaldata.cash += $background / userAmount.money
	else:
		globaldata.bank += $background / userAmount.money
		globaldata.cash -= $background / userAmount.money
	_play_sfx("cash")
	_refresh()

func _reset_digit():
	selected_digit = 5
	actual_digit = (selected_digit - 5) * - 1
	_visual_cursor_move()

func move_digit(dir: int):
	selected_digit += dir
	if selected_digit < digit_limit: selected_digit = 5
	if selected_digit > 5: selected_digit = digit_limit
	
	actual_digit = (selected_digit - 5) * - 1
	_visual_cursor_move()
	

func _visual_cursor_move():
	var arrow_U = $background / userAmount / ArrowU
	var arrow_D = $background / userAmount / ArrowD
	if _cursor_tween: _cursor_tween.kill()
	_cursor_tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO)
	_cursor_tween.tween_property(arrow_U, "position:x", 10 + (selected_digit * 8), 0.1)
	_cursor_tween.tween_property(arrow_D, "position:x", 10 + (selected_digit * 8), 0.1)

func _switch_tab_anim():
	var arrow := $background / Arrow as TextureRect
	var main_tab := $TabMain as TextureRect
	var sub_tab := $TabSub as TextureRect
	if _tab_tween: _tab_tween.kill()
	_tab_tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO)
	if withdraw:
		_tab_tween.tween_property(arrow, "rect_rotation", 180.0, 0.1)
	else:
		_tab_tween.tween_property(arrow, "rect_rotation", 0.0, 0.1)

func close():
	if _callback and _callback.is_valid():
		_callback.call_func()
		_callback = null

	queue_free()

func _refresh():
	var limit_string: String
	$background / BankBalance.set_limit(globaldata.bank)
	$background / BankBalance.set_money(globaldata.bank)
	$background / WalletBalance.set_limit(globaldata.cash)
	$background / WalletBalance.set_money(globaldata.cash)
	if withdraw:
		$TabMain.rect_position = subTab_root_pos + Vector2(0, - 2)
		$TabSub.rect_position = mainTab_root_pos + Vector2(0, + 2)
		$TabMain.flip_h = true
		$TabSub.flip_h = false
		$Deposit / Sprite.modulate = Color("c8c8c8")
		$Withdraw / Sprite.modulate = Color.white
		
		
		
		$background / Label2.text = "ATM_WITHDRAW"
		$background / userAmount.set_limit(globaldata.bank)
		limit_string = str(globaldata.bank)
	else:
		$TabMain.rect_position = mainTab_root_pos
		$TabSub.rect_position = subTab_root_pos
		$TabMain.flip_h = false
		$TabSub.flip_h = true
		$Withdraw / Sprite.modulate = Color("c8c8c8")
		$Deposit / Sprite.modulate = Color.white
		
		
		$background / Label2.text = "ATM_DEPOSIT"
		
		$background / userAmount.set_limit(globaldata.cash)
		limit_string = str(globaldata.cash)
	$background / userAmount.set_money(0)
	digit_limit = (limit_string.length() - 6) * - 1
	_reset_digit()
	_switch_tab_anim()


func _play_sfx(sfx_name: String):
	audioManager.play_sfx_by_name(sfx_name, "cursor")
