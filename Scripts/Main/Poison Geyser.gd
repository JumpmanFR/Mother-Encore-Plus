extends Area2D


onready var _anim_player = $AnimationPlayer

func _ready():
	_anim_player.play("Spewing")
	global.get_player().connect("paused", self, "pause")
	global.get_player().connect("unpaused", self, "unpause")

func _process(delta):
	$AudioStreamPlayer2D.volume_db = - 80 if uiManager.is_in_battle() or uiManager.is_in_cutscene()\
	or uiManager.is_game_over() else 0

func pause():
	$AnimationPlayer.playback_active = false
	$AudioStreamPlayer2D.stream_paused = true

func unpause():
	$AnimationPlayer.playback_active = true
	$AudioStreamPlayer2D.stream_paused = false

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func _on_Poison_Geyser_body_entered(body):
	if body is PartyObject:
		if global.get_player().is_paused() == false:
			body.start_continuous_damage(5, 2, Vector2.ZERO, Status.AILMENT_POISONED)

func _on_Poison_Geyser_body_exited(body):
	if body is PartyObject:
		body.stop_continuous_damage()

func play_rumble():
	if not $VisibilityNotifier2D.is_on_screen() or uiManager.is_in_battle() or uiManager.is_game_over() or uiManager.is_in_cutscene():
		return
	if audioManager.get_sfx("geyser") == null:
		audioManager.play_sfx(load("res://Audio/Sound effects/shrekrumble.mp3"), "geyser")
	elif not audioManager.get_sfx(("geyser")).playing:
		audioManager.play_sfx(load("res://Audio/Sound effects/shrekrumble.mp3"), "geyser")
