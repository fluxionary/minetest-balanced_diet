balanced_diet.registered_saturation_huds = {}

function balanced_diet.register_saturation_hud(def)
	table.insert(balanced_diet.registered_saturation_huds, def)
end

balanced_diet.saturation_attribute:register_on_change(function(self, player, value, old_value)
	if value ~= old_value then
		for _, hud_def in ipairs(balanced_diet.registered_saturation_huds) do
			hud_def.on_saturation_change(player, value)
		end
	end
end)

balanced_diet.saturation_attribute:register_on_max_change(function(self, player, saturation_max, old_max)
	if saturation_max ~= old_max then
		for _, hud_def in ipairs(balanced_diet.registered_saturation_huds) do
			hud_def.on_saturation_max_change(player, saturation_max)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local saturation = balanced_diet.saturation_attribute:get(player, os.time())
	local saturation_max = balanced_diet.saturation_attribute:get_max(player)
	for _, hud_def in ipairs(balanced_diet.registered_saturation_huds) do
		if hud_def.on_joinplayer then
			hud_def.on_joinplayer(player, saturation, saturation_max)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	for _, hud_def in ipairs(balanced_diet.registered_saturation_huds) do
		if hud_def.on_leaveplayer then
			hud_def.on_leaveplayer(player)
		end
	end
end)
