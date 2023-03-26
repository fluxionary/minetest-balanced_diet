local f = string.format

balanced_diet.nutrients_hud = futil.define_hud("balanced_diet:nutrients", {
	period = 1,
	get_hud_def = function(player)
		local now = os.time()
		local nutrient_values = {}

		for nutrient in futil.table.pairs_by_key(balanced_diet.registered_nutrients) do
			local value = balanced_diet.check_nutrient_value(player, nutrient, now)
			nutrient_values[#nutrient_values + 1] = f("%s: %.0f", nutrient, value)
		end

		local text = table.concat(nutrient_values, "\n")
		return {
			hud_elem_type = "text",
			text = text,
			number = 0xFFFFFF, --
			direction = 0, -- left to right
			position = { x = 1, y = 1 },
			alignment = { x = -1, y = -1 },
			offset = { x = -10, y = -10 },
			style = 1,
		}
	end,
})

minetest.register_chatcommand("toggle_nutrients_hud", {
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "you are not a connected player"
		end
		local enabled = balanced_diet.nutrients_hud:toggle_enabled(player)
		if enabled then
			return true, "hud enabled"
		else
			return true, "hud disabled"
		end
	end,
})
