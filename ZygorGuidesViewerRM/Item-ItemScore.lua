local ZGV = ZygorGuidesViewer
if not ZGV then return end

local L = ZGV.L
local G = _G

local tinsert,tremove,print,ipairs,pairs,wipe=tinsert,tremove,print,ipairs,pairs,wipe
local Gratuity = LibStub("LibGratuity-3.0")

local ItemScore = ZGV.ItemScore
if not ItemScore then return end
LibStub("AceHook-3.0"):Embed(ItemScore)

local item_weapon_types = ItemScore.Item_Weapon_Types
local item_armor_types = ItemScore.Item_Armor_Types
local item_gem_types = ItemScore.Item_Gem_Types

-- Pawn compatibility tables (optional, for import/export)
ItemScore.Gear_PawnToZygor = ItemScore.Gear_PawnToZygor or {}
ItemScore.KeywordsPawnToRules = ItemScore.KeywordsPawnToRules or {}
ItemScore.Gear_ZygorToPawn = ItemScore.Gear_ZygorToPawn or {}

local ItemCache = {}
ItemScore.ItemCache = ItemCache

local locale=GetLocale()
if locale=="enGB" then locale="enUS" end  -- just in case.

local function strip_link(itemlink)
	local _,itemstring,_ = itemlink:match("(.*)item:([0-9-:]*)(.*)")
	if itemstring then
		-- Strip all :0: to :: repeatedly until stable
		local result = itemstring
		local prev
		repeat
			prev = result
			result = result:gsub(":0:", "::")
		until result == prev
		-- Also strip trailing :0 sequences
		result = result:gsub(":0$", ":")
		return "item:"..result
	end
	return false
end
ItemScore.strip_link = strip_link
	
function ItemScore:Initialise()
	-- apply lower armor types as viable
	for class,classrules in pairs(ItemScore.rules) do
		for spec,rule in pairs(classrules) do
			local stats = rule["stats"]
			local types = rule["itemtypes"]

			stats.DAMAGE_PER_SECOND = stats.DPS stats.DPS = nil -- Switch DPS to the full string.

			-- players use only final armor types, so no fallbacks to lower ones anymore

			types["JEWELERY"] = 1 -- rings, trinkets, necklaces
		end
	end

	-- register all needed events
	self.eventFrame=CreateFrame("Frame")
	ZGV.ChainCall(self.eventFrame)
		:RegisterEvent("LOADING_SCREEN_DISABLED")

		:RegisterEvent("PLAYER_LEVEL_UP")
		:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		:RegisterEvent("BAG_UPDATE_DELAYED")

		:RegisterEvent("PLAYER_REGEN_DISABLED")
		:RegisterEvent("PLAYER_REGEN_ENABLED")

		:SetScript("OnEvent",function(self,event,...) ItemScore:OnEvent(event,...) end)
		:Show()

	-- 3.3.5a: use talent/skill events instead of retail spec events
	self.eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self.eventFrame:RegisterEvent("SKILL_LINES_CHANGED")


	ZGV.UpdateCentral:AddHandler(ItemScore.ItemDetailsHandler)


	ZGV:AddMessageHandler("ZGV_STEP_FINALISED",ItemScore.OnEvent)
	ZGV:AddMessageHandler("LIBROVER_TRAVEL_REPORTED",ItemScore.OnEvent)

	-- create item popup
	ItemScore.Upgrades:CreatePopup()

	-- set up initial data
	ItemScore:RefreshUserData()
end

function ItemScore:OnEvent(event,arg1,arg2,...)
	if event == "PLAYER_LEVEL_UP" or event == "CHARACTER_POINTS_CHANGED" then
		-- using timer as delay, since in the same frame PLAYER_LEVEL_UP player is still on previous level
		-- and to run it only once, as both PLU and PSC can fire more than once
		ItemScore:DelayedRefreshUserData()
	elseif event == "SKILL_LINES_CHANGED" then -- on classic, skills changed, so user may have learned new weapon skill
		ItemScore:GetEquipmentSkills()
	elseif event == "LOADING_SCREEN_DISABLED" then -- user logged in, see what upgrades we have
		ItemScore.EquipTimer = ItemScore.EquipTimer or ZGV:ScheduleTimer(function() 
			ItemScore.Upgrades:ScoreEquippedItems()
		end,0.5)
	elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED" -- bags or equipment changed, see what upgrades we have
		or event=="ZGV_STEP_FINALISED"  or event=="LIBROVER_TRAVEL_REPORTED" or event=="GET_ITEM_INFO_RECEIVED" -- step finished loading, or travel route updated, see if we have useless quest equip or portkey
		then 
		-- on timer to run it only once, since equip/unequip fires both events, and we would get spammed
		ItemScore.EquipTimer = ItemScore.EquipTimer or ZGV:ScheduleTimer(function() 
			ItemScore.Upgrades:ScoreEquippedItems()
		end,0.5)
	elseif event == "PLAYER_REGEN_DISABLED" then -- combat started, kill all upgrade popups
		if ItemScore.Upgrades.EquipPopup then ItemScore.Upgrades.EquipPopup:Hide() end
	elseif event == "PLAYER_REGEN_ENABLED" then -- combat ended, check if anything is waiting for equip
		ItemScore.Upgrades:ProcessPossibleUpgrades()
	end

	if event == "PLAYER_EQUIPMENT_CHANGED" then
		ItemScore.GearFinder:ClearResults()
	end
end

function ItemScore:DelayedRefreshUserData()
	ItemScore.RefreshTimer = ItemScore.RefreshTimer or ZGV:ScheduleTimer(function() 
		ItemScore:RefreshUserData()
		-- TODO: outleveled heirloom popup
	end,0.5)
end

function ItemScore:RefreshUserData()
	ItemScore.RefreshTimer = nil
	ItemScore:GetEquipmentSkills()
	ItemScore:SetStatWeights()
	ItemScore.Upgrades:ScoreEquippedItems()
end

function ItemScore:SetStatWeights(playerclass,playerspec,playerlevel)
	self.playerclass = playerclass or (select(2,UnitClass("player")))
	self.playerclassName = (select(1,UnitClass("player")))
	self.playerclassNum = (select(3,UnitClass("player")))
	self.playerlevel = playerlevel or ((ZGV.db.char.fakelevel or 0)>0 and ZGV.db.char.fakelevel) or UnitLevel("player")
	self.playerfaction = UnitFactionGroup("player")

	-- 3.3.5a: detect spec from talent tree point distribution
	self.playeristank = self.playerclass=="DRUID" or self.playerclass=="PALADIN" or self.playerclass=="WARRIOR" or self.playerclass=="DEATHKNIGHT"
	self.playerishealer = self.playerclass=="DRUID" or self.playerclass=="SHAMAN" or self.playerclass=="PRIEST" or self.playerclass=="PALADIN"
	if not ZGV.db.char.gear_active_build then
		-- Auto-detect spec from talent points
		local bestTree, bestPoints = 1, 0
		for i = 1, GetNumTalentTabs() do
			local _, _, pointsSpent = GetTalentTabInfo(i)
			if pointsSpent > bestPoints then
				bestPoints = pointsSpent
				bestTree = i
			end
		end
		ZGV.db.char.gear_selected_build = bestTree
		ZGV.db.char.gear_active_build = bestTree
	end
	ItemScore.Upgrades.BadUpgrades = ZGV.db.char.badupgrade

	-- create a copy so that the arrays in datatables are left untouched, as we will need them to handle custom weights resets
	self.ActiveRuleSet = {
		itemtypes = {},
		stats = {},
		primary = {},
		caps = {},
	}

	local active_set = ZGV.db.char.gear_active_build

	-- Copy values from our rules
	if ItemScore.rules[self.playerclass] and ItemScore.rules[self.playerclass][active_set] then
		for i,v in pairs(ItemScore.rules[self.playerclass][active_set].itemtypes) do self.ActiveRuleSet.itemtypes[i]=v end
		for i,v in pairs(ItemScore.rules[self.playerclass][active_set].stats) do self.ActiveRuleSet.stats[i]=v end
		if ItemScore.rules[self.playerclass][active_set].caps then
			for i,v in pairs(ItemScore.rules[self.playerclass][active_set].caps) do self.ActiveRuleSet.caps[i]=v end
		end
	else
		print("Unknown spec",self.playerclass,active_set)
	end

	-- Update stats with users profile
	local saved_vars_prefix = "gear_"..self.playerclass.."_"..tostring(active_set).."_"
	for index,stat in pairs(ZGV.ItemScore.Keywords) do
		if ZGV.db.profile[saved_vars_prefix..(stat.blizz)] then
			self.ActiveRuleSet.stats[(stat.blizz)]= tonumber(ZGV.db.profile[saved_vars_prefix..(stat.blizz)] or 0)
		end
	end

	-- Set dual wield 
	ItemScore:SetDualWield()

	-- record lowest statweight for scoring armor/dps
	self.whiteScoreWeight = nil
	for i,v in pairs(self.ActiveRuleSet.stats) do
		if v>0 then
			if not self.whiteScoreWeight or self.whiteScoreWeight>v then
				self.whiteScoreWeight = v
			end
		end
	end

	if not self.whiteScoreWeight then self.whiteScoreWeight=1 end -- in case user statweights are wiped clean
	self.whiteScoreWeight = self.whiteScoreWeight * 0.1

	-- if anything in user info has changed, all cached scores are no longer valid, and item stats could have changed due to level scaling
	-- wipe cached data, we are starting anew
	table.wipe(ItemCache)

	ItemScore.GearFinder:ClearResults()
end

-- converts ITEM_MOD_CRIT_RATING_SHORT to CRIT
local name_cache = {}
function ItemScore:NormaliseStatName(statname)
	if name_cache[statname] then return name_cache[statname] end

	-- primary and secondary stats
	statname = statname:gsub("_RATING_SHORT$","")
	statname = statname:gsub("_SHORT$","")
	statname = statname:gsub("^ITEM_MOD_","")

	-- tertiary stats
	statname = statname:gsub("^CR_","")

	-- element resist gear
	statname = statname:gsub("_NAME$","")
	
	-- specific case: armor
	if statname=="RESISTANCE0" then statname="ARMOR" end

	name_cache[statname] = statname
	return statname
end

ItemScore.GetItemDetailsQueue = {}
function ItemScore:GetItemDetails(itemlink,callback,force)
	if not itemlink then return false end
	itemlink = strip_link(itemlink)

	if not ItemCache[itemlink] then
		table.insert(ItemScore.GetItemDetailsQueue,{itemlink,callback,force})
	else
		return ItemCache[itemlink]
	end
end

function ItemScore:ItemDetailsHandler()
	if ItemScore.GetItemDetailsQueue[1] then
		local itemlink,callback,force = unpack(table.remove(ItemScore.GetItemDetailsQueue,1))
		local result = ItemScore:GetItemDetailsQueued(itemlink,force)
		if result then
			if callback and type(callback)=="function" then callback(result) end
		else
			table.insert(ItemScore.GetItemDetailsQueue,{itemlink,callback,force})
		end
	end
end

local SKIP_CACHE = false
function ItemScore:GetItemDetailsQueued(itemlink,force)
	if not itemlink then return false end
	local itemlinkfull = itemlink
	itemlink = strip_link(itemlink)
	if not itemlink then return false end

	-- if item is not yet cached, grab its data
	if not ItemCache[itemlink] or SKIP_CACHE or force then
		-- that is a new one
		local itemName, itemLink2, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, texture = ZGV:GetItemInfo(itemlink)
		local itemlvl = itemLevel
		-- 3.3.5a: GetItemInfo doesn't return classID/subclassID numerically
		-- Map the string type/subtype to numeric IDs used by LE_ITEM_CLASS constants
		local itemClassID, itemSubClassID
		if itemType then
			-- Map item type strings to class IDs
			local typeMap = {
				[ARMOR or "Armor"] = LE_ITEM_CLASS_ARMOR,  -- 4
				[WEAPON or "Weapon"] = LE_ITEM_CLASS_WEAPON, -- 2
			}
			-- Try localized name first, then English fallback
			itemClassID = typeMap[itemType]
			if not itemClassID then
				-- Check common English names as fallback
				local typeUpper = itemType:upper()
				if typeUpper == "ARMOR" then itemClassID = LE_ITEM_CLASS_ARMOR
				elseif typeUpper == "WEAPON" then itemClassID = LE_ITEM_CLASS_WEAPON
				end
			end

			-- Map armor subtypes to numeric IDs matching Item_Armor_Types table
			if itemClassID == LE_ITEM_CLASS_ARMOR then
				local armorMap = {}
				for id, name in pairs(ItemScore.Item_Armor_Types) do
					local skillName = ItemScore.SkillNames[name]
					if skillName then armorMap[skillName] = id end
				end
				-- Also add English fallbacks
				armorMap["Cloth"] = 1  armorMap["Leather"] = 2  armorMap["Mail"] = 3  armorMap["Plate"] = 4
				armorMap["Shields"] = 6  armorMap["Shield"] = 6
				-- Misc armor (rings, trinkets, necklaces) has subtype "Miscellaneous" or similar
				itemSubClassID = armorMap[itemSubType] or 0
			elseif itemClassID == LE_ITEM_CLASS_WEAPON then
				local weaponMap = {}
				for id, name in pairs(ItemScore.Item_Weapon_Types) do
					local skillName = ItemScore.SkillNames[name]
					if skillName then weaponMap[skillName] = id end
				end
				-- English fallbacks for common weapon types
				weaponMap["Swords"] = 7  weaponMap["Axes"] = 0  weaponMap["Maces"] = 4
				weaponMap["Staves"] = 10  weaponMap["Daggers"] = 15  weaponMap["Fist Weapons"] = 13
				weaponMap["Polearms"] = 6  weaponMap["Bows"] = 2  weaponMap["Guns"] = 3
				weaponMap["Crossbows"] = 18  weaponMap["Wands"] = 19  weaponMap["Thrown"] = 16
				weaponMap["Two-Handed Swords"] = 8  weaponMap["Two-Handed Axes"] = 1
				weaponMap["Two-Handed Maces"] = 5  weaponMap["Fishing Poles"] = 20
				weaponMap["Fishing Pole"] = 20  weaponMap["Miscellaneous"] = 14
				itemSubClassID = weaponMap[itemSubType] or 0
			end
		end
		if not itemName then return false end

		if itemEquipLoc=="" then -- not equipment, don't bother parsing tooltip
			ItemCache[itemlink] = { 
				stats = {}, 
				itemlink = itemlink,
				itemid = ZGV.ItemLink.GetItemID(itemlink),
				itemlinkfull = itemlinkfull,
				class = itemClassID,
				subclass = itemSubClassID,
				quality = itemRarity,
				validated = false,
				texture = texture,
			}
			return
		end

		-- class, spec check, and level check. we need to scan tooltip for those. meh.
		local playerclass, playerspec
		Gratuity:SetHyperlink(itemlink)
		if Gratuity:NumLines()==0 then return false end

		local stats = {}
		local tooltip = {}

		-- use blizz GetItemStats to get sockets, since tooltip scanning would only detect empty ones
		local blizzstats = GetItemStats(itemlink)
		if blizzstats then
			for i,v in pairs(blizzstats) do
				if i=="EMPTY_SOCKET_DOMINATION" then stats.EMPTY_SOCKET_DOMINATION = v end
				if i=="EMPTY_SOCKET_PRISMATIC" then stats.EMPTY_SOCKET_PRISMATIC = v end
			end
		end

		for num=1,Gratuity:NumLines() do
			local line=Gratuity:GetLine(num)

			if not line then return false end
			if line==RETRIEVING_ITEM_INFO then return false end

			if ItemScore.SaveTooltip then table.insert(tooltip,line) end

			line = line:gsub("|c........",""):gsub("|r","") -- strip color codes, if any

			if ITEM_CLASSES_ALLOWED then
				local found_class = line:match( gsub(ITEM_CLASSES_ALLOWED,"%%s","(.*)"))
				if found_class then playerclass = found_class end
			end

			-- 3.3.5a: no ITEM_REQ_SPECIALIZATION

			if ITEM_MIN_LEVEL then
				local found_level = line:match( gsub(ITEM_MIN_LEVEL,"%%d","(.*)"))
				if found_level then itemMinLevel = tonumber(found_level) end
			end

			-- 3.3.5a: classic has normal stats as equip: effects, so do NOT early exit on those lines

			local socket_bonus = ITEM_SOCKET_BONUS and line:match( ITEM_SOCKET_BONUS:gsub("%%s","(.*)"))
			local set_bonus = ITEM_SET_BONUS_GRAY and line:match( ITEM_SET_BONUS_GRAY:gsub("%%s","(.*)"))
			local set2_bonus = ITEM_SET_BONUS and line:match( ITEM_SET_BONUS:gsub("%%s","(.*)"))
			if socket_bonus or set_bonus or set2_bonus then line="" end -- skip all extra lines

			local line = (ITEM_SPELL_TRIGGER_ONEQUIP and line:gsub(ITEM_SPELL_TRIGGER_ONEQUIP.." ","") or line):lower()
			for _,statdata in pairs(ItemScore.Keywords) do
				for _,regex in ipairs(statdata.regexs) do
					if not stats[statdata.blizz] then
						local sign,value = line:match(regex)
						if sign and not value then value = sign end

						if statdata.boolean and sign then
							value="1"
						end

						if value then
							value = value:gsub(",",".")
							if sign=="-" then value=value*(-1) end
							if statdata.multi then
								for _,multiname in ipairs(statdata.multi) do
									stats[multiname] = tonumber(value)
								end
							else
								stats[statdata.blizz] = tonumber(value)
							end
						end
					end
				end
			end
		end

		-- ok, got everything, cache it
		ItemCache[itemlink] = { 
			stats = stats, 
			itemlink = itemlink,
			itemid = ZGV.ItemLink.GetItemID(itemlink),
			itemlinkfull = itemlinkfull,
			minlevel = itemMinLevel,
			type = itemEquipLoc,
			class = itemClassID,
			subclass = itemSubClassID,
			quality = itemRarity,
			validated = false,
			texture = texture,
			itemlvl = itemlvl,
			playerclass = playerclass,
			playerspec = playerspec,
		}

		if ItemScore.SaveTooltip then ItemCache[itemlink].tooltip = tooltip end


		local slot_1, slot_2, twohander = ItemScore:GetValidSlots(ItemCache[itemlink])
		ItemCache[itemlink].slot = slot_1
		ItemCache[itemlink].slot_2 = slot_2
		ItemCache[itemlink].twohander = twohander

	end

	if ItemCache[itemlink] and not (ItemCache[itemlink].itemlinkfull and ItemCache[itemlink].itemlinkfull:match("%[")) then -- in case we get a mangled (stripped) full link, try to rebuild it now
		local itemName,newfulllink = ZGV:GetItemInfo(itemlink) 
		if newfulllink then
			ItemCache[itemlink].itemlinkfull = newfulllink
		end
	end

	return ItemCache[itemlink]
end

-- function ItemScore:GetValidSlots(item) in flavour specific files

-- calculates item score based on item stats and current weights. result is cached
-- params:
--	itemlink - string - item that we are checking
-- return:
--	score - int - -1 or score of given item
--	success - bool - was item scored at all
--	comment - string - description
function ItemScore:GetItemScore(itemlink,verbose)
	local item = ItemScore:GetItemDetails(itemlink)
	if not item then return -1, -1, false, "no info yet" end

	local stats = item.stats
	local score = 0
	local statweights = self.ActiveRuleSet.stats
	local caps = self.ActiveRuleSet.caps

	-- calculate score based on stats
	for statname,statvalue in pairs(stats) do
		statname = ItemScore:NormaliseStatName(statname)
		local statweight = statweights[statname] or 0

		if caps and caps[statname] then
			local current_rating = ItemScore:GetEquippedStatValue(statname)
			-- reduce value of stats that are already capped, or if player is not at max level
			if (current_rating > caps[statname]) or self.playerlevel < GetMaxPlayerLevel() then
				statweight = statweight / 2
			end
		end
		
		score = score + statvalue*statweight

		if verbose then table.insert(verbose,("  + |cff00ff00%.1f * %s|r: |cffaaaaaa * %.1f|r = |cffffffff%.1f|r"):format(statvalue,statname, statweight, statvalue*statweight))  end
		
		-- 3.3.5a: gem socket scoring not supported (no gem database for WOTLK)
	end

	-- add dps and armor at minimal weight, unless proper statweights for them exist
	if not statweights.ARMOR then 
		if verbose then table.insert(verbose,("  + |cff00ff00%.1f extra %s|r: |cffaaaaaa * %.1f|r = |cffffffff%.1f|r"):format((item.stats.ARMOR or 0),RESISTANCE0_NAME, self.whiteScoreWeight, (item.stats.ARMOR or 0)*self.whiteScoreWeight ))  end
		score = score + (item.stats.ARMOR or 0)*self.whiteScoreWeight 
	end
	if not statweights.DAMAGE_PER_SECOND then 
		if verbose then table.insert(verbose,("  + |cff00ff00%.1f extra %s|r: |cffaaaaaa * %.1f|r = |cffffffff%.1f|r"):format((item.stats.DAMAGE_PER_SECOND or 0),ITEM_MOD_DAMAGE_PER_SECOND_SHORT, self.whiteScoreWeight, (item.stats.DAMAGE_PER_SECOND or 0)*self.whiteScoreWeight ))  end
		score = score + (item.stats.DAMAGE_PER_SECOND or 0)*self.whiteScoreWeight 
	end

	-- adjust armor weights
	if item.class == LE_ITEM_CLASS_ARMOR and item.type~="INVTYPE_CLOAK" then
		if verbose then table.insert(verbose,("  ? |cff00ff00Is armor|r"))  end 
		local types = self.ActiveRuleSet.itemtypes
		local subclass = item_armor_types[item.subclass]
		local limit = types[subclass] or 0
		if verbose then table.insert(verbose,("  ? |cff00ff00limit "..limit.." level "..self.playerlevel.."|r"))  end 
		-- if limit is below 0, item is good only till given level, with 10 level grace
		if limit < 0 then 
			if verbose then table.insert(verbose,("  ? |cff00ff00Has limit|r"))   end
			if self.playerlevel >= (-limit+10) then
				if verbose then table.insert(verbose,"  ? |cff00ff00Has limit, past grace|r") end  
				-- we are over the 10 level grace period, undervalue heavily. I mean, come on, farm a little...
				score = score * 0.5
			elseif self.playerlevel >= -limit then
				if verbose then table.insert(verbose,"  ? |cff00ff00Has limit, grace period|r") end  
				 -- we are within grace period, undervalue slightly
				 score = score * 0.9
				-- allows all classes to transition to final armor type after specified level
			end
		end

	end

	-- heirloom protection is now done in upgrades get_upgrade

	-- record scores
	item.score = score

	if verbose then 
		table.insert(verbose,("score %f"):format(score))
		table.insert(verbose,("comment %s"):format("scored ok"))
	end

	return score, true, "scored ok"
end

-- checks if given item is a heirloom that should be protected
-- params:
--	itemlink - string - item that we are checking
-- return:
--	is_protected - bool - whenever item is heirloom not outleveled by user
--	max_level - int - up to what level this item is valid heirloom
function ItemScore:GetHeirloomInfo(itemlink)
	-- in shadowland heirlooms no longer give exp bonus, so we are not protecting them anymore unless player asks for it
	do return ZGV.db.profile.autogear_keepheirlooms, 60 end

	local item = ItemScore:GetItemDetails(itemlink)
	if not item then return false,0 end
	if item.quality ~= 7 then return false,0 end

	local itemid = item.itemid
	local max_level = 60 -- default for all looms

	-- if it is one of items with hardcoded max levels
	max_level =  ItemScore.FixedLevelHeirloom[itemid] or max_level
		
	for bonus,_ in pairs(ZGV.ItemLink.GetItemBonuses(itemlink)) do
		max_level = math.max(max_level,ItemScore.HeirloomBonuses[tonumber(bonus)])
	end
	
	return self.playerlevel < max_level, max_level
end


-- checks if item can be equipped by player at the moment. result is cached
-- params:
--	itemlink - string
--	future - anything - for checks for future upgrades. if set, level restriction is not checked
-- returns: 
--	is valid - bool - is item valid for current player
--	is final - bool - was validity really checked (and not skipped due to no gii info)
--	comment - string - verbose description of result
function ItemScore:IsValidItem(itemlink, future)
	if not itemlink then return false, false, "No itemlink" end

	local item = ItemScore:GetItemDetails(itemlink)
	if not item then return false, false, "No info" end

	if item.validated then return item.valid, true, item.validstatus end

	if not item.slot then 
		item.validated = true
		item.valid = false
		item.validstatus = "not equipment "..tostring(item.class).." "..tostring(item.subclass)
		return false, true, item.validstatus
	end

	local types = self.ActiveRuleSet.itemtypes
	if not types then return false, false, "No info" end

	-- is something that can be equipped
	local subclass
	if item.class == LE_ITEM_CLASS_ARMOR then
		subclass = item_armor_types[item.subclass]
	elseif item.class == LE_ITEM_CLASS_WEAPON then
		subclass = item_weapon_types[item.subclass]
	else
		item.validated = true
		item.valid = false
		item.validstatus = "not equipment"
		return false, true, "not equipment"
	end

	-- can equip at current level, cloaks are cloth, but valid for all classes
	local useble_since_level = types[subclass] or (item.type=="INVTYPE_CLOAK" and 1)

	if not useble_since_level then
		item.validated = true
		item.valid = false
		item.validstatus = ("%s is not valid for %s %s"):format(subclass,self.playerclassName,self.playerspecName or "")
		return false, true, item.validstatus
	elseif not future and self.playerlevel < useble_since_level then
		item.validated = true
		item.valid = false
		item.validstatus = ("required level %d to use"):format(useble_since_level)
		return false, true, item.validstatus
	end

	-- 3.3.5a: check weapon/armor skill proficiency
	if (subclass~="JEWELERY") and (ItemScore.Skills[subclass] or 0) == 0 then
		item.validated = true
		item.valid = false
		item.validstatus = "no skill "..subclass
		return false, true, item.validstatus
	end
	
	-- player class
	if item.playerclass then
		local validclass=false
	        for i,v in pairs(ZGV.ExplodeString(", ",item.playerclass)) do
			if v==self.playerclassName then
				validclass=true
				break
			end
		end

		if not validclass then
			item.validated = true
			item.valid = false
			item.validstatus = "wrong class"
			return false, true, item.validstatus
		end
	end

	-- player spec
	if item.playerspec and item.playerspec ~= self.playerspecName then
		item.validated = true
		item.valid = false
		item.validstatus = "wrong spec"
		return false, true, item.validstatus
	end

	-- player level
	if not future and item.minlevel and item.minlevel > self.playerlevel then 
		item.validated = true
		item.valid = false
		item.validstatus = ("required level %d to equip"):format(item.minlevel)
		return false, true, item.validstatus
	end

	-- if we are here, it means that none of conditions forced early exit. wheeee have an upgrade
	item.validated = true
	item.valid = true
	item.validstatus = "ok"
	return true, true, "ok"
end

-- 3.3.5a: gem scoring functions removed (retail-only feature)

-- returns items equipped by requested type, used by items-quest
-- params:
--	equiptype - int - invtype constant of type to check
-- returns
--	itemlink - string - itemlink of item in first possible slot
--	itemlink2 - string, optional - itemlink of item in second possible slot
function ItemScore:GetItemByType(equiptype)
	local s1, s2 = get_slots_by_type(equiptype)

	local itemlink1,itemlink2
	if s1 then itemlink1 = GetInventoryItemLink("player",s1) end
	if s2 then itemlink2 = GetInventoryItemLink("player",s2) end

	return itemlink1 and itemlink1:match("item[:%d]+"),itemlink2 and itemlink2:match("item[:%d]+"), itemlink1,itemlink2
end

-- returns items equipped in requested type, used by pointer
-- params:
--	slotid - int - invslot constant
-- returns
--	itemlink - string - itemlink of item in given slot
--	itemid - string - itemid of item in given slot
function ItemScore:GetItemInSlot(slotid)
	local itemlink = GetInventoryItemLink("player",slotid)
	if itemlink then
		return itemlink:match("item[:%d]+"), tonumber(itemlink:match("item:(%d+)"))
	end
end

-- 3.3.5a: Azerite powers do not exist
-- Stub function for compatibility
function ItemScore:GetAzeritePowers(itemlink)
	return {}, false
end



-- set of functions to add zygor item info to tooltip
local function get_change(old,new) 
	if old and old>0 then 
		return math.floor(((new*100/old)-100)*100)/100
	else 
		return 100 
	end 
end

local function ItemScore_SetTooltipData(tooltip, tooltipobj)
	if not ZGV.db.profile.autogear then return end
	if not ZGV.db.profile.itemscore_tooltips then return end
	tooltipobj=tooltipobj or GameTooltip -- we patch either gametooltip or itemreftooltip

	if not ItemScore.TooltipPatched then
		local itemName,itemlink = tooltipobj:GetItem()
		if not itemlink then ItemScore.TooltipPatched  = true return end

		local item = ItemScore:GetItemDetails(itemlink,"temporary")
		if not item then
			-- Item not cached yet - force immediate parse instead of queuing
			item = ItemScore:GetItemDetailsQueued(itemlink, true)
			if not item then
				ItemScore.TooltipPatched = true
				return
			end
		end

		local fulllink = itemlink
		local itemlink = item.itemlink

		local score, success, scorecomment = ItemScore:GetItemScore(itemlink)
		if not success then ItemScore.TooltipPatched  = true return end

		local valid, final, validcomment = ItemScore:IsValidItem(itemlink)
		if not final then ItemScore.TooltipPatched  = true return end

		local heirloom_protected,heirloom_max = ItemScore:GetHeirloomInfo(itemlink)
		
		if ZGV.db.profile.debug_display then
			tooltip:AddLine(" ")
			tooltip:AddLine("|cfffe6100Zygor debug:|r ")
			tooltip:AddLine("link "..fulllink)
			tooltip:AddLine("stripped "..itemlink)
			tooltip:AddLine("score "..score)
			tooltip:AddLine("valid "..(valid and "yes " or "no ")..validcomment)
			tooltip:AddLine("protected heirloom "..(heirloom_protected and "yes " or "no ")..heirloom_max)
			tooltip:AddLine("stats:")
			for i,v in pairs(item.stats) do
				tooltip:AddLine(i.." "..v)
			end
		end
		
		local slot_1,slot_2 = item.slot, item.slot_2
		local equipped_item_1, equipped_item_2, change_1, change_2
		if slot_1 then 
			equipped_item_1 = ItemScore.Upgrades.EquippedItems[slot_1]
			if equipped_item_1 and ItemScore:IsValidItem(equipped_item_1.itemlink) then
				change_1 = get_change(equipped_item_1.artifactscore or equipped_item_1.score,score)
			else
				change_1 = 100
			end
		end
		if slot_2 then 
			equipped_item_2 = ItemScore.Upgrades.EquippedItems[slot_2] 
			if equipped_item_1 and ItemScore:IsValidItem(equipped_item_1.itemlink) then
				change_2 = get_change(equipped_item_2.artifactscore or equipped_item_2.score,score)
			else
				change_2 = 100
			end
		end

		if valid then
			if (equipped_item_1 and equipped_item_1.score) or (equipped_item_2 and equipped_item_2.score) and score then -- item can replace something
				local mh, oh, th
				if item.class == LE_ITEM_CLASS_WEAPON then
					ItemScore.Upgrades:ResetWeaponQueue("onlytemp")
					ItemScore.Upgrades:QueueWeapon(itemlink)
					mh, oh, th = ItemScore.Upgrades:ProcessWeaponQueue()
				end

				tooltip:AddLine(" ")
				tooltip:AddLine("|cfffe6100Zygor ItemScore:|r")
				local slotinfo1 = slot_2 and "Slot 1: " or ""
				local slotinfo2 = slot_2 and "Slot 2: " or ""

				-- item in slot 1
				if equipped_item_1.score then
					if itemlink~=equipped_item_1.itemlink then
						local comment = "|r "..slotinfo1..((change_1 > 0) and "Upgrade |cff00ff00" or "Downgrade |cffff0000")
						if ZGV.db.profile.debug then comment = comment..(score-equipped_item_1.score).." " end
						tooltip:AddLine(comment..change_1.."% ")
						if change_1<0 and (mh and mh.itemlink==itemlink) and (oh and oh.itemlink) then
							tooltip:AddLine("       Upgrade with "..oh.itemlinkfull)
						end
					else
						tooltip:AddLine("|r "..slotinfo1.."Equipped")
					end
				else
					tooltip:AddLine("|r "..slotinfo1.."Upgrade |cff00ff00100% ")
				end

				if slot_2 and equipped_item_2.score then
					if itemlink~=equipped_item_2.itemlink then
						local comment = "|r "..slotinfo2..((change_2 > 0) and "Upgrade |cff00ff00" or "Downgrade |cffff0000")
						if ZGV.db.profile.debug then comment = comment..(score-equipped_item_2.score).." " end
						tooltip:AddLine(comment..change_2.."% ")
						if change_2<0 and (mh and mh.itemlink) and (oh and oh.itemlink==itemlink) then
							tooltip:AddLine("       Upgrade with "..mh.itemlinkfull)
						end
					else
						tooltip:AddLine("|r "..slotinfo2.."Equipped")
					end
				elseif slot_2 then
					tooltip:AddLine("|r "..slotinfo2.."Upgrade |cff00ff00100% ")
				end
			elseif (score or 0)>0 then
				tooltip:AddLine(" ")
				tooltip:AddLine("|cfffe6100Zygor ItemScore:|r")
				tooltip:AddLine("|r  Upgrade |cff00ff00100% ")
			end
			-- 3.3.5a: gem socket suggestions removed
		else
			if item.type~="" then
				tooltip:AddLine(" ")
				tooltip:AddLine("|cfffe6100Zygor ItemScore:|r")
				tooltip:AddLine("|r  Not a valid item")
			end
		end

		ItemScore.TooltipPatched  = true
	end
	if tooltipobj==ItemRefTooltip then ItemRefTooltip:Show() end -- update to new height, have to do it by hand since IRT is called just once
end
local function ItemScore_ClearTooltipData(tooltip, ...) ItemScore.TooltipPatched = false end

-- functions that support itemscore/gearfinder options panel
function ItemScore:UsesCustomWeights(class,spec)
	local statset = ZGV.ItemScore.rules[class][spec].stats
	local prefix = 'gear_'..class..'_'..spec..'_'
	local profile = ZGV.db.profile

	for index=1,#ZGV.ItemScore.Keywords do
		local statname = ZGV.ItemScore.Keywords[index].blizz

		if not profile[prefix..statname] and statset[statname] then
		
		elseif tonumber(profile[prefix..statname]) and not statset[statname] then
			return true
		elseif tonumber(profile[prefix..statname]) and tonumber(statset[statname])~=tonumber(profile[prefix..statname]) then
			return true
		end
	end
	return false
end

ItemScore.Skills = {}
function ItemScore:GetEquipmentSkills()

	table.wipe(ItemScore.Skills)
	table.wipe(ItemCache) -- since items that were rejected due to skill may be valid now

	for i=1, GetNumSkillLines() do
		local skillName, _, _, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType = GetSkillLineInfo(i);
		local skillTag = ItemScore.SkillNamesRev[skillName]
		if skillTag then
			ItemScore.Skills[skillTag] = skillRank
		end
	end
end

function ItemScore:GetEquippedStatValue(statname)
	local result = 0
	for slotID,item in pairs(ZGV.ItemScore.Upgrades.EquippedItems) do 
		local details = ItemScore:GetItemDetails(item.itemlink)
		if details then
			for sname,svalue in pairs(details.stats) do
				local name = ItemScore:NormaliseStatName(sname)
				if name==statname then
					result = result + svalue
				end
			end
		end
	end
	return result
end


function ItemScore:ImportPawn(datastring)
	if not datastring then return end
	local unknowns = false

	if not datastring:find("Pawn: v1:") then 
		ZGV:Print("Import: Incorrect pawn string") 
		return
	end

	datastring = datastring:gsub(" [)]",""):gsub("(.*): ","")

	local stattable = {}
	for statstring in string.gmatch(datastring, "([^,]+)") do
		local statname,statval = statstring:match("(%w+)=([-0-9%.]+)")
		if statname and statval then
			stattable[statname] = (tonumber(statval)~=0 and statval or nil)
		end
	end

	for statname,statval in pairs(stattable) do
		if not ItemScore.Gear_PawnToZygor[statname] and not ItemScore.KeywordsPawnToRules[statname] then
			unknowns = true
			stattable[statname]=nil
		end
	end

	if unknowns then
		ZGV:Print("Import: Some of Pawn stat names are not supported by Zygor, and have been skipped.") 
	end


	local name,tag,id = GetClassInfo(ZGV.db.char.gear_selected_class)
	local groupname = 'gear_'..tag..'_'..ZGV.db.char.gear_selected_spec.."_"

	for index,stat in pairs(ZGV.ItemScore.Keywords) do -- wipe
		ZGV.db.profile[groupname..stat.blizz] = "0"
	end

	for statname,statval in pairs(stattable) do
		if not ItemScore.Gear_PawnToZygor[statname] then
			ZGV.db.profile[groupname..ItemScore.KeywordsPawnToRules[statname]] = statval
		end
	end
end

function ItemScore:ExportPawn(datastring)
	local class, spec = ZGV.db.char.gear_selected_class, ZGV.db.char.gear_selected_spec
	local name,tag,id = GetClassInfo(class)
	local specname = ZGV.SpecByNumber[tag][spec] -- values taken from parser.lua classtalents
	local ruleset = ItemScore.rules[tag][spec]

	local returnstring = '( Pawn: v1: "Zygor: '
	returnstring = returnstring..name..' '..specname..'": '

	local data = {}

	--[[
	for namez,namep in pairs(ItemScore.Gear_ZygorToPawn) do
		if not ruleset.itemtypes[namez] then
			table.insert(data,namep.."=-1000000")
		else
			table.insert(data,namep.."="..ruleset.itemtypes[namez])
		end
	end
	--]]

	local playermask = "gear_"..tag.."_"..spec.."_"
	for index,stat in pairs(ZGV.ItemScore.Keywords) do
		local value = ZGV.db.profile[playermask..(stat.blizz)] or ruleset.stats[stat.blizz]
		if tonumber(value) then
			table.insert(data,stat.pawn.."="..value)
		end
	end
	
	returnstring = returnstring.." "..table.concat(data, ", ") 
	returnstring = returnstring..")"

	ZGV.ItemScore.lastPawnString = returnstring
end

tinsert(ZGV.startups,{"ItemScore",function(self)
	ZGV.db.char.badupgrade = ZGV.db.char.badupgrade or {}

	local ok, err

	ok, err = pcall(ItemScore.SetData, ItemScore)
	if not ok then ZGV:Print("|cffff0000ItemScore SetData error:|r "..tostring(err)) end

	ok, err = pcall(ItemScore.Initialise, ItemScore)
	if not ok then ZGV:Print("|cffff0000ItemScore Initialise error:|r "..tostring(err)) end

	ok, err = pcall(function() ItemScore.GearFinder:Initialise() end)
	if not ok then ZGV:Print("|cffff0000GearFinder Initialise error:|r "..tostring(err)) end

	-- 3.4.3: re-enabled tooltip hooks (LibGratuity fix resolved corruption)
	pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", ItemScore_SetTooltipData)
	pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", ItemScore_ClearTooltipData)
	pcall(ItemRefTooltip.HookScript, ItemRefTooltip, "OnTooltipCleared", ItemScore_ClearTooltipData)
	if GameTooltip.SetHyperlink then pcall(hooksecurefunc, GameTooltip, "SetHyperlink", function(tip) ItemScore_SetTooltipData(tip,GameTooltip) end) end
	if ItemRefTooltip.SetHyperlink then pcall(hooksecurefunc, ItemRefTooltip, "SetHyperlink", function(tip) ItemScore_SetTooltipData(tip,ItemRefTooltip) end) end

	if Gratuity and Gratuity.vars and Gratuity.vars.tooltip then
		Gratuity.vars.tooltip:HookScript("OnTooltipSetItem", function() 
			local itemName,itemlink = Gratuity.vars.tooltip:GetItem()
			if itemlink then 
				ItemScore:GetItemDetails(itemlink,nil,"force") 
			end
		end)
	end
end})