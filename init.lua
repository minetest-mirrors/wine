wine = {}

local path = minetest.get_modpath("wine")
local def = minetest.get_modpath("default")
local snd_d = def and default.node_sound_defaults()
local snd_g = def and default.node_sound_glass_defaults()


-- check for MineClone2
local mcl = minetest.get_modpath("mcl_core")

if mcl then
	snd_d = mcl_sounds.node_sound_glass_defaults()
	snd_g = mcl_sounds.node_sound_defaults()
end


-- check for Unified Inventory
local is_uninv = minetest.global_exists("unified_inventory") or false


-- is thirsty mod active
local thirsty_mod = minetest.get_modpath("thirsty")


-- translation support
local S
if minetest.get_translator then
	S = minetest.get_translator("wine")
elseif minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s, a, ...)
		if a == nil then
			return s
		end
		a = {a, ...}
		return s:gsub("(@?)@(%(?)(%d+)(%)?)", function(e, o, n, c)
			if e == ""then
				return a[tonumber(n)] .. (o == "" and c or "")
			else
				return "@" .. o .. n .. c
			end
		end)
	end
end
wine.S = S


-- Unified Inventory hints
if is_uninv then

	unified_inventory.register_craft_type("barrel", {
		description = "Barrel",
		icon = "wine_barrel.png",
		width = 2,
		height = 1
	})
end


-- fermentation list (drinks added in drinks.lua)
local ferment = {}


-- add item and resulting beverage to list
function wine:add_item(list)

	for n = 1, #list do

		local item = list[n]

		-- change old string recipe item into table
		if type(item[1]) == "string" then
			item = { {item[1]}, item[2] }
		end

		table.insert(ferment, item)

		-- if ui mod found add recipe
		if is_uninv then

			unified_inventory.register_craft({
				type = "barrel",
				items = item[1],
				output = item[2]
			})
		end
	end
end


-- add drink with bottle
function wine:add_drink(name, desc, has_bottle, num_hunger, num_thirst, alcoholic)

	-- glass
	minetest.register_node("wine:glass_" .. name, {
		description = S("Glass of " .. desc),
		drawtype = "plantlike",
		visual_scale = 0.5,
		tiles = {"wine_" .. name .. "_glass.png"},
		inventory_image = "wine_" .. name .. "_glass.png",
		wield_image = "wine_" .. name .. "_glass.png",
		paramtype = "light",
		is_ground_content = false,
		sunlight_propagates = true,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.15, -0.5, -0.15, 0.15, 0, 0.15}
		},
		groups = {
			vessel = 1, dig_immediate = 3,
			attached_node = 1, drink = 1, alcohol = alcoholic
		},
		sounds = snd_g,
		on_use = function(itemstack, user, pointed_thing)

			if user then

				if thirsty_mod then
					thirsty.drink(user, num_thirst)
				end

				return minetest.do_item_eat(num_hunger, nil,
						itemstack, user, pointed_thing)
			end
		end
	})

	-- bottle
	if has_bottle then

		minetest.register_node("wine:bottle_" .. name, {
			description = S("Bottle of " .. desc),
			drawtype = "plantlike",
			visual_scale = 0.7,
			tiles = {"wine_" .. name .. "_bottle.png"},
			inventory_image = "wine_" .. name .. "_bottle.png",
			paramtype = "light",
			sunlight_propagates = true,
			walkable = false,
			selection_box = {
				type = "fixed",
				fixed = {-0.15, -0.5, -0.15, 0.15, 0.25, 0.15}
			},
			groups = {dig_immediate = 3, attached_node = 1, vessel = 1},
			sounds = snd_d,
		})

		local glass = "wine:glass_" .. name

		minetest.register_craft({
			output = "wine:bottle_" .. name,
			recipe = {
				{glass, glass, glass},
				{glass, glass, glass},
				{glass, glass, glass}
			}
		})

		minetest.register_craft({
			output = glass .. " 9",
			recipe = {{"wine:bottle_" .. name}}
		})
	end
end


-- Wine barrel formspec
local function winebarrel_formspec(item_percent, brewing)

	return "size[8,9]"
	.. "image[0.25,0.5;5.5,4.25;wine_barrel_fs_bg.png]"
	.. "list[current_name;src;1.55,1.8;2,1;]"
	.. "list[current_name;dst;6.5,1.8;1,1;]"
	.. "list[current_player;main;0,5;8,4;]"
	.. "listring[current_name;dst]"
	.. "listring[current_player;main]"
	.. "listring[current_name;src]"
	.. "listring[current_player;main]"
	.. "image[5.2,1.8;1,1;wine_barrel_icon_bg.png^[lowpart:"
	.. item_percent .. ":wine_barrel_icon.png]"
	.. "tooltip[5,1.8;1,1;" .. brewing .. "]"
end


-- Wine barrel node
minetest.register_node("wine:wine_barrel", {
	description = S("Fermenting Barrel"),
	tiles = {"wine_barrel.png" },
	drawtype = "mesh",
	mesh = "wine_barrel.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		choppy = 2, oddly_breakable_by_hand = 1, flammable = 2,
		tubedevice = 1, tubedevice_receiver = 1
	},
	legacy_facedir_simple = true,

	on_place = minetest.rotate_node,

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		meta:set_string("formspec", winebarrel_formspec(0, ""))
		meta:set_string("infotext", S("Fermenting Barrel"))
		meta:set_float("status", 0.0)

		local inv = meta:get_inventory()

		inv:set_size("src", 2)
		inv:set_size("dst", 1)
	end,

	-- punch barrel to change old 1x slot barrels into 2x slot
	on_punch = function(pos, node, puncher, pointed_thing)

		local meta = minetest.get_meta(pos)
		local inv = meta and meta:get_inventory()
		local size = inv and inv:get_size("src")

		if size and size == 1 then
			inv:set_size("src", 2)
		end
	end,

	can_dig = function(pos,player)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if not inv:is_empty("dst")
		or not inv:is_empty("src") then
			return false
		end

		return true
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_put = function(
			pos, listname, index, stack, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if listname == "src" then
			return stack:get_count()
		elseif listname == "dst" then
			return 0
		end
	end,

	allow_metadata_inventory_move = function(
			pos, from_list, from_index, to_list, to_index, count, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)

		if to_list == "src" then
			return count
		elseif to_list == "dst" then
			return 0
		end
	end,

	on_metadata_inventory_put = function(pos)

		local timer = minetest.get_node_timer(pos)

		timer:start(5)
	end,

	tube = (function() if minetest.get_modpath("pipeworks") then return {

		-- using a different stack from defaut when inserting
		insert_object = function(pos, node, stack, direction)

			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local timer = minetest.get_node_timer(pos)

			if not timer:is_started() then
				timer:start(5)
			end

			return inv:add_item("src", stack)
		end,

		can_insert = function(pos,node,stack,direction)

			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()

			return inv:room_for_item("src", stack)
		end,

		-- the default stack, from which objects will be taken
		input_inventory = "dst",

		connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}

	} end end)(),

	on_timer = function(pos)

		local meta = minetest.get_meta(pos) ; if not meta then return end
		local inv = meta:get_inventory()

		-- is barrel empty?
		if not inv or inv:is_empty("src") then

			meta:set_float("status", 0.0)
			meta:set_string("infotext", S("Fermenting Barrel"))

			return false
		end

		-- does it contain any of the source items on the list?
		local has_item, recipe

		for n = 1, #ferment do

			recipe = ferment[n]

			-- check for first recipe item
			if inv:contains_item("src", ItemStack(recipe[1][1])) then

				has_item = true

				-- check for second recipe item if required
				if recipe[1][2] then

					if inv:contains_item("src", ItemStack(recipe[1][2])) then
						has_item = 2 -- used further on for item checks
					else
						has_item = false
					end
				end

				break
			end
		end

		if not has_item then

			meta:set_string("infotext", S("Fermenting Barrel") .. " (X)")

			return false
		end

		-- is there room for additional fermentation?
		if not inv:room_for_item("dst", recipe[2]) then

			meta:set_string("infotext", S("Fermenting Barrel (FULL)"))

			return true
		end

		local status = meta:get_float("status")

		-- fermenting (change status)
		if status < 100 then

			meta:set_string("infotext", S("Fermenting Barrel (@1% Done)", status))
			meta:set_float("status", status + 5)

			local desc = minetest.registered_items[recipe[2]].description or ""

			meta:set_string("formspec", winebarrel_formspec(status, S("Brewing: @1", desc)))
		else
			inv:remove_item("src", recipe[1][1])

			-- remove 2nd recipe item if found
			if has_item == 2 then
				inv:remove_item("src", recipe[1][2])
			end

			inv:add_item("dst", recipe[2])

			meta:set_float("status", 0,0)
			meta:set_string("formspec", winebarrel_formspec(0, ""))
		end

		if inv:is_empty("src") then
			meta:set_float("status", 0.0)
			meta:set_string("infotext", S("Fermenting Barrel"))
		end

		return true
	end
})


-- wine barrel craft recipe (with mineclone2 check)
local ingot = mcl and "mcl_core:iron_ingot" or "default:steel_ingot"

minetest.register_craft({
	output = "wine:wine_barrel",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{ingot, "", ingot},
		{"group:wood", "group:wood", "group:wood"}
	}
})


-- LBMs to start timers on existing, ABM-driven nodes
minetest.register_lbm({
	name = "wine:barrel_timer_init",
	nodenames = {"wine:wine_barrel"},
	run_at_every_load = false,
	action = function(pos)
		minetest.get_node_timer(pos):start(5)
	end
})


-- add agave plant and functions
dofile(path .. "/agave.lua")

-- add drink nodes and recipes
dofile(path .. "/drinks.lua")

-- add lucky blocks
if minetest.get_modpath("lucky_block") then
	dofile(path .. "/lucky_block.lua")
end


print ("[MOD] Wine loaded")
