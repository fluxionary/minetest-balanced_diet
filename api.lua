local f = string.format

local S = balanced_diet.S
local s = balanced_diet.settings

balanced_diet.registered_nutrients = {}

local function gamma(v)
	return math.max(0, math.min(math.pow(v, s.nutrient_decay_gamma), 1))
end

local eaten_key = "balanced_diet:eaten"
local last_set_key = "balanced_diet:last_set"

local function get_eaten(meta, now)
	local eaten = minetest.deserialize(meta:get_string(eaten_key)) or {}
	if now then
		local last_set = meta:get_int(last_set_key)
		if last_set > 0 and now > last_set then
			local elapsed = now - last_set
			for food, remaining in pairs(eaten) do
				if elapsed >= remaining then
					eaten[food] = nil
				else
					eaten[food] = remaining - elapsed
				end
			end
			meta:set_string(eaten_key, minetest.serialize(eaten), now)
		end
		meta:set_int(last_set_key, now)
	end
	for food in pairs(eaten) do
		if not balanced_diet.is_food(food) then
			eaten[food] = nil
		end
	end
	return eaten
end

function balanced_diet.get_eaten(player, now)
	return get_eaten(player:get_meta(), now)
end

local function set_eaten(meta, eaten, now)
	for food, time_remaining in pairs(eaten) do
		if not balanced_diet.is_food(food) then
			error(f("attempting to set eaten w/ non-food item %q", food))
		end
		if time_remaining <= 0 then
			eaten[food] = nil
		end
	end
	if futil.table.is_empty(eaten) then
		meta:set_string(eaten_key, "")
	else
		meta:set_string(eaten_key, minetest.serialize(eaten))
	end
	if now then
		meta:set_int(last_set_key, now)
	end
end

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	-- start the timer again
	meta:set_int(last_set_key, os.time())
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	local meta = player:get_meta()
	if timed_out then
		-- refund time during timeout (60 seconds)
		-- note that this doesn't refund foods which might have expired during the timeout, which is tricky
		local eaten = get_eaten(meta)
		for food, remaining in pairs(eaten) do
			eaten[food] = remaining + 60
		end
		set_eaten(meta, eaten) -- don't change last_set
	end

	-- make sure food is used up
	get_eaten(meta, os.time())
end)

function balanced_diet.register_nutrient(name, def)
	if balanced_diet.registered_nutrients[name] then
		error("attempt to re-register nutrient " .. name)
	end
	def.name = name
	def.description = def.description or def.name
	balanced_diet.registered_nutrients[name] = def
end

function balanced_diet.override_nutrient(name, def)
	if not balanced_diet.registered_nutrients[name] then
		error("attempt to override non-existing nutrient " .. name)
	end
	if def.name then
		error("you can't rename a nutrient")
	end
	futil.table.set_all(balanced_diet.registered_nutrients[name], def)
end

function balanced_diet.is_food(item_or_stack)
	local itemstack = ItemStack(item_or_stack)
	local def = itemstack:get_definition()
	return def and def._balanced_diet
end

function balanced_diet.get_food_def(item_or_stack)
	local stack
	if type(item_or_stack) == "string" then
		stack = ItemStack(item_or_stack)
	else
		stack = item_or_stack
	end
	local meta = stack:get_meta()
	local override = meta:get("_balanced_diet")
	if override then
		return minetest.deserialize(override)
	end
	return stack:get_definition()._balanced_diet
end

local function build_description(item_name, food_def)
	local def = minetest.registered_items[item_name]
	local orig_description
	if def._balanced_diet_orig_description then
		orig_description = def._balanced_diet_orig_description
	else
		local item_stack = ItemStack(item_name)
		orig_description = item_stack:get_description()
		minetest.override_item(item_name, {
			_balanced_diet_orig_description = orig_description,
		})
	end
	local parts = { orig_description }
	table.insert_all(parts, {
		S("food saturation: @1", food_def.saturation),
		S("food duration: @1s", food_def.duration),
	})
	for nutrient, value in futil.table.pairs_by_key(food_def.nutrients or {}) do
		table.insert(parts, S("@1 = @2", balanced_diet.registered_nutrients[nutrient].description, value))
	end
	return table.concat(parts, "\n"), def.short_description or orig_description
end

function balanced_diet.register_food(item_name, food_def)
	local def = minetest.registered_items[item_name]
	if not def then
		error("attempt to register non-existent item as a food " .. item_name)
	end
	if def._balanced_diet then
		error("attempt to re-register food " .. item_name)
	end

	food_def = table.copy(food_def)
	food_def.duration = food_def.duration or s.default_food_duration
	food_def.saturation = food_def.saturation or s.default_food_saturation

	local groups = table.copy(def.groups or {})
	groups.food = 1
	for nutrient, value in pairs(food_def.nutrients or {}) do
		if not balanced_diet.registered_nutrients[nutrient] then
			-- TODO: this should optionally just be a warning
			error(f("unknown nutrient %q when defining food %q", nutrient, item_name))
		end
		groups["nutrient_" .. nutrient] = value
	end

	local description, short_description = build_description(item_name, food_def)

	minetest.override_item(item_name, {
		_balanced_diet = food_def,
		description = description,
		short_description = short_description,
		groups = groups,
		on_use = balanced_diet.item_eat(),
	})
end

function balanced_diet.override_food(item_name, overrides)
	local def = minetest.registered_items[item_name]
	if not def then
		error("attempt to override non-existent item " .. item_name)
	end
	if not def._balanced_diet then
		error("attempt to override unregistered food " .. item_name)
	end
	local groups = table.copy(def.groups)

	-- clear old nutrient groups
	for group in pairs(groups) do
		if group:match("^nutrient_") then
			groups[group] = nil
		end
	end

	for nutrient, value in pairs(overrides.nutrients or {}) do
		if not balanced_diet.registered_nutrients[nutrient] then
			-- TODO: this should optionally just be a warning
			error(f("unknown nutrient %q when defining food %q", nutrient, item_name))
		end
		groups["nutrient_" .. nutrient] = value
	end

	local food_def = table.copy(def._balanced_diet)
	futil.table.set_all(food_def, overrides)

	local description, short_description = build_description(item_name, food_def)

	minetest.override_item(item_name, {
		_balanced_diet = food_def,
		description = description,
		short_description = short_description,
		groups = groups,
	})
end

balanced_diet.registered_on_item_eats = {}

function balanced_diet.register_on_item_eat(callback)
	table.insert(balanced_diet.registered_on_item_eats, callback)
end

balanced_diet.registered_after_item_eats = {}

function balanced_diet.register_after_item_eat(callback)
	table.insert(balanced_diet.registered_after_item_eats, callback)
end

function balanced_diet.check_nutrient_value(player, nutrient, now)
	if not minetest.is_player(player) then
		return
	end
	local nutrient_def = balanced_diet.registered_nutrients[nutrient]
	if not nutrient_def then
		error(f("unknown nutrient %q", nutrient))
	end

	if not now then
		now = os.time()
	end

	local meta = player:get_meta()
	local eaten = get_eaten(meta, now)

	local value = 0
	for food, remaining in pairs(eaten) do
		local food_def = balanced_diet.get_food_def(food)
		local full_value = food_def.nutrients[nutrient] or 0
		local remaining_value = full_value * gamma(remaining / food_def.duration)
		value = value + remaining_value
	end
	return value
end

balanced_diet.registered_on_saturation_max_changes = {}

function balanced_diet.register_on_saturation_max_change(callback)
	table.insert(balanced_diet.registered_on_saturation_max_changes, callback)
end

function balanced_diet.get_saturation_max(player)
	if not minetest.is_player(player) then
		return
	end
	local meta = player:get_meta()
	return meta:get_float("balanced_diet:saturation_max")
end

function balanced_diet.set_saturation_max(player, saturation_max)
	if not minetest.is_player(player) then
		return
	end
	local meta = player:get_meta()
	local key = "balanced_diet:saturation_max"
	local old_max = meta:get_float("balanced_diet:saturation_max")
	meta:set_float(key, saturation_max)
	if saturation_max ~= old_max then
		for _, callback in ipairs(balanced_diet.registered_on_saturation_max_changes) do
			callback(player, saturation_max, old_max)
		end
	end
end

local current_saturation_cache = {}
minetest.register_globalstep(function()
	current_saturation_cache = {}
end)

function balanced_diet.get_current_saturation(player, now)
	if not minetest.is_player(player) then
		return 0
	end

	if not now then
		now = os.time()
	end

	local player_name = player:get_player_name()
	local key = f("%s:%s", player_name, now)
	local total_saturation = current_saturation_cache[key]

	if total_saturation then
		return total_saturation
	end

	local meta = player:get_meta()
	local eaten = get_eaten(meta, now)
	total_saturation = 0

	for food, remaining in pairs(eaten) do
		local food_def = balanced_diet.get_food_def(food)
		if not food_def then
			error(f("no def for food %q?! %s", food, dump(eaten)))
		end
		local remaining_saturation = food_def.saturation * remaining / food_def.duration
		total_saturation = total_saturation + remaining_saturation
	end

	local saturation_max = balanced_diet.get_saturation_max(player)
	if total_saturation > saturation_max then
		balanced_diet.log("error", "saturation %s is greater than max %s", total_saturation, saturation_max)
		total_saturation = saturation_max
	end

	current_saturation_cache[key] = total_saturation

	return total_saturation
end

function balanced_diet.purge_eaten(player)
	if not minetest.is_player(player) then
		return
	end
	local meta = player:get_meta()
	set_eaten(meta, {}, os.time())
end

function balanced_diet.advance_eaten_time(player, amount)
	if not minetest.is_player(player) then
		return
	end
	local meta = player:get_meta()
	local eaten = get_eaten(meta)
	for food, remaining_time in pairs(eaten) do
		if remaining_time > amount then
			eaten[food] = remaining_time - amount
		else
			eaten[food] = nil
		end
	end
	set_eaten(meta, eaten)
end

balanced_diet.registered_appetite_checks = {}
function balanced_diet.register_appetite_check(callback)
	table.insert(balanced_diet.registered_appetite_checks, callback)
end

function balanced_diet.check_appetite_for(player, itemstack, now)
	if not minetest.is_player(player) then
		return false, S("you are not a player")
	end

	local def = itemstack:get_definition()
	if not def then
		return false, S("this is not food")
	end

	local food_def = balanced_diet.get_food_def(itemstack)
	if not food_def then
		return false, S("this is not food")
	end

	if not now then
		now = os.time()
	end

	for i = 1, #balanced_diet.registered_appetite_checks do
		local result, reason = balanced_diet.registered_appetite_checks[i](player, itemstack, now)
		if result == false then
			return false, (reason or S("appetite check failed w/out reason."))
		end
	end

	local meta = player:get_meta()
	local food_name = itemstack:get_name()
	local food_description = futil.get_safe_short_description(itemstack)
	local food_saturation = food_def.saturation
	local saturation_max = balanced_diet.get_saturation_max(player)
	local saturation_after_eating = 0

	local eaten = get_eaten(meta, now)
	for eaten_food, remaining in pairs(eaten) do
		if eaten_food == food_name then
			if remaining > food_def.duration * s.top_up_at then
				return false, S("you can't eat any more @1 right now.", food_description)
			else
				saturation_after_eating = saturation_after_eating + food_saturation
			end
		else
			local other_food_def = balanced_diet.get_food_def(eaten_food)
			local remaining_saturation = other_food_def.saturation * remaining / other_food_def.duration
			saturation_after_eating = saturation_after_eating + remaining_saturation
		end
	end

	if saturation_after_eating > saturation_max then
		return false, S("you are too full to eat @1 right now.", food_description)
	end

	return true, nil, eaten
end

local function handle_replace_with(eater, itemstack, replace_with)
	local inv = eater:get_inventory()
	if type(replace_with) == "string" then
		local remainder = itemstack:add_item(replace_with)
		eater:set_wielded_item(itemstack)
		if not remainder:is_empty() then
			remainder = inv:add_item("main", replace_with)
			if not remainder:is_empty() then
				local pos = eater:get_pos()
				minetest.add_item(pos, remainder)
			end
		end
	else
		for _, replace_item in ipairs(replace_with) do
			local remainder = itemstack:add_item(replace_item)
			eater:set_wielded_item(itemstack)
			if not remainder:is_empty() then
				remainder = inv:add_item("main", replace_item)
				if not remainder:is_empty() then
					local pos = eater:get_pos()
					minetest.add_item(pos, remainder)
				end
			end
		end
	end
	return itemstack
end

function balanced_diet.do_item_eat(itemstack, eater, pointed_thing)
	if not minetest.is_player(eater) then
		return
	end

	local def = itemstack:get_definition()
	if not def then
		return
	end

	local food_def = balanced_diet.get_food_def(itemstack)
	if not food_def then
		return
	end

	local player_name = eater:get_player_name()
	local now = os.time()

	local food_name = itemstack:peek_item():to_string()
	local has_appetite, reason, eaten = balanced_diet.check_appetite_for(eater, itemstack, now)

	if not has_appetite then
		if reason then
			balanced_diet.log("action", "%s tries to eat %s but cannot", player_name, food_name)
			minetest.chat_send_player(player_name, reason)
		end
		return
	end

	balanced_diet.log("action", "%s eats %s", player_name, food_name)

	for _, callback in ipairs(balanced_diet.registered_on_item_eats) do
		local result = callback(eater, itemstack, pointed_thing)
		if result then
			return result
		end
	end

	if not minetest.is_creative_enabled(player_name) then
		itemstack:take_item()
		eater:set_wielded_item(itemstack)
	end

	local meta = eater:get_meta()
	eaten[food_name] = food_def.duration
	set_eaten(meta, eaten, now)

	-- see https://github.com/minetest/minetest/pull/13286/files
	if food_def.replace_with then
		itemstack = handle_replace_with(eater, itemstack, food_def.replace_with)
	end

	if def.sound and def.sound.eat then
		minetest.sound_play(def.sound.eat, { pos = eater:get_pos(), max_hear_distance = 16 }, true)
	else
		minetest.sound_play("balanced_diet_eat", { pos = eater:get_pos(), max_hear_distance = 16 }, true)
	end

	for _, callback in ipairs(balanced_diet.registered_after_item_eats) do
		callback(eater, itemstack, pointed_thing)
	end

	return itemstack
end

function balanced_diet.item_eat()
	return function(itemstack, eater, pointed_thing)
		return balanced_diet.do_item_eat(itemstack, eater, pointed_thing)
	end
end
