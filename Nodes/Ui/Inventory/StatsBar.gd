extends NinePatchRect

const CHARACTER_PORTRAIT_PATH = "res://Graphics/UI/Inventory/characters/%s.png"

const stats_list = [
	"maxhp",		
	"maxpp",		
	"speed",	
	"offense",
	"defense",
	"iq", 
	"guts"
]

onready var stats = {
	"maxhp": 		$StatsLabels/HPStats,
	"maxpp":		$StatsLabels/PPStats,
	"speed":	$StatsLabels/SPDStats,
	"offense":	$StatsLabels/OFEStats,
	"defense":	$StatsLabels/DEFStats,
	"iq": 		$StatsLabels/IQStats,
	"guts":		$StatsLabels/GUTStats
}


func _ready():
	hide()

func show_statsBar(character: Character, modifiers: Dictionary):
	if !character: return
	
	$CenterContainer/CharacterPortrait.texture = load(CHARACTER_PORTRAIT_PATH % character.get_name())
	for stat in stats_list:
		stats[stat].set_stat_value(character.get_stat(stat))
		stats[stat].hide_modifier_value()
		stats[stat].set_modifier_icon("")
	
	if modifiers:
		for modifier in modifiers.keys():
			var mod = modifiers[modifier]
			stats[modifier].set_modifier_value(mod)
			if int(mod) > int(character.get_stat(modifier)):
				stats[modifier].set_modifier_icon("up")
			elif int(mod) < int(character.get_stat(modifier)):
				stats[modifier].set_modifier_icon("down")
			else: stats[modifier].set_modifier_icon("")
	
	if !visible: $AnimationPlayer.play("Open")

func hide_statsBar():
	if visible: $AnimationPlayer.play("Close")
