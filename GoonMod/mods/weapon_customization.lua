
-- Mod Definition
local Mod = class( BaseMod )
Mod.id = "WeaponCustomization"
Mod.Name = "Weapon Visual Customization"
Mod.Desc = "Visually customize your weapons using materials, patterns, and colour swatches"
Mod.Requirements = {}
Mod.Incompatibilities = {}

Hooks:Add("GoonBaseRegisterMods", "GoonBaseRegisterMutators_" .. Mod.id, function()
	GoonBase.Mods:RegisterMod( Mod )
end)

if not Mod:IsEnabled() then
	return
end

-- Weapon Customization
GoonBase.WeaponCustomization = GoonBase.WeaponCustomization or {}
local WeaponCustomization = GoonBase.WeaponCustomization
WeaponCustomization.MenuId = "goonbase_weapon_customization_menu"
WeaponCustomization._update_queue = {}

WeaponCustomization._default_part_visual_blueprint =  {
	["materials"] = "no_material",
	["textures"] = "no_color_no_material",
	["colors"] = "white_solid",
}

WeaponCustomization._mod_overrides_download_location = "https://github.com/JamesWilko/GoonMod/archive/WeaponCustomizerModOverrides.zip"

-- Load extras
SafeDoFile( GoonBase.Path .. "mods/weapon_customization_menus.lua" )
SafeDoFile( GoonBase.Path .. "mods/weapon_customization_part_data.lua" )

-- Options
if GoonBase.Options.WeaponCustomization == nil then
	GoonBase.Options.WeaponCustomization = {}
	GoonBase.Options.WeaponCustomization.Color1R = 1
	GoonBase.Options.WeaponCustomization.Color1G = 1
	GoonBase.Options.WeaponCustomization.Color1B = 1
	GoonBase.Options.WeaponCustomization.Color2R = 1
	GoonBase.Options.WeaponCustomization.Color2G = 1
	GoonBase.Options.WeaponCustomization.Color2B = 1
	GoonBase.Options.WeaponCustomization.Pattern = 1
	GoonBase.Options.WeaponCustomization.Material = 1
	GoonBase.Options.WeaponCustomization.HideDiffuse = false
	GoonBase.Options.WeaponCustomization.HideNormal = false
	GoonBase.Options.WeaponCustomization.TempShownOverridesNotInstalled = false
end

-- Menu
Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenus_" .. Mod:ID(), function(menu_manager, menu_nodes)
	MenuHelper:NewMenu( WeaponCustomization.MenuId )
end)

Hooks:Add("MenuManagerSetupGoonBaseMenu", "MenuManagerSetupGoonBaseMenu_" .. Mod:ID(), function(menu_manager, menu_nodes)

	-- Submenu Button
	MenuHelper:AddButton({
		id = "weapon_customization_menu_button",
		title = "Options_WeaponCustomizationName",
		desc = "Options_WeaponCustomizationDesc",
		next_node = WeaponCustomization.MenuId,
		menu_id = "goonbase_options_menu",
	})

	-- Menu
	MenuCallbackHandler.wc_download_mod_overrides = function(this, item)
		if SystemInfo:platform() == Idstring("WIN32") then
			os.execute( "explorer " .. WeaponCustomization._mod_overrides_download_location )
		end
	end

	MenuCallbackHandler.clear_weapon_visual_customizations = function(this, item)
		WeaponCustomization:ShowClearDataConfirmation()
	end

	MenuHelper:AddButton({
		id = "weapon_customization_download_mod_overrides",
		title = "WeaponCustomization_DownloadModOverridesManual",
		desc = "WeaponCustomization_DownloadModOverridesManualDesc",
		callback = "wc_download_mod_overrides",
		menu_id = WeaponCustomization.MenuId,
		priority = 100,
	})

	MenuHelper:AddDivider({
		id = "weapon_customization_divider1",
		menu_id = WeaponCustomization.MenuId,
		size = 16,
		priority = 99,
	})

	MenuHelper:AddButton({
		id = "weapon_customization_clear_data",
		title = "WeaponCustomization_ClearDataButton",
		desc = "WeaponCustomization_ClearDataButtonDesc",
		callback = "clear_weapon_visual_customizations",
		menu_id = WeaponCustomization.MenuId,
		priority = 98,
	})

end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_" .. Mod:ID(), function(menu_manager, mainmenu_nodes)
	local menu_id = WeaponCustomization.MenuId
	local data = {
		area_bg = "none"
	}
	mainmenu_nodes[menu_id] = MenuHelper:BuildMenu( menu_id, data )
end)

-- Hooks
Hooks:Add("BlackMarketGUIOnPreviewWeapon", "BlackMarketGUIOnPreviewWeapon_WeaponCustomization", function(gui, data)
	if not WeaponCustomization._is_previewing then
		WeaponCustomization._is_previewing = {
			["previewing"] = true,
			["data"] = data,
		}
	end
end)

Hooks:Add("MenuSceneManagerSpawnedItemWeapon", "MenuSceneManagerSpawnedItemWeapon_" .. Mod:ID(), function(menu, factory_id, blueprint, texture_switches, spawned_unit)

	WeaponCustomization._menu_weapon_preview_unit = spawned_unit

	if WeaponCustomization._is_previewing then
		local data = WeaponCustomization._is_previewing["data"]
		WeaponCustomization:LoadCurrentWeaponCustomization( data )
		WeaponCustomization._is_previewing = nil
	end

end)

Hooks:Add("MenuSceneManagerSpawnedMeleeWeapon", "MenuSceneManagerSpawnedMeleeWeapon_" .. Mod:ID(), function(menu, melee_weapon_id, spawned_unit)
	WeaponCustomization._menu_weapon_preview_unit = spawned_unit
end)

Hooks:Add("NewRaycastWeaponBasePostAssemblyComplete", "NewRaycastWeaponBasePostAssemblyComplete_WeaponCustomization", function(weapon, clbk, parts, blueprint)
	WeaponCustomization:LoadEquippedWeaponCustomizations( weapon )
end)

Hooks:Add("PlayerStandardStartActionEquipWeapon", "PlayerStandardStartActionEquipWeapon_WeaponCustomization", function(ply, t)
	if managers.player:local_player() then
		WeaponCustomization:LoadEquippedWeaponCustomizations( managers.player:local_player():inventory():equipped_unit():base() )
	end
end)

Hooks:Add("PlayerStandardStartMaskUp", "PlayerStandardStartMaskUp_WeaponCustomization", function(ply, data)
	if managers.player:local_player() then
		WeaponCustomization:LoadEquippedWeaponCustomizations( managers.player:local_player():inventory():equipped_unit():base() )
	end
end)

Hooks:Add("BlackMarketGUIOnPopulateMaskMods", "BlackMarketGUIOnPopulateMaskMods_WeaponCustomization", function(gui, data)

	-- Create "no material" data
	if not tweak_data.blackmarket.materials.no_material then

		tweak_data.blackmarket.materials.no_material = {}
		tweak_data.blackmarket.materials.no_material.name_id = "bm_mtl_no_material"
		tweak_data.blackmarket.materials.no_material.texture = "units/payday2/matcaps/matcap_plastic_df"
		tweak_data.blackmarket.materials.no_material.value = 0
		tweak_data.blackmarket.materials.no_material.weapon_only = true

	end

	-- Inject "no material" material
	local no_material_index = nil
	for k, v in ipairs( data.on_create_data ) do
		if v.id == "no_material" then
			no_material_index = k
			break
		end
	end

	if no_material_index then
		table.remove( data.on_create_data, no_material_index )
	end

	if managers.blackmarket._customizing_weapon and data.category == "materials" then

		local clear_material = deep_clone( data.on_create_data[1] )
		clear_material.id = "no_material"
		clear_material.bitmap_texture_override = "plastic"
		clear_material.free_of_charge = true

		table.insert( data.on_create_data, 1, clear_material )

	end

end)

-- Functions
function WeaponCustomization:AddCustomizablePart( part_id )
	local tbl = clone( WeaponCustomization._default_part_visual_blueprint )
	tbl.id = part_id
	tbl.modifying = false
	table.insert( managers.blackmarket._customizing_weapon_parts, tbl )
end

function WeaponCustomization:CreateCustomizablePartsList( weapon, is_melee )

	-- Clear weapon parts
	managers.blackmarket._customizing_weapon_parts = {}

	if is_melee then
		return
	end

	local blueprint_parts = {}

	-- Add blueprint parts
	for k, v in ipairs( weapon.blueprint ) do

		-- Add blueprint part
		WeaponCustomization:AddCustomizablePart( v )
		blueprint_parts[v] = true

		-- Check if part has adds
		local part_data = tweak_data.weapon.factory.parts[v]
		if part_data and part_data.adds then
			for x, y in pairs( part_data.adds ) do
				WeaponCustomization:AddCustomizablePart( y )
				blueprint_parts[y] = true
			end
		end

	end

	-- Add weapon extra part adds
	local weapon_data = tweak_data.weapon.factory[ weapon.factory_id ]
	if weapon_data and weapon_data.adds then
		for k, v in pairs( weapon_data.adds ) do
			if blueprint_parts[k] then
				for x, y in pairs( v ) do
					WeaponCustomization:AddCustomizablePart( y )
				end
			end
		end
	end

end

function WeaponCustomization:QueueWeaponUpdate( material_id, pattern_id, tint_color_a, tint_color_b, parts_table )

	if not self._update_queue then
		self._update_queue = {}
	end

	local data = {
		["material"] = material_id,
		["pattern"] = pattern_id,
		["color_a"] = tint_color_a,
		["color_b"] = tint_color_b,
		["parts"] = parts_table,
	}
	table.insert( self._update_queue, data )

end

function WeaponCustomization:DequeueUpdate()

	if not self._update_queue then
		Print("[Error] Could not dequeue as the update queue does not exist")
		return
	end

	if #self._update_queue > 0 then
		local data = self._update_queue[1]
		WeaponCustomization:UpdateWeapon( data["material"], data["pattern"], data["color_a"], data["color_b"], data["parts"] )
		table.remove( self._update_queue, 1 )
	end

end

function WeaponCustomization:UpdateWeaponPartsWithMaskMod( data )
	WeaponCustomization:UpdateWeaponPartsWithMod( data.category, data.mods.id )
end

function WeaponCustomization:UpdateWeaponPartsWithMod( category, mod_id, parts_table, disable_saving )

	if managers.blackmarket._customizing_weapon and managers.blackmarket._customizing_weapon_data and managers.blackmarket._selected_weapon_parts then

		-- Set selected part
		if managers.blackmarket._selected_weapon_parts[ category ] then
			managers.blackmarket._selected_weapon_parts[ category ] = mod_id
		end

		-- Get parts to modify
		if not parts_table and managers.blackmarket._customizing_weapon_parts then
			parts_table = {}
			for k, v in ipairs( managers.blackmarket._customizing_weapon_parts ) do
				if v.modifying then
					parts_table[v.id] = v
				end
			end
		end

		-- Modify parts
		local weapon_name = managers.blackmarket._customizing_weapon_data.name
		local weapon_category = managers.blackmarket._customizing_weapon_data.category
		if parts_table and (weapon_category == "primaries" or weapon_category == "secondaries") then

			for k, v in pairs( parts_table ) do

				-- Update category mod
				if v[ category ] then
					v[ category ] = mod_id
				end

				-- Update part visuals
				local color_data = tweak_data.blackmarket.colors[ v["colors"] ]
				WeaponCustomization:UpdateWeapon( v["materials"], v["textures"], color_data.colors[1], color_data.colors[2], { [v.id] = true } )

			end

		else

			local wep = managers.blackmarket._global.melee_weapons[weapon_name]
			if wep.visual_blueprint then

				local vis_parts = managers.blackmarket._selected_weapon_parts 
				local color_data = tweak_data.blackmarket.colors[ vis_parts["colors"] ]
				WeaponCustomization:UpdateWeapon( vis_parts["materials"], vis_parts["textures"], color_data.colors[1], color_data.colors[2], { ["melee"] = true } )

			end

		end

		-- Save current weapon customization
		if not disable_saving then
			WeaponCustomization:SaveCurrentWeaponCustomization()
		end

	end

end

function WeaponCustomization:UpdateWeaponUsingOptions()

	local opts = GoonBase.Options.WeaponCustomization
	local material = WeaponCustomization._materials_lookup[ opts.Material ]
	local pattern = WeaponCustomization._patterns_lookup[ opts.Pattern ]
	local tint_color_a = Color( opts.Color1R, opts.Color1G, opts.Color1B )
	local tint_color_b = Color( opts.Color2R, opts.Color2G, opts.Color2B )

	if opts.Pattern == 1 then
		if opts.Material == 1 then
			pattern = "no_color_no_material"
		else
			pattern = "no_color_full_material"
		end
	end

	self:UpdateWeapon( material, pattern, tint_color_a, tint_color_b )

end

function WeaponCustomization:UpdateWeapon( material_id, pattern_id, tint_color_a, tint_color_b, parts_table, unit_override )

	if self._requesting then
		Print("[Error] Could not update weapon customization, already updating current materials")
		return
	end

	-- Find weapon
	local weapon_base = unit_override and unit_override:base() or nil
	if not weapon_base then

		if managers.player:local_player() then
			weapon_base = managers.player:local_player():inventory():equipped_unit():base()
		end
		if self._menu_weapon_preview_unit and alive( self._menu_weapon_preview_unit ) then
			weapon_base = self._menu_weapon_preview_unit.base and self._menu_weapon_preview_unit:base() or self._menu_weapon_preview_unit
		end

		if self._menu_weapon_preview_unit then
			SaveTable( self._menu_weapon_preview_unit.__index, "_menu_weapon_preview_unit.txt" )
		end

	end

	if not weapon_base then
		Print("[Error] Could not update weapon customization, no weapon unit")
		return
	end

	-- Defaults
	material_id = material_id or "no_material"
	pattern_id = pattern_id or "no_color_no_material"
	if material_id ~= "no_material" and pattern_id == "no_color_no_material" then
		pattern_id = "no_color_full_material"
	end
	if material_id == "no_material" then
		pattern_id = "no_color_no_material"
	end
	tint_color_a = tint_color_a or Color(1, 1, 1)
	tint_color_b = tint_color_b or Color(1, 1, 1)

	-- Callbacks
	local texture_load_result_clbk = callback(self, self, "clbk_texture_loaded")

	self._materials = {}
	self._textures = {}

	-- Find materials
	if type(weapon_base._parts) == "table" then

		for k, v in pairs( weapon_base._parts ) do
			if v.unit and ( (parts_table and parts_table[k]) or not parts_table ) then
				
				local materials = v.unit:get_objects_by_type(Idstring("material"))
				for _, m in ipairs(materials) do
					if m:variable_exists(Idstring("tint_color_a")) then
						table.insert(self._materials, m)
					end
				end

			end
		end

	else

		local materials = weapon_base:get_objects_by_type(Idstring("material"))
		for _, m in ipairs(materials) do
			if m:variable_exists(Idstring("tint_color_a")) then
				table.insert(self._materials, m)
			end
		end

	end

	-- Material
	local old_reflection = self._textures.reflection and self._textures.reflection.name
	local material_amount = 1
	if tweak_data.blackmarket.materials[material_id] then

		local material_data = tweak_data.blackmarket.materials[material_id]
		local reflection = Idstring(material_data.texture)
		if old_reflection ~= reflection then
			self._textures.reflection = {
				name = reflection,
				texture = false,
				ready = false
			}
		end
		material_amount = material_data.material_amount or 1

	end

	-- Pattern
	local old_pattern = self._textures.pattern and self._textures.pattern.name
	if tweak_data.blackmarket.textures[pattern_id] then

		local pattern = Idstring(tweak_data.blackmarket.textures[pattern_id].texture)
		if old_pattern ~= pattern then
			self._textures.pattern = {
				name = pattern,
				texture = false,
				ready = false
			}
		end

	end

	-- Set Textures
	for _, material in ipairs(self._materials) do
		material:set_variable(Idstring("tint_color_a"), tint_color_a)
		material:set_variable(Idstring("tint_color_b"), tint_color_b)
		material:set_variable(Idstring("material_amount"), material_amount)
	end

	-- Load
	self._requesting = true

	for tex_id, texture_data in pairs(self._textures) do
		if not texture_data.ready then
			texture_data.ready = true
			for _, material in ipairs(self._materials) do
				Application:set_material_texture(material, Idstring(tex_id == "pattern" and "material_texture" or "reflection_texture"), texture_data.name, Idstring("normal"), 0)
			end
		end
	end

	self._requesting = nil

end

function WeaponCustomization:clbk_texture_loaded(tex_name)

	for tex_id, texture_data in pairs(self._textures) do
		if not texture_data.ready and tex_name == texture_data.name then
			texture_data.ready = true
			for _, material in ipairs(self._materials) do
				Application:set_material_texture(material, Idstring(tex_id == "pattern" and "material_texture" or "reflection_texture"), tex_name, Idstring("normal"), 0)
			end
		end
	end

end

function WeaponCustomization:SaveCurrentWeaponCustomization()

	if not managers.blackmarket._customizing_weapon or not managers.blackmarket._customizing_weapon_data or not managers.blackmarket._selected_weapon_parts then
		Print("[Error] Could not save weapon customization, no customization data")
		return
	end

	-- Get weapon
	local data = managers.blackmarket._customizing_weapon_data
	local weapon_category = data.category
	local weapon_slot = data.slot
	local weapon = WeaponCustomization:GetWeaponTableFromInventory( data )

	if not weapon then
		Print("[Error] Could not save weapon customization, no weapon found in category '", weapon_category, "' slot '", weapon_slot, "'")
		return
	end

	-- Setup weapon visual customization save
	if not weapon.visual_blueprint then
		weapon.visual_blueprint = {}
		for k, v in ipairs( weapon.blueprint ) do
			weapon.visual_blueprint[v] = clone( WeaponCustomization._default_part_visual_blueprint )
		end
	end

	-- Get modified parts
	local parts = {}
	for k, v in ipairs( managers.blackmarket._customizing_weapon_parts ) do
		if v.modifying then
			parts[v.id] = true
		end
	end

	-- Update visual customization
	for k, v in pairs( parts ) do

		local mat = managers.blackmarket._selected_weapon_parts["materials"]
		local tex = managers.blackmarket._selected_weapon_parts["textures"]
		local col = managers.blackmarket._selected_weapon_parts["colors"]

		if not weapon.visual_blueprint[k] then
			weapon.visual_blueprint[k] = clone( WeaponCustomization._default_part_visual_blueprint )
		end

		weapon.visual_blueprint[k]["materials"] = mat
		weapon.visual_blueprint[k]["textures"] = tex
		weapon.visual_blueprint[k]["colors"] = col

	end

end

function WeaponCustomization:LoadCurrentWeaponCustomization( data )

	data = data or managers.blackmarket._customizing_weapon_data

	-- Get weapon
	local weapon_name = data.name 
	local weapon_category = data.category
	local weapon_slot = data.slot
	if not weapon_category or not weapon_slot then
		Print("[Error] Could not load weapon customization, could not find category or slot")
		return
	end
	local weapon = WeaponCustomization:GetWeaponTableFromInventory( data )

	if not weapon then
		Print("[Error] Could not load weapon customization, no weapon found in category '", weapon_category, "' slot '", weapon_slot, "'")
		return
	end

	-- Create default blueprint if it doesn't exist
	if not weapon.visual_blueprint then

		weapon.visual_blueprint = {}

		if weapon.blueprint then
			for k, v in pairs( weapon.blueprint ) do
				weapon.visual_blueprint[v] = clone( WeaponCustomization._default_part_visual_blueprint )
			end
		else
			weapon.visual_blueprint["melee"] = clone( WeaponCustomization._default_part_visual_blueprint )
		end

	end

	-- Load and apply blueprint
	WeaponCustomization:LoadWeaponCustomizationFromBlueprint( weapon.visual_blueprint )

end


function WeaponCustomization:GetWeaponTableFromInventory( data )
	local category = data.category
	if category == "primaries" or category == "secondaries" then
		return managers.blackmarket._global.crafted_items[category][data.slot]
	end
	if category == "melee_weapons" then
		return managers.blackmarket._global.melee_weapons[data.name]
	end
	return nil
end

function WeaponCustomization:LoadWeaponCustomizationFromBlueprint( blueprint, unit_override )

	if not blueprint then
		Print("[Warning] Could not load weapon customization, no visual blueprint specified")
		return
	end

	for k, v in pairs( blueprint ) do

		local material = v["materials"]
		local pattern = v["textures"]
		local blackmarket_color = v["colors"]
		local color = tweak_data.blackmarket.colors[ blackmarket_color ]

		self:UpdateWeapon( material, pattern, color.colors[1], color.colors[2], k and { [k] = true } or nil, unit_override )

	end

end

function WeaponCustomization:LoadEquippedWeaponCustomizations( weapon_base )

	local equipped_weapons = {
		[1] = managers.blackmarket:equipped_primary(),
		[2] = managers.blackmarket:equipped_secondary()
	}

	for k, v in pairs( equipped_weapons ) do
		if weapon_base._factory_id == v.factory_id and v.visual_blueprint then
			WeaponCustomization:LoadWeaponCustomizationFromBlueprint( v.visual_blueprint, weapon_base._unit )
		end
	end

end

-- Clear Data
function WeaponCustomization:ShowClearDataConfirmation()

	local title = managers.localization:text("WeaponCustomization_ClearDataTitle")
	local message = managers.localization:text("WeaponCustomization_ClearDataMessage")
	local menuOptions = {}
	menuOptions[1] = {
		text = managers.localization:text("WeaponCustomization_ClearDataAccept"),
		callback = WeaponCustomization.ClearDataFromSave,
		is_cancel_button = true
	}
	menuOptions[2] = {
		text = managers.localization:text("WeaponCustomization_ClearDataCancel"),
		is_cancel_button = true
	}
	local menu = QuickMenu:new(title, message, menuOptions, true)

end

function WeaponCustomization.ClearDataFromSave()

	if not managers.blackmarket then
		return
	end

	-- Erase primary weapons
	for k, v in pairs( managers.blackmarket._global.crafted_items["primaries"] ) do
		if v.visual_blueprint then
			v.visual_blueprint = nil
		end
	end

	-- Erase secondary weapons
	for k, v in pairs( managers.blackmarket._global.crafted_items["secondaries"] ) do
		if v.visual_blueprint then
			v.visual_blueprint = nil
		end
	end

	-- Erase melee weapons
	for k, v in pairs( managers.blackmarket._global["melee_weapons"] ) do
		if v.visual_blueprint then
			v.visual_blueprint = nil
		end
	end

end
