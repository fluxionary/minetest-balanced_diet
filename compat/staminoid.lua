staminoid.register_on_exhaust_player(function(player, amount, reason)
	local current_stamina = staminoid.stamina_attribute:get(player)
	if current_stamina < amount then
		balanced_diet.advance_eaten_time(player, 10 * (amount - current_stamina))
	end
end)
