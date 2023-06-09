local f = string.format

local check_every = 1 -- TODO: setting

local last_eaten_by_player_name = {}

local function update_saturation(player, now)
	local eaten = balanced_diet.get_eaten(player, now)
	local total_saturation = 0

	for food, remaining in pairs(eaten) do
		local food_def = balanced_diet.get_food_def(food)
		if not food_def then
			error(f("no def for food %q?! %s", food, dump(eaten)))
		end
		local remaining_saturation = food_def.saturation * remaining / food_def.duration
		total_saturation = total_saturation + remaining_saturation
	end

	local saturation_max = balanced_diet.saturation_attribute:get_max(player)
	if total_saturation > saturation_max then
		balanced_diet.log("error", "saturation %s is greater than max %s", total_saturation, saturation_max)
		total_saturation = saturation_max
	end

	balanced_diet.saturation_attribute:set(player, total_saturation)
end

minetest.register_globalstep(function()
	local now = os.time()
	local players = minetest.get_connected_players()

	for i = 1, #players do
		update_saturation(players[i], now)
	end
end)

local function apply_nutrients(player, now)
	for nutrient, nutrient_def in pairs(balanced_diet.registered_nutrients) do
		if nutrient_def.apply_value then
			local value = balanced_diet.check_nutrient_value(player, nutrient, now)
			nutrient_def.apply_value(player, value)
		end
	end
end

local function check_for_empty_stomach(player, now)
	local player_name = player:get_player_name()
	local last_eaten = last_eaten_by_player_name[player_name]
	local eaten = balanced_diet.get_eaten(player, now)
	last_eaten_by_player_name[player_name] = eaten
	if last_eaten then
		local food_digested = false
		for food in pairs(last_eaten) do
			if not eaten[food] then
				food_digested = true
				break
			end
		end
		if food_digested then
			minetest.sound_play(
				"balanced_diet_hungry",
				{ pos = player:get_pos(), max_hear_distance = 16, gain = 0.5 },
				true
			)
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
			apply_nutrients(players[i], now)
			check_for_empty_stomach(players[i], now)
		end
	end,
})

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	last_eaten_by_player_name[player_name] = nil
end)
