local f = string.format

balanced_diet.diet_hud = futil.define_hud("balanced_diet:diet", {
	period = 1,
	enabled_by_default = true,
	get_hud_def = function(player)
		local now = os.time()
		local eaten = balanced_diet.get_eaten(player, now)
		local lines = {}
		local item_name_by_description = {}

		for item, remaining in pairs(eaten) do
			local description = futil.get_safe_short_description(item)
			description = f("%s: %.0f", description, remaining)
			lines[#lines + 1] = description
			item_name_by_description[description] = item:match("^[^:]:(.*)$") or item
		end

		table.sort(lines, function(a, b)
			return item_name_by_description[a] < item_name_by_description[b]
		end)

		if #lines > 0 then
			table.insert(lines, "---------------")
		end

		for nutrient, def in futil.table.pairs_by_key(balanced_diet.registered_nutrients) do
			local value = balanced_diet.check_nutrient_value(player, nutrient, now)
			lines[#lines + 1] = f("%s: %.0f", def.description, value)
		end

		local text = table.concat(lines, "\n")
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

minetest.register_chatcommand("toggle_diet_hud", {
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "you are not a connected player"
		end
		local enabled = balanced_diet.diet_hud:toggle_enabled(player)
		if enabled then
			return true, "hud enabled"
		else
			return true, "hud disabled"
		end
	end,
})
