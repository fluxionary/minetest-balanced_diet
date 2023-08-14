
```lua
-- register a new nutrient
balanced_diet.register_nutrient(name, {
    description = S(name),
    on_eat = function(player, value)
        -- optional. called once when a food item is eaten.
    end,
    apply_value = function(player, value)
        -- how to apply the nutrient value to the player. the nutrient value is a function of what the player has
        -- eaten, how much of the nutrient individual foods provide, and how long ago they ate the item.
    end,
})

-- override a nutrient
balanced_diet.override_nutrient(name, def)  -- as above
```

* `balanced_diet.is_food(item_or_stack)`

  returns true if the item is a registered food.

```lua
-- register an *existing item* as a food
balanced_diet.register_food("default:apple", {
	-- item_eat(2)
	category = "apple",  -- other apples cannot be eaten at the same time.
	replace_with = "default:stick",
	saturation = 1,  -- adds this amount to the player's saturation
	duration = 300,  -- how long the food lasts.
	nutrients = {
		carbohydrate = 1,
		vitamin = 1,
	},
	after_eat = function(itemstack, eater, pointed_thing)
		-- called after an item is eaten, and can trigger food-specific effects
        -- return true to prevent taking an item from the stack.
	end,
})

-- override a food
balanced_diet.override_food(item_name, overrides)
```

```lua
balanced_diet.register_on_item_eat(function(eater, itemstack, pointed_thing)
    -- if this returns true, this will block the item from being eaten via the normal mechanic
end)
```

```lua
balanced_diet.register_after_item_eat(function(eater, itemstack, pointed_thing)
    -- called *after* a food is eaten. return true to prevent taking an item from the stack.
end)

```
