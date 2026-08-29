extends Node
# IntegerResolutionHandler autoload.
# Watches for window size changes and handles
# game screen scaling with exact integer
# multiples of a base resolution in mind.

const SETTING_BASE_WIDTH = "display/window/integer_resolution_handler/base_width"
const SETTING_BASE_HEIGHT = "display/window/integer_resolution_handler/base_height"

var _is_active := false
var _is_initialized := false

var _base_resolution := Vector2(320, 180)
var _stretch_mode: int
var _stretch_aspect: int
var _stretch_shrink: float

func _ready():
	# Parse project settings
	if ProjectSettings.has_setting(SETTING_BASE_WIDTH):
		_base_resolution.x = ProjectSettings.get_setting(SETTING_BASE_WIDTH)
	if ProjectSettings.has_setting(SETTING_BASE_HEIGHT):
		_base_resolution.y = ProjectSettings.get_setting(SETTING_BASE_HEIGHT)

	match ProjectSettings.get_setting("display/window/stretch/mode"):
		"2d":
			_stretch_mode = SceneTree.STRETCH_MODE_2D
		"viewport":
			_stretch_mode = SceneTree.STRETCH_MODE_VIEWPORT
		_:
			_stretch_mode = SceneTree.STRETCH_MODE_DISABLED

	match ProjectSettings.get_setting("display/window/stretch/aspect"):
		"keep":
			_stretch_aspect = SceneTree.STRETCH_ASPECT_KEEP
		"keep_height":
			_stretch_aspect = SceneTree.STRETCH_ASPECT_KEEP_HEIGHT
		"keep_width":
			_stretch_aspect = SceneTree.STRETCH_ASPECT_KEEP_WIDTH
		"expand":
			_stretch_aspect = SceneTree.STRETCH_ASPECT_EXPAND
		_:
			_stretch_aspect = SceneTree.STRETCH_ASPECT_IGNORE

	_stretch_shrink = ProjectSettings.get_setting("display/window/stretch/shrink")
	
	# Enforce minimum resolution.
	OS.min_window_size = _base_resolution

	# Remove default stretch behavior.
	var tree: SceneTree = get_tree()
	tree.set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, _base_resolution, 1)

	# Start tracking resolution changes and scaling the screen.
	_update_resolution()
	# warning-ignore:return_value_discarded
	tree.connect("screen_resized", self, "_update_resolution")
	_is_initialized = true

# Added compared to the original addon: activate/deactivate integer scaling with a toggle.
func set_active(active: bool):
	_is_active = active
	if _is_initialized:
		_update_resolution()

func toggle_active():
	set_active(!_is_active)

func is_active() -> bool:
	return _is_active

func _update_resolution():
	var video_mode: Vector2 = OS.window_size
	if OS.window_fullscreen:
		video_mode = OS.get_screen_size()

	var scale: float
	
	# Added compared to the original addon: activate/deactivate integer scaling with a toggle.
	if _is_active:
		scale = int(max(floor(min(video_mode.x / _base_resolution.x, video_mode.y / _base_resolution.y)), 1))
	else:
		scale = min(video_mode.x / _base_resolution.x, video_mode.y / _base_resolution.y)

	var screen_size: Vector2 = _base_resolution
	var viewport_size: Vector2 = screen_size * scale

	var overscan: Vector2 = ((video_mode - viewport_size) / scale).floor()
	
	var margin: Vector2
	var margin2: Vector2

	match _stretch_aspect:
		SceneTree.STRETCH_ASPECT_KEEP_WIDTH:
			screen_size.y += overscan.y
		SceneTree.STRETCH_ASPECT_KEEP_HEIGHT:
			screen_size.x += overscan.x
		SceneTree.STRETCH_ASPECT_EXPAND, SceneTree.STRETCH_ASPECT_IGNORE:
			screen_size += overscan
	viewport_size = screen_size * scale
	margin = (video_mode - viewport_size) / 2
	margin2 = margin.ceil()
	margin = margin.floor()

	var _root: Viewport = get_node("/root")
	match _stretch_mode:
		SceneTree.STRETCH_MODE_VIEWPORT:
			_root.set_size((screen_size / _stretch_shrink).floor())
			_root.set_attach_to_screen_rect(Rect2(margin, viewport_size))
			_root.set_size_override_stretch(false)
			_root.set_size_override(false)
		SceneTree.STRETCH_MODE_2D, _:
			_root.set_size((viewport_size / _stretch_shrink).floor())
			_root.set_attach_to_screen_rect(Rect2(margin, viewport_size))
			_root.set_size_override_stretch(true)
			_root.set_size_override(true, (screen_size / _stretch_shrink).floor())

	if margin.x < 0:
		margin.x = 0
	if margin.y < 0:
		margin.y = 0
	if margin2.x < 0:
		margin2.x = 0
	if margin2.y < 0:
		margin2.y = 0

	VisualServer.black_bars_set_margins(int(margin.x), int(margin.y), int(margin2.x), int(margin2.y))
