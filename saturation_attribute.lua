local s = balanced_diet.settings

balanced_diet.saturation_attribute = player_attributes.register_bounded_attribute("saturation", {
	min = 0,
	base = 0,
	base_max = s.default_saturation_max,
})
