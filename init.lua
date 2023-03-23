if minetest.get_modpath("stamina") then
	error("balanced_diet is not compatible with stamina")
end

futil.check_version({ year = 2023, month = 3, day = 21 })

balanced_diet = fmod.create()

balanced_diet.dofile("api")
balanced_diet.dofile("callbacks")
balanced_diet.dofile("chatcommands")
balanced_diet.dofile("saturation_hud")
balanced_diet.dofile("eaten_hud")
balanced_diet.dofile("nutrients_hud")
balanced_diet.dofile("overrides")

balanced_diet.dofile("compat", "init")
