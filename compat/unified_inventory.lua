local S = balanced_diet.S

local symbol
if minetest.get_modpath("default") then
	symbol = "default:apple"
end

unified_inventory.register_category("food", {
	symbol = symbol,
	label = S("Food"),
})

balanced_diet.register_on_register_food(function(item_name, food_def)
	unified_inventory.add_category_item("food", item_name)
end)
