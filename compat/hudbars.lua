local S = balanced_diet.S
local s = balanced_diet.settings

local identifier = "balanced_diet:saturation"

hb.register_hudbar(
	identifier,
	0x000000,
	S("saturation"),
	{ bar = "[combine:2x16^[noalpha^[colorize:#FF0:255" },
	0,
	s.default_saturation_max,
	false
)

balanced_diet.register_hud({
	on_joinplayer = function(player, saturation, saturation_max)
		hb.init_hudbar(player, identifier, saturation, saturation_max, false)
	end,
	on_saturation_change = function(player, saturation)
		hb.change_hudbar(player, identifier, saturation, nil)
	end,
	on_saturation_max_change = function(player, saturation_max)
		hb.change_hudbar(player, identifier, nil, saturation_max)
	end,
})
