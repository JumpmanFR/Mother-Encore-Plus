extends Control

onready var value: float = $Texture.value setget _set_value, _get_value
var highlighted := false setget _set_highlighted

func _ready():
	uiManager.connect("menu_flavor_updated", self, "_refresh_tint")
	_refresh_tint()

func _set_highlighted(value):
	highlighted = value
	_refresh()

func _set_value(value):
	$Texture.value = value

func _get_value():
	return $Texture.value

func _on_visibility_changed():
	if !is_visible_in_tree():
		highlighted = false
	_refresh()

func _on_value_changed(value):
	_refresh()

func _refresh():
	var volRange = $Texture.max_value - $Texture.min_value
	$Texture/Thumb.rect_position.x = ($Texture.value - 1) * ($Texture.rect_size.x) / volRange

	$Texture/Thumb/ThumbRect.rect_size.y = $Texture.value
	$Texture/Thumb/ThumbRect.rect_position.y = volRange - $Texture/Thumb/ThumbRect.rect_size.y

	$Texture/Thumb/ThumbLowerRect.visible = highlighted
	$Texture/LowerLine.visible = highlighted

func _refresh_tint():
	$Texture.tint_under = uiManager.get_flavor_color(3)
	$Texture.tint_progress = uiManager.get_flavor_color(5)
	$Texture/Thumb/ThumbRect.color = uiManager.get_flavor_color(1)
	$Texture/Thumb/ThumbLowerRect.color = uiManager.get_flavor_color(1)
	$Texture/LowerLine.color = uiManager.get_flavor_color(3)

