extends Control
class_name OptionsSwitch

export var highlighted = false setget _set_highlighted
export var text = "" setget _set_text

func _ready():
	global.connect("locale_changed", self, "_refresh")

func _on_visibility_changed():
	self.highlighted = false

func _set_highlighted(val):
	highlighted = val
	_refresh()

func _set_text(val):
	$HBox/Label.text = val
	text = val

func _refresh():
	if highlighted:
		if not $HBox/ArrowLMargin/ArrowL.playing:
			$HBox/ArrowLMargin/ArrowL.playing = true
			$HBox/ArrowLMargin/ArrowL.frame = 1
		if not $HBox/ArrowRMargin/ArrowR.playing:
			$HBox/ArrowRMargin/ArrowR.playing = true
			$HBox/ArrowRMargin/ArrowR.frame = 1
	else:
		$HBox/ArrowLMargin/ArrowL.playing = false
		$HBox/ArrowRMargin/ArrowR.playing = false
		$HBox/ArrowLMargin/ArrowL.frame = 0
		$HBox/ArrowRMargin/ArrowR.frame = 0

	if tr("LANGUAGE_CODE") in ["ko", "ja", "zh_Hans_CN"]:
		$HBox / ArrowLMargin / ArrowL.offset.y = 1
		$HBox / ArrowRMargin / ArrowR.offset.y = 1
	else:
		$HBox/ArrowLMargin/ArrowL.offset.y = 0
		$HBox/ArrowRMargin/ArrowR.offset.y = 0
