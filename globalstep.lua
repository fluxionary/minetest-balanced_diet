local f = string.format

local check_every = 1 -- TODO: setting

local function last_value_key(nutrient)
	return f("balanced_diet:last_value:%s", nutrient)
end

local function update(player, now)
	local meta = player:get_meta()
	for nutrient, def in pairs(balanced_diet.registered_nutrients) do
		local key = last_value_key(nutrient)
		local last_value = meta:get_float(key)
		local current_value = balanced_diet.check_nutrient_value(player, nutrient, now)
		if last_value ~= current_value then
			if def.apply_value then
				def.apply_value(player, current_value)
			end
			meta:set_float(key, current_value)
		end
	end
end

local elapsed = 0
minetest.register_globalstep(function(dtime)
	elapsed = elapsed + dtime
	if elapsed < check_every then
		return
	end
	elapsed = elapsed - check_every -- allow catchup when lag
	local now = os.time()
	local players = minetest.get_connected_players()
	for i = 1, #players do
		update(players[i], now)
	end
end)
