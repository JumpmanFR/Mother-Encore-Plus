class_name SaveManager



static func is_save_in_current_version(save_data: Dictionary):
	return save_data.get("version", "") == global.GAME_VERSION

static func upgrade_save(save_data: Dictionary):
	var inventories = save_data.get("inventories", {})
	for i in inventories.keys():
		
		for item in inventories[i]:
			if item.has("equiped"):
				item["equipped"] = item["equiped"]
				item.erase("equiped")
			if item.has("ItemName"):
				item["item_name"] = item["ItemName"]
				item.erase("ItemName")
		if i in global.POSSIBLE_PLAYABLE_MEMBERS and i in save_data.keys():
			save_data[i]["inventory"] = inventories[i]
		elif i == "key":
			save_data["key_items"] = inventories[i]
	save_data.erase("inventories")
	
	for char_name in globaldata.characters:
		if save_data.has(char_name):
			var chara = save_data[char_name]
			if char_name in global.POSSIBLE_PLAYABLE_MEMBERS:
				
				chara.nickname = chara.nickname.replace("[", "⟦").replace("]", "⟧")
			
			
			if chara.has("boosts"):
				chara["permanent_boosts"] = chara["boosts"]
				chara.erase("boosts")
			
			
			if chara.has("equipment"):
				chara.erase("equipment")
				
				
				for item in chara.get("inventory"):
					if item["equipped"]:
						var item_info = globaldata.get_item_data(item["item_name"])
						if item_info.has("boost"):
							for stat in item_info["boost"]:
								chara["permanent_boosts"][stat] -= item_info["boost"][stat]
			
			
			chara.erase("name")
			
			chara.erase("passiveSkills")
			
			chara.erase("passiveHeal")
			
			var status = chara.get("status")
			if status != null:
				var old_status_enum = ["asthma", "blinded", "burned", "cold", "confused", "forgetful", "nausea", "numb", "poisoned", "sleeping", "sunstroked", "mushroomized", "unconscious"]
				for i in range(status.size()):
					if typeof(status[i]) in [TYPE_INT, TYPE_REAL]:
						status[i] = {"status": old_status_enum[status[i]]}
	
	
	for i in save_data.get("party", []).size():
		if save_data.party[i] is Dictionary:
			save_data.party[i] = save_data.party[i].name
	
	
	for i in save_data.get("partyNpcs", []).size():
		save_data.party.append(save_data.partyNpcs[i].name)
	save_data.erase("partyNpcs")
	
	save_data["flags"]["visited_podunk"] = true
	
	save_data["object_flags"] = save_data.get("object_flags", {})
	for flag_key in save_data["flags"].keys():
		if ("_present_" in flag_key) or ("_pres_" in flag_key)\
		or ("_item_" in flag_key) or ("_key_" in flag_key)\
		or ("_door_" in flag_key) or ("_plate_" in flag_key):
			var new_flag_key = flag_key
			new_flag_key = flag_key.replace("debug_present_", "Debug World/Present")\
			.replace("basement_pres_", "Ninten's House/Present")\
			.replace("podunk_pres_", "Podunk/Present")\
			.replace("cem_pres_", "Podunk/PresentCem")\
			.replace("zoo_pres_", "Podunk/PresentZoo")\
			.replace("catac_pres_", "Catacombs/Present")\
			.replace("zoo_office_pres_", "Zoo Office/Present")\
			.replace("catac_item_", "Catacombs/Item")\
			.replace("catac_key_", "Catacombs/Key")\
			.replace("catac_door_", "Catacombs/Locked Door")\
			.replace("catac_plate_", "Catacombs/Plate")

			if new_flag_key != flag_key:
				save_data["object_flags"][new_flag_key] = save_data["flags"][flag_key] or save_data["object_flags"].get(new_flag_key, false)
				save_data["flags"].erase(flag_key)
