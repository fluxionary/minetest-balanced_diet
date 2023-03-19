if minetest.get_modpath("stamina") then
	error("balanced_diet is not compatible with stamina")
end

balanced_diet = fmod.create()

balanced_diet.dofile("api")
balanced_diet.dofile("callbacks")
balanced_diet.dofile("chatcommands")
balanced_diet.dofile("hud")
balanced_diet.dofile("overrides")

balanced_diet.dofile("compat", "init")
