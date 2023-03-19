local S = balanced_diet.S

minetest.register_chatcommand("puke", {
	description = S("empty the contents of your stomach"),
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("you are not an active player")
		end
		balanced_diet.purge_saturation(player)
		return true, S("you empty the contents of your stomach")
	end,
})
