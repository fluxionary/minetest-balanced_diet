minetest.register_on_dieplayer(function(player)
	balanced_diet.purge_eaten(player)
end)
