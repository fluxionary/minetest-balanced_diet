local old_do_item_eat = minetest.do_item_eat

function minetest.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	if balanced_diet.is_food(itemstack) then
		return balanced_diet.do_item_eat(user, itemstack, pointed_thing)
	else
		return old_do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	end
end
