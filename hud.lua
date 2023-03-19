balanced_diet.registered_huds = {}

function balanced_diet.register_hud(def)
	table.insert(balanced_diet.registered_huds, def)
end

balanced_diet.register_on_saturation_change(function(player, saturation)
	for _, hud_def in ipairs(balanced_diet.registered_huds) do
		hud_def.on_saturation_change(player, saturation)
	end
end)

balanced_diet.register_on_saturation_max_change(function(player, saturation_max)
	for _, hud_def in ipairs(balanced_diet.registered_huds) do
		hud_def.on_saturation_max_change(player, saturation_max)
	end
end)

minetest.register_on_joinplayer(function(player)
	local saturation = balanced_diet.get_current_saturation(player, minetest.get_us_time())
	local saturation_max = balanced_diet.get_saturation_max(player)
	for _, hud_def in ipairs(balanced_diet.registered_huds) do
		hud_def.on_joinplayer(player, saturation, saturation_max)
	end
end)

minetest.register_on_leaveplayer(function(player)
	for _, hud_def in ipairs(balanced_diet.registered_huds) do
		if hud_def.on_leaveplayer then
			hud_def.on_leaveplayer(player)
		end
	end
end)
