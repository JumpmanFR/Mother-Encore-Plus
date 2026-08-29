extends ColorRect

var oldColor

func _ready():
	oldColor = color
	uiManager.connect("menu_flavor_updated", self, "setColor")
	connect("visibility_changed", self, "setColor")
	setColor()

func setColor():
	for i in 7:
		if oldColor == uiManager.get_flavor_color(i + 1, false):
			color = uiManager.get_flavor_color(i + 1, true)
