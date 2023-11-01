for _, mod in ipairs({ "hbhunger", "hunger_ng", "stamina" }) do
	if minetest.get_modpath(mod) then
		error("balanced_diet is not compatible w/ " .. mod)
	end
end

futil.check_version({ year = 2023, month = 11, day = 1 }) -- is_player

balanced_diet = fmod.create()

balanced_diet.dofile("saturation_attribute")
balanced_diet.dofile("api")
balanced_diet.dofile("globalstep")
balanced_diet.dofile("chatcommands")
balanced_diet.dofile("saturation_hud")
balanced_diet.dofile("diet_hud")
balanced_diet.dofile("overrides")
balanced_diet.dofile("callbacks")

balanced_diet.dofile("compat", "init")
