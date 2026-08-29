extends YSort

var party_members = []
var party_npcs = []

export var lloydPath: NodePath
export var anaPath: NodePath
export var teddyPath: NodePath
export var pippiPath: NodePath
export var canaryPath: NodePath

onready var npcs = {
	"lloyd": get_node_or_null(lloydPath), 
	"ana": get_node_or_null(anaPath), 
	"teddy": get_node_or_null(teddyPath), 
	"pippi": get_node_or_null(pippiPath), 
	"canarychick": get_node_or_null(canaryPath)
}

var replacing = false

func _remove_non_present_npcs():
	var present_npcs = []
	
	for partyMem in global.get_full_party():
		var npc = npcs.get(partyMem.get_name(), null)
		if npc:
			present_npcs.append(npc)
	
	for npc in npcs:
		var npcNode = npcs[npc]
		if !present_npcs.has(npcNode) and is_instance_valid(npcNode):
			npcNode.queue_free()

func _replace_party_members():
	replacing = true
	uiManager.set_cutscene(true)
	party_members = []
	party_npcs = []
	
	for partyMem in global.party:
		if partyMem.get_name() != PartyMember.NINTEN:
			global.party.erase(partyMem)
			party_members.append(partyMem)
	for partyNPC in global.partyNpcs:
		global.partyNpcs.erase(partyNPC)
		party_npcs.append(partyNPC)
	uiManager.set_cutscene(false)
	global.call_deferred("create_party_followers")

func _on_Area2D_body_entered(body):
	if body == global.get_player() and !replacing:
		_remove_non_present_npcs()
		_replace_party_members()

func _on_Area2D_body_exited(body):
	if body == global.get_player() and replacing:
		for i in party_members:
			global.party.append(i)
		for i in party_npcs:
			global.partyNpcs.append(i)
		global.call_deferred("create_party_followers")
		replacing = false
