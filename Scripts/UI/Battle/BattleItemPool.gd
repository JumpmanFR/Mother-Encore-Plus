extends Object
class_name BattleItemPool

var _chosen_enemy: BattleParticipant
var _starting_party := []
var _pool := []
var item: Item = null

func roll_item(enemy_BPs: Array):
	_starting_party = enemy_BPs.duplicate()
	var candidates := []
	for enemy in _starting_party:
		if enemy.is_boss():
			candidates = [enemy]
			break
		if !_get_enemy_pool(enemy).empty():
			candidates.append(enemy)
	
	if candidates.empty(): return
	_chosen_enemy = candidates[randi() % candidates.size()]
	_pool = _get_enemy_pool(_chosen_enemy)
	_roll()

func _roll():
	for poolite in _pool:
		if poolite.get("rare", false):
			var enemy_name = _chosen_enemy.get_id()
			var r := rand_range(0.0, 100)
			var chance_mod: int = poolite.get("increaseChance", 0) * globaldata.rare_drops[enemy_name]
			if r <= poolite.chance + chance_mod or globaldata.rare_drops[enemy_name] >= 100.0 / poolite.chance:
				item = Item.new(poolite.item)
				globaldata.rare_drops[enemy_name] = 0
		else:
			var r := rand_range(0.0, 100)
			if r <= poolite.chance:
				item = Item.new(poolite.item)
			
		if item: return

func add_rare_drops_for_all_enemies():
	for enemy in _starting_party:
		var pool = _get_enemy_pool(enemy)
		for poolite in pool:
			var item_id = poolite.get("item")
			if poolite.get("rare", false) and ( not item or item.item_name != item_id):
				if !enemy.get_id() in globaldata.rare_drops:
					globaldata.rare_drops[enemy.get_id()] = 0
				globaldata.rare_drops[enemy.get_id()] += 1

func do_you_get_item() -> bool:
	return item != null

func _get_enemy_pool(enemy: BattleParticipant) -> Array:
	return enemy.character.get_data().get("items", [])

func get_item_enemy() -> BattleParticipant:
	return _chosen_enemy
