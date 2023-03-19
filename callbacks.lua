local s = balanced_diet.settings

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	if meta:get_int("balanced_diet:initialized") < 1 then
		balanced_diet.set_saturation_max(player, s.default_saturation_max)
		meta:set_int("balanced_diet:initialized", 1)
	end
end)
