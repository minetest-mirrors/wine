-- add all drinks even if mods to brew them aren't active
wine:add_drink("wine", "Wine", true, 2, 5, 1)
wine:add_drink("beer", "Beer", true, 2, 8, 1)
wine:add_drink("rum", "Rum", true, 2, 5, 1)
wine:add_drink("tequila", "Tequila", true, 2, 3, 1)
wine:add_drink("wheat_beer", "Wheat Beer", true, 2, 8, 1)
wine:add_drink("sake", "Sake", true, 2, 3, 1)
wine:add_drink("bourbon", "Bourbon", true, 2, 3, 1)
wine:add_drink("vodka", "Vodka", true, 2, 3, 1)
wine:add_drink("cider", "Cider", true, 2, 6, 1)
wine:add_drink("mead", "Honey-Mead", true, 4, 5, 1)
wine:add_drink("mint", "Mint Julep", true, 4, 3, 1)
wine:add_drink("brandy", "Brandy", true, 3, 4, 1)
wine:add_drink("coffee_liquor", "Coffee Liquor", true, 3, 4, 1)
wine:add_drink("champagne", "Champagne", true, 4, 5, 1)
wine:add_drink("kefir", "Kefir", true, 4, 4, 0)


-- brandy recipe
minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "wine:glass_brandy",
	recipe = "wine:glass_wine"
})

-- Raw champagne alias
minetest.register_alias("wine:glass_champagne_raw", "wine:glass_champagne")

-- quick override to add wine to food group
minetest.override_item("wine:glass_wine", {
	groups = {
		food_wine = 1, vessel = 1, dig_immediate = 3,
		attached_node = 1, alcohol = 1, drink = 1
	}
})

-- quick override to add brandy to food group
minetest.override_item("wine:glass_brandy", {
	groups = {
		food_brandy = 1, vessel = 1, dig_immediate = 3,
		attached_node = 1, alcohol = 1, drink = 1
	}
})


-- wine mod adds tequila by default
wine:add_item({ {"wine:blue_agave", "wine:glass_tequila"} })

-- default game
if minetest.get_modpath("default") then

	wine:add_item({
		{"default:apple", "wine:glass_cider"},
		{"default:papyrus", "wine:glass_rum"}
	})
end

-- xdecor
if minetest.get_modpath("xdecor") then

	wine:add_item({ {"xdecor:honey", "wine:glass_mead"} })
end

-- mobs_animal
if minetest.get_modpath("mobs_animal")
or minetest.get_modpath("xanadu") then

	wine:add_item({
		{"mobs:honey", "wine:glass_mead"},
		{"mobs:glass_milk", "wine:glass_kefir"}
	})
end

-- farming
if minetest.get_modpath("farming") then

	wine:add_item({ {"farming:wheat", "wine:glass_wheat_beer"} })

	if farming.mod and (farming.mod == "redo" or farming.mod == "undo") then

		-- mint julep recipe
		minetest.register_craft({
			output = "wine:glass_mint",
			recipe = {
				{"farming:mint_leaf", "farming:mint_leaf", "farming:mint_leaf"},
				{"wine:glass_bourbon", "farming:sugar", ""}
			}
		})

		wine:add_item({
			{"farming:grapes", "wine:glass_wine"},
			{"farming:barley", "wine:glass_beer"},
			{"farming:rice", "wine:glass_sake"},
			{"farming:corn", "wine:glass_bourbon"},
			{"farming:baked_potato", "wine:glass_vodka"},
			{"farming:coffee_beans", "wine:glass_coffee_liquor"},
			{{"wine:glass_wine", "farming:sugar"}, "wine:glass_champagne"}
		})
	end
end

-- mineclone2
if minetest.get_modpath("mcl_core") then

	wine:add_item({
		{"mcl_core:apple", "wine:glass_cider"},
		{"mcl_core:reeds", "wine:glass_rum"},
		{"mcl_core:wheat_item", "wine:glass_wheat_beer"},
		{"mcl_core:potato_item_baked", "wine:glass_vodka"}
	})
end
