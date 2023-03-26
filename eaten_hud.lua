local f = string.format

balanced_diet.eaten_hud = futil.define_hud("balanced_diet:eaten", {
	period = 1,
	enabled_by_default = true,
	get_hud_def = function(player)
		local now = os.time()
		local eaten = balanced_diet.get_eaten(player, now)
		local eaten_info = {}

		for item, remaining in futil.table.pairs_by_key(eaten) do
			table.insert(eaten_info, f("%s: %.0f", item, remaining))
		end

		local text = table.concat(eaten_info, "\n")
		return {
			hud_elem_type = "text",
			text = text,
			number = 0xFFFFFF, --
			direction = 0, -- left to right
			position = { x = 1, y = 0 },
			alignment = { x = -1, y = 1 },
			offset = { x = -10, y = 10 },
			style = 1,
		}
	end,
})

minetest.register_chatcommand("toggle_eaten_hud", {
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "you are not a connected player"
		end
		local enabled = balanced_diet.eaten_hud:toggle_enabled(player)
		if enabled then
			return true, "hud enabled"
		else
			return true, "hud disabled"
		end
	end,
})
