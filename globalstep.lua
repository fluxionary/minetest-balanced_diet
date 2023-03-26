local check_every = 1 -- TODO: setting

local function update(player, now)
	for nutrient, nutrient_def in pairs(balanced_diet.registered_nutrients) do
		if nutrient_def.apply_value then
			local value = balanced_diet.check_nutrient_value(player, nutrient, now)
			nutrient_def.apply_value(player, value)
		end
	end
end

futil.register_globalstep({
	period = check_every,
	catchup = false,
	func = function()
		local now = os.time()
		local players = minetest.get_connected_players()
		for i = 1, #players do
			update(players[i], now)
		end
	end,
})
