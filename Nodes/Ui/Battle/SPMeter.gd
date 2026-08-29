extends Control
class_name SPMeter

export var progressBar: NodePath
export var progressBarUnder: NodePath
export var progressBarGlow: NodePath
export var glowAnim: NodePath

onready var progressBarNode : TextureProgress = get_node_or_null(progressBar)
onready var progressBarUnderNode : TextureProgress = get_node_or_null(progressBarUnder)
onready var progressBarGlowNode : TextureProgress = get_node_or_null(progressBarGlow)
onready var glowAnimNode : AnimationPlayer = get_node_or_null(glowAnim)

var _tween: SceneTreeTween
var _sp := 0
var _encore_cost := 4
# encores can only be activated once it reaches a certain amount
const SP_MAX := 100
const NOTCH_STEP := 10

func _ready():
	_update_bar_instantly()

func get_filled_bars() -> int:
	return _sp / 10

func _set_bar_glow(enabled: bool) -> void :
	glowAnimNode.play("Glowing" if enabled else "NotGlowing")

func add_sp(amt: int, multiplied:= false) -> void:
	if multiplied: amt = _get_multiplied_amt(amt)
	_sp += amt
	_update_sp()

func remove_sp(amt: int, multiplied:= false) -> void:
	if multiplied: amt = _get_multiplied_amt(amt)
	_sp -= amt
	_update_sp()

func set_sp(amt: int) -> void :
	_sp = amt
	_update_sp()

func get_sp() -> int:
	return _sp

func _update_sp() -> void:
	_sp = int(max(0, min(_sp, SP_MAX)))
	_update_bar()

func _update_bar() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	if progressBarNode.value < _sp:
		_tween.tween_property(progressBarUnderNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
		_tween.tween_property(progressBarNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(progressBarGlowNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
	elif progressBarUnderNode.value > _sp:
		_tween.tween_property(progressBarUnderNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(progressBarNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
		_tween.tween_property(progressBarGlowNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
	_set_bar_glow(_sp >= _get_multiplied_amt(_encore_cost))

func _update_bar_instantly() -> void:
	progressBarUnderNode.value = _sp
	progressBarNode.value = _sp
	progressBarGlowNode.value = _sp
	_set_bar_glow(_sp >= _get_multiplied_amt(_encore_cost))

func set_encore_cost(amt: int) -> void:
	_encore_cost = amt
	_update_sp()

func _get_multiplied_amt(amt) -> int:
	return amt * NOTCH_STEP
