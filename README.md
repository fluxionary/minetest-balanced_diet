# balanced_diet

api for specifying multiple dimensions to eating

comes w/ submodule balanced_nutrients which provides one possible usage, and balanced_overridese, which applies
attributes to common food items

```lua
local speed_monoid = player_monoids.speed
local health_max_monoid = ...
local health_regen_monoid = ...
local stamina_max_monoid = ...
local stamina_regen_monoid = ...

balanced_diet.register_nutrient("fat", { -- raises maximum health, makes you slower
    apply_value = function(player, value)
        if value > 0 then
            health_max_monoid:add_change(player, value / 2, "balanced_nutrients:fat")
            speed_monoid:add_change(player, - value / 8, "balanced_nutrients:fat")
        else
            health_max_monoid:del_change(player, "balanced_nutrients:fat")
            speed_monoid:del_change(player, "balanced_nutrients:fat")
        end
    end,
})

balanced_diet.register_nutrient("protein", { -- raises health regeneration, makes you stronger
    apply_value = function(player, value)
        if value > 0 then
            health_regen_monoid:add_change(player, value / 2, "balanced_nutrients:protein")
            player_attributes.set_value(player, "strength", "balanced_nutrients:protein", value / 2)
        else
            health_regen_monoid:del_change(player, "balanced_nutrients:protein")
            player_attributes.set_value(player, "strength", "balanced_nutrients:protein")
        end
    end,
})

balanced_diet.register_nutrient("carbohydrate", { -- raises maximum stamina
    apply_value = function(player, value)
        if value > 0 then
            stamina_max_monoid:add_change(player, value / 2, "balanced_nutrients:carbohydrate")
        else
            stamina_max_monoid:del_change(player, "balanced_nutrients:carbohydrate")
        end
    end,
})
balanced_diet.register_nutrient("vitamin", {  -- rises stamina regeneration
    apply_value = function(player, value)
        if value > 0 then
            stamina_regen_monoid:add_change(player, value / 2, "balanced_nutrients:vitamin")
        else
            stamina_regen_monoid:del_change(player, "balanced_nutrients:vitamin")
        end
    end,
})
balanced_diet.register_nutrient("raw_meat", { -- poison for regular players, raises stamina/stamina regen for werewolves
    on_eat = function(player, value)
        if not petz.is_werewolf(player) then
            poison(player, value)  -- TODO: how would this be implemented?
        end
    end,
    apply_value = function(player, value)
        if value > 0 and petz.is_werewolf(player) then
            stamina_max_monoid:add_change(player, value / 2, "balanced_nutrients:raw_meat")
            stamina_regen_monoid:add_change(player, value / 2, "balanced_nutrients:raw_meat")
        else
            stamina_max_monoid:del_change(player, "balanced_nutrients:raw_meat")
            stamina_regen_monoid:del_change(player, "balanced_nutrients:raw_meat")
        end
    end,
})

balanced_diet.register_food("default:apple", {
    saturation = 2,
    duration = 300,
    nutrients = {
        carbohydrate = 2,
        vitamin = 2,
    }
})

balanced_diet.register_food("mobs:meat_raw", {
    saturation = 3,
    duration = 600,
    nutrients = {
        fat = 2,
        protein = 4,
        raw_meat = 4,
    }
})

balanced_diet.register_food("mobs:meat", {
    saturation = 4,
    duration = 1200,
    nutrients = {
        fat = 2,
        protein = 6,
    }
})

balanced_diet.register_food("bbq:bacon_cheeseburger", {
    saturation = 8,
    duration = 1200,
    nutrients = {
        fat = 6,
        protein = 6,
        carbohydrate = 2,
        vitamin = 4,
    }
})

```


### media sources

* balanced_diet_eat.[123].ogg - (C) sonictechtonic CC-BY-3.0 http://www.freesound.org/people/sonictechtonic/sounds/242215/

* balanced_diet_eat.[45].ogg - (C) rubberduck CC0 https://opengameart.org/content/80-cc0-creature-sfx
