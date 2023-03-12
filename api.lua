local f = string.format

local default_saturation = 0 -- TODO settings
local default_duration = 300 -- TODO settings
local max_saturation = 20 -- TODO settings

balanced_diet.registered_nutrients = {}

local function values_key(nutrient)
	return f("balanced_diet:values:%s", nutrient)
end

function balanced_diet.register_nutrient(name, def)
	if balanced_diet.registered_nutrients[name] then
		error("attempt to re-register nutrient " .. name)
	end
	def.name = name
	balanced_diet.registered_nutrients[name] = def
end

function balanced_diet.override_nutrient(name, def)
	if not balanced_diet.registered_nutrients[name] then
		error("attempt to override non-existing nutrient " .. name)
	end
	if def.name then
		error("TODO: fill in message")
	end
	futil.table.set_all(balanced_diet.registered_nutrients[name], def)
end

function balanced_diet.is_food(item_or_stack)
	local itemstack = ItemStack(item_or_stack)
	local def = itemstack:get_definition()
	return def and def._balanced_diet
end

function balanced_diet.register_food(item_name, properties)
	local def = minetest.registered_items[item_name]
	if not def then
		error("attempt to register non-existent item as a food " .. item_name)
	end
	if def._balanced_diet then
		error("attempt to re-register food " .. item_name)
	end
	for nutrient in pairs(properties.nutrients or {}) do
		if not balanced_diet.registered_nutrients[nutrient] then
			error(f("unknown nutrient %q when defining food %q", nutrient, item_name))
		end
	end
	def._balanced_diet = properties
end

function balanced_diet.override_food(item_name, properties)
	local def = minetest.registered_items[item_name]
	if not def then
		error("attempt to override non-existent item " .. item_name)
	end
	if not def._balanced_diet then
		error("attempt to override unregistered food " .. item_name)
	end
	for nutrient in pairs(properties.nutrients or {}) do
		if not balanced_diet.registered_nutrients[nutrient] then
			error(f("unknown nutrient %q when defining food %q", nutrient, item_name))
		end
	end
	futil.table.set_all(def._balanced_diet, properties)
end

balanced_diet.registered_on_item_eats = {}

function balanced_diet.register_on_item_eat(callback)
	table.insert(balanced_diet.registered_on_item_eats, callback)
end

function balanced_diet.check_nutrient_value(player, nutrient, now)
	if not minetest.is_player(player) then
		return
	end
	local nutrient_def = balanced_diet.registered_nutrients[nutrient]
	if not nutrient_def then
		error(f("unknown nutrient %q", nutrient))
	end
	local meta = player:get_meta()
	local key = values_key(nutrient)
	local consumed = minetest.deserialize(meta:get(key)) or {}
	if nutrient_def.compose then
		return nutrient_def.compose(consumed)
	else
		local removed = false
		local value = 0
		local i = #consumed
		while i > 0 do
			local full_value, duration, expires = unpack(consumed[i])
			if now >= expires then
				table.remove(consumed, i)
				removed = true
			else
				if nutrient_def.evaluate then
					value = value + nutrient_def.evaluate(full_value, duration, expires)
				else
					value = value + (full_value * (expires - now) / duration)
				end
				i = i + 1
			end
		end
		if removed then
			meta:set_string(key, minetest.serialize(consumed))
		end
		return value
	end
end

function balanced_diet.consume_nutrient(player, nutrient, value, duration)
	if not minetest.is_player(player) then
		return
	end
	local nutrient_def = balanced_diet.registered_nutrients[nutrient]
	if not nutrient_def then
		error(f("unknown nutrient %q", nutrient))
	end
	local consume = true
	if nutrient_def.on_eat and nutrient_def.on_eat(player, value, duration) == false then
		consume = false
	end
	if consume then
		local meta = player:get_meta()
		local key = values_key(nutrient)
		local consumed = minetest.deserialize(meta:get(key)) or {}
		local expires = os.time() + duration
		table.insert(consumed, { value, duration, expires })
		meta:set_string(key, minetest.serialize(consumed))
	end
end

function balanced_diet.get_saturation(player, now)
	if not minetest.is_player(player) then
		return
	end
	local meta = player:get_meta()
	local values = minetest.deserialize(meta:get("balanced_diet:saturation")) or {}
	local total_saturation = 0
	local removed = false
	local i = #values
	while i > 0 do
		local saturation, duration, expires = unpack(values[i])
		if now >= expires then
			table.remove(values, i)
			removed = true
		else
			total_saturation = total_saturation + (saturation * (expires - now) / duration)
		end
	end
	if removed then
		meta:set_string("balanced_diet:saturation", minetest.serialize(values))
	end
end

function balanced_diet.can_consume(player, now, saturation)
	if not minetest.is_player(player) then
		return
	end
	return balanced_diet.get_saturation(player, now) + saturation <= max_saturation
end

function balanced_diet.increase_saturation(player, now, saturation, duration)
	if not minetest.is_player(player) then
		return
	end
	local meta = player:get_meta()
	local values = minetest.deserialize(meta:get("balanced_diet:saturation")) or {}
	local expires = now + duration
	table.insert(values, { saturation, duration, expires })
	meta:set_string("balanced_diet:saturation", minetest.serialize(values))
end

function balanced_diet.do_item_eat(player, itemstack, pointed_thing)
	for _, callback in ipairs(balanced_diet.registered_on_item_eats) do
		local result = callback(player, itemstack, pointed_thing)
		if result then
			return result
		end
	end

	if not minetest.is_player(player) then
		return itemstack
	end

	local item_name = itemstack:get_name()
	local def = minetest.registered_items[item_name]
	if not def then
		return itemstack
	end

	local properties = def._balanced_diet
	if not properties then
		return itemstack
	end

	local player_name = player:get_player_name()
	local saturation = properties.saturation or default_saturation

	if balanced_diet.can_consume(player, saturation) then
		minetest.chat_send_player(
			player_name,
			f("you are too full to eat %q right now.", futil.get_safe_short_description(itemstack))
		)
		return itemstack
	end

	if not minetest.is_creative_enabled(player_name) then
		itemstack:take_item()
		player:set_wielded_item(itemstack)
	end

	local duration = properties.duration or default_duration
	balanced_diet.increase_saturation(saturation, duration)

	if properties.replace_with then
		local inv = player:get_inventory()
		local remainder = inv:add_item("main", properties.replace_with)
		if not remainder:is_empty() then
			local pos = player:get_pos()
			minetest.add_item(pos, remainder)
		end
	end

	if def.sound and def.sound.eat then
		minetest.sound_play(def.sound.eat, { pos = player:get_pos(), max_hear_distance = 16 }, true)
	else
		minetest.sound_play("balanced_diet_eat", { pos = player:get_pos(), max_hear_distance = 16 }, true)
	end

	for nutrient, value in (properties.nutrients or {}) do
		if not balanced_diet.registered_nutrients[nutrient] then
			error(f("unknown nutrient %q in food %q", nutrient, item_name))
		end
		balanced_diet.consume_nutrient(player, nutrient, value, duration)
	end
end

function balanced_diet.item_eat()
	return function(itemstack, user, pointed_thing)
		return balanced_diet.do_item_eat(user, itemstack, pointed_thing)
	end
end
