local f = string.format

local check_every = 1 -- TODO: setting

local function last_value_key(nutrient)
	return f("balanced_diet:last_value:%s", nutrient)
end

local function update(player, now)
	local meta = player:get_meta()
	for nutrient, nutrient_def in pairs(balanced_diet.registered_nutrients) do
		local key = last_value_key(nutrient)
		local last_nutrient_value = meta:get_float(key)
		local current_nutrient_value = balanced_diet.check_nutrient_value(player, nutrient, now)
		if last_nutrient_value ~= current_nutrient_value then
			if nutrient_def.apply_value then
				nutrient_def.apply_value(player, current_nutrient_value)
			end
			meta:set_float(key, current_nutrient_value)
		end
	end
end

futil.register_globalstep({
	period = check_every,
	catchup = "single",
	func = function()
		local now = os.time()
		local players = minetest.get_connected_players()
		for i = 1, #players do
			update(players[i], now)
		end
	end,
})
