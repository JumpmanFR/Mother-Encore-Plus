extends TextureRect


func show_is_item_suitable(val):
	$Indicators / is_item_suitable.visible = val

func show_is_item_equipped(val):
	$Indicators / is_item_equipped.visible = val

func show_is_item_better(val):
	$Indicators / is_item_better.visible = val

func show_is_item_lower(val):
	$Indicators / is_item_lower.visible = val

func show_is_inventory_full(val):
	$Indicators / is_inventory_full.visible = val
