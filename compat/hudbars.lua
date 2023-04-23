local S = balanced_diet.S
local s = balanced_diet.settings

local identifier = "saturation"

hb.register_hudbar(
	identifier,
	0x000000,
	S("saturation"),
	{ bar = "[combine:2x16^[noalpha^[colorize:#FF0:255" },
	0,
	s.default_saturation_max,
	false,
	nil,
	{ format_value = "%.1f", format_max_value = "%.1f" }
)

balanced_diet.register_saturation_hud({
	on_joinplayer = function(player, saturation, saturation_max)
		hb.init_hudbar(player, identifier, saturation, saturation_max, saturation == 0)
	end,
	on_saturation_change = function(player, saturation)
		-- TODO: https://codeberg.org/Wuzzy/minetest_hudbars/issues/4
		-- local state = hb.get_hudbar_state(player, identifier)
		local state = hb.get_hudtable(identifier).hudstate[player:get_player_name()]
		if not state then
			return
		end
		saturation = math.min(saturation, state.max)
		hb.change_hudbar(player, identifier, saturation, nil)
		if saturation == 0 then
			hb.hide_hudbar(player, identifier)
		else
			hb.unhide_hudbar(player, identifier)
		end
	end,
	on_saturation_max_change = function(player, saturation_max)
		-- TODO: https://codeberg.org/Wuzzy/minetest_hudbars/issues/4
		-- local state = hb.get_hudbar_state(player, identifier)
		local state = hb.get_hudtable(identifier).hudstate[player:get_player_name()]
		if not state then
			return
		elseif state.value >= saturation_max then
			hb.change_hudbar(player, identifier, saturation_max, saturation_max)
		else
			hb.change_hudbar(player, identifier, nil, saturation_max)
		end
	end,
})
