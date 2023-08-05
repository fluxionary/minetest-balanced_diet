local S = balanced_diet.S

minetest.register_chatcommand("purge", {
	description = S("empty the contents of your stomach"),
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("you are not an active player")
		end
		balanced_diet.purge_eaten(player)
		return true, S("you empty the contents of your stomach")
	end,
})
