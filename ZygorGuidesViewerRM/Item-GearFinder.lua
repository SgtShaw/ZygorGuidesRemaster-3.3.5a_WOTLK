local ZGV = ZygorGuidesViewer
if not (ZGV and ZGV.ItemScore) then return end

-- GLOBAL ZygorGearFinder

local L = ZGV.L
local G = _G
local FONT=ZGV.Font
local FONTBOLD=ZGV.FontBold
local CHAIN = ZGV.ChainCall
local ui = ZGV.UI
local SkinData = ui and ui.SkinData

local function GF_GetSlotLabel(slotKey, fallback)
	return _G[slotKey] or fallback
end

local tinsert,tremove,print,ipairs,pairs,wipe,debugprofilestop=tinsert,tremove,print,ipairs,pairs,wipe,debugprofilestop
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted

local ItemScore = ZGV.ItemScore
local GearFinder = {}
ItemScore.GearFinder = GearFinder
ItemScore.Items = {}

-- remove all non-player class drops, and all bosses that do not drop anything for player
function GearFinder:TrimDatabase() 
	local player = ZGV.ItemScore.playerclass

	for i,instance in pairs(ZygorGuidesViewer.ItemScore.Items) do
		for bossindex,boss in pairs(instance) do
			if type(boss)=="table" then
				for classindex,class in pairs(boss) do
					if type(class)=="table" then -- strip non quest drops for classes other than current
						if classindex~=player and classindex~="quest" then
							boss[classindex]=nil
						end
					end
				end
				if not boss[player] or #boss[player]==0 then -- strip bosses that do not offer anything to current class
					instance[bossindex]=nil
				end
			end
		end
	end
end

-- checks if gear from specific dungeon can be suggested
--	dungeon - int - dungeon id, as used in ZGV.Dungeons
--	instance - int - dungeon id, as used in ZGV.Dungeons
-- returns:
--	valid - bool - can be suggested now
--	future - bool - may contains upgrades later (level, ilvl, attunment)
--	ident - string or int - identificator of dungeon
--	maxscale - int - maximum level up to which drops are scaled
--	mythic - bool - is this a mythic dungeon
--	comment - string - verbose message
function GearFinder:IsValidDungeon(dungeon, instanceId)
	local ident = dungeon
	if ident==0 and instanceId then ident="e_"..instanceId end

	local dungeon = ZGV.Dungeons and ZGV.Dungeons[ident]

	if not dungeon then return false, false, ident, 0, false, "no dungeon" end
	if dungeon.phase and ZGV.Dungeons.Phases and not ZGV.Dungeons.Phases[dungeon.phase] then return false, false, ident, 0, false, "phase inactive" end

	-- 3.3.5a: no Chromie Time, no Mythic+
	local maxScaleLevel = dungeon.maxScaleLevel or 80

	-- handle permanent rejects
	if dungeon.max_level and dungeon.max_level<ItemScore.playerlevel then return false, false, ident, 0, false, "instance disabled" end
	if dungeon.expansionLevel>GearFinder.CurrentExpansion then return false, false, ident, 0, false, "no expansion " ..dungeon.expansionLevel end
	if dungeon.difficulty and not ZGV.db.profile["gear_"..dungeon.difficulty] then return false, false, ident, 0, false, "instance filtered out"..dungeon.difficulty end

	if dungeon.isHoliday then return false, false, ident, 0, false, "holiday dungeons not supported" end
	if dungeon.minLevel and dungeon.minLevel > (ItemScore.playerlevel+GearFinder.FUTURE_DUNGEONS_LIMIT) then return false, false, ident, 0, false, "need way higher level "..dungeon.minLevel end
	if dungeon.minLevel and dungeon.minLevel < (ItemScore.playerlevel-GearFinder.PAST_DUNGEONS_LIMIT) then return false, false, ident, 0, false, "outleveled "..dungeon.minLevel end
	if maxScaleLevel < (ItemScore.playerlevel-GearFinder.PAST_DUNGEONS_LIMIT) then return false, false, ident, 0, false, "outleveled "..maxScaleLevel..":"..(ItemScore.playerlevel-GearFinder.PAST_DUNGEONS_LIMIT)  end

	-- 3.3.5a: no LFG dungeon joinable check, no mythic
	local mythic = false
	local mythicplus = false

	-- handle future rejects
	if dungeon.minLevel and dungeon.minLevel > ItemScore.playerlevel then return false, true, ident, dungeon.maxScaleLevel, mythic, "need higher level" end
	-- 3.3.5a: no player ilvl system, skip min_ilevel check

	-- attunements
	if dungeon.attunement_achieve then
		local _,_,_,complete = GetAchievementInfo(dungeon.attunement_achieve)
		if not complete then return false, true, ident, maxScaleLevel, mythic, "attunement needed" end
	end	
	if dungeon.attunement_quest and not IsQuestFlaggedCompleted(dungeon.attunement_quest) then return false, true, ident, maxScaleLevel, mythic, "attunement needed" end
	if dungeon.attunement_queston and not (IsQuestFlaggedCompleted(dungeon.attunement_queston) or ZGV.Parser.ConditionEnv.haveq(dungeon.attunement_queston)) then return false, true, ident, maxScaleLevel, mythic, "attunement needed" end

	return true, true, ident, maxScaleLevel, mythic, mythicplus, "ok"
end

GearFinder.UpgradeQueue = {
	[INVSLOT_MAINHAND] = {},
	[INVSLOT_OFFHAND] = {},
	[INVSLOT_HEAD] = {},
	[INVSLOT_NECK] = {},
	[INVSLOT_SHOULDER] = {},
	[INVSLOT_BACK] = {},
	[INVSLOT_CHEST] = {},
	[INVSLOT_WRIST] = {},
	[INVSLOT_HAND] = {},
	[INVSLOT_WAIST] = {},
	[INVSLOT_LEGS] = {},
	[INVSLOT_FEET] = {},
	[INVSLOT_FINGER1] = {},
	[INVSLOT_FINGER2] = {},
	[INVSLOT_TRINKET1] = {},
	[INVSLOT_TRINKET2] = {},
}

if ZGV.IsClassic or ZGV.IsClassicTBC or ZGV.IsClassicWOTLK then
	GearFinder.UpgradeQueue[INVSLOT_RANGED] = {}
end

-- those slots should not have the same item suggested
local slot_pairs = {
	[INVSLOT_MAINHAND] = INVSLOT_OFFHAND,
	[INVSLOT_FINGER1] = INVSLOT_FINGER2,
	[INVSLOT_TRINKET1] = INVSLOT_TRINKET2,
}

-- checks if gearfounder got upgrades for all slots, so that we may skip looking for future upgrades
-- no params
-- returns
--	bool - are all slots filled
local function are_all_slots_filled()
	for slot,data in pairs(GearFinder.UpgradeQueue) do
		if not next(data) then
			return false
		end
	end
	return true
end

-- checks if item should be considered for weapon upgrade - don't switch between 2h and 1h when looking in dungeons
-- params:
--	current - bool - if user is using 2h weapon now
--	item - array - item that we will be checking
-- returns
--	valid - bool - should we queue this item
local function is_replacement(uses2h, item)
	if not item then return false end

	if (item.class == LE_ITEM_CLASS_WEAPON) or (item.type=="INVTYPE_HOLDABLE" or item.type=="INVTYPE_SHIELD") then
		return item.twohander == uses2h
	end

	return true
end

-- main worker function. goes first through all items prepared for scoring, if upgrades for all slots are not found, checks future items
-- sorts result slots by highest score and calls display when it is done
-- no params, no returns
local function loot_score_dungeon_thread()
	local total_current, total_future = 0,0
	for _,dungeon in pairs(GearFinder.ItemsToScore) do total_current = total_current + #dungeon end
	for _,dungeon in pairs(GearFinder.ItemsToMaybeScore) do total_future = total_future + #dungeon end
	local total = total_current + total_future

	GearFinder.MainFrame.Progress:SetPercent(0,"noanim")
	GearFinder.MainFrame.Progress:Show()
	local success_counter = 0


	local equipped_weapon = GetInventoryItemLink("player",INVSLOT_MAINHAND) and ItemScore:GetItemDetails(GetInventoryItemLink("player",INVSLOT_MAINHAND))
	local twohander_equipped = equipped_weapon and equipped_weapon.twohander

	while true do
		local fail_counter = 0
		for ident,dungeon in pairs(GearFinder.ItemsToScore) do
			for index,itemdata in pairs(dungeon) do
				local itemlink = itemdata.itemlink
				local item = ItemScore:GetItemDetails(itemlink)
				if not item then
					fail_counter = fail_counter + 1
				else
					success_counter = success_counter + 1
					local is_upgrade, slot, change, score, comment, futurevalid, slot_2, change_2  = ItemScore.Upgrades:IsUpgrade(itemlink)
					if is_upgrade and is_replacement(twohander_equipped,item)  then
						item.ident = ident
						item.boss = itemdata.boss
						item.bossname = itemdata.bossname
						item.encounterId = itemdata.encounterId
						item.quest = itemdata.quest
						if not (item.quest and IsQuestFlaggedCompleted(item.quest)) then
							table.insert(GearFinder.UpgradeQueue[slot],item)

							if slot_2 then table.insert(GearFinder.UpgradeQueue[slot_2],item) end
						end
					elseif futurevalid then
						GearFinder.ItemsToMaybeScore[ident] = GearFinder.ItemsToMaybeScore[ident] or {}
						table.insert(GearFinder.ItemsToMaybeScore[ident],itemdata)
					end
					GearFinder.ItemsToScore[ident][index]=nil
				end
			end
			ZGV:Debug("&gear current scored %d of %d/%d",success_counter,total_current,total)
			ZGV:Debug("&gear current failed %d",fail_counter)
			coroutine.yield()
			local ready = success_counter / total * 100
			GearFinder.MainFrame.Progress:SetPercent(ready)
		end
		if fail_counter==0 then break end
	end

	GearFinder.DungeonItemsScored = true
	local t2 = debugprofilestop()
	ZGV:Debug("&gear scoring current took %d",t2-GearFinder.TimeScoreStart)

	for i,slotupgrades in pairs(GearFinder.UpgradeQueue) do 
		table.sort(slotupgrades,function(a,b) return a.score>b.score end)
	end

	-- remove duplicates from primary/secondary slots
	for first,second in pairs(slot_pairs) do
		local first_equipped = ItemScore:GetItemDetails(ItemScore.Upgrades.EquippedItems[first].itemlink)
		local second_equipped = ItemScore:GetItemDetails(ItemScore.Upgrades.EquippedItems[second].itemlink)
		local first_queue = GearFinder.UpgradeQueue[first]
		local second_queue = GearFinder.UpgradeQueue[second]

		if first_queue[1] and second_queue[1] and first_queue[1]==second_queue[1] then
			if not first_equipped or first_equipped.twohander then
				ZGV:Debug("&itemscore SDG same item, drop second, no first")
				table.remove(second_queue,1)
			elseif not first_equipped then		
				ZGV:Debug("&itemscore SDG same item, drop first, no second")
				table.remove(first_queue,1)
			elseif second_queue[2] then
				ZGV:Debug("&itemscore SDG same item, drop second, has options")
				table.remove(second_queue,1)
			elseif first_queue[2] then
				ZGV:Debug("&itemscore SDG same item, drop first, has options")
				table.remove(first_queue,1)
			else
				ZGV:Debug("&itemscore SDG same item, drop second, no choice")
				table.remove(second_queue,1)
			end
		end
	end

	if are_all_slots_filled() then 
		GearFinder.ResultsReady=true 
		GearFinder.MainFrame.Progress:Hide()
		ZGV:CancelTimer(GearFinder.AntsTimer) 
		GearFinder:DisplayResults()
		return
	else
		GearFinder:DisplayResults()
		GearFinder.AntsMode = "future "
	end

	table.sort(GearFinder.FutureDungeons,function(a,b) if a.minLevel==b.minLevel then return a.min_ilevel<b.min_ilevel else return a.minLevel<b.minLevel end end)
	while true do
		local fail_counter = 0
		for _,dungeon in ipairs(GearFinder.FutureDungeons) do
			if GearFinder.ItemsToMaybeScore[dungeon.ident] then
				for index,itemdata in pairs(GearFinder.ItemsToMaybeScore[dungeon.ident]) do
					local itemlink = itemdata.itemlink
					local item = ItemScore:GetItemDetails(itemlink)
					if not item then 
						fail_counter = fail_counter + 1
					else
						success_counter = success_counter + 1
						local is_upgrade, slot, change, score, comment, validfuture, slot_2, change_2 = ItemScore.Upgrades:IsUpgrade(itemlink,"future")
						-- only record future items for slots that do not have upgrades from current dungeons
						-- if slot and GearFinder.UpgradeQueue[slot] then--and not GearFinder.UpgradeQueue[slot][1] then
						if slot and GearFinder.UpgradeQueue[slot] and (not GearFinder.UpgradeQueue[slot][1] or GearFinder.UpgradeQueue[slot][1].future) then
							if is_upgrade and is_replacement(twohander_equipped,item) then
								item.ident = dungeon.ident
								item.min_ilevel = dungeon.min_ilevel
								item.boss = itemdata.boss
								item.encounterId = itemdata.encounterId
								item.future = true
								item.quest = itemdata.quest
								if not (item.quest and IsQuestFlaggedCompleted(item.quest)) then
									table.insert(GearFinder.UpgradeQueue[slot],item)

									if slot_2 then table.insert(GearFinder.UpgradeQueue[slot_2],item) end
								end
							end
						end
						GearFinder.ItemsToMaybeScore[dungeon.ident][index]=nil
					end
				end
				local ready = success_counter / total * 100
				ZGV:Debug("&gear future scored %d of %d/%d",success_counter,total_future,total)
				ZGV:Debug("&gear future failed %d",fail_counter)
				GearFinder.MainFrame.Progress:SetPercent(ready)
				coroutine.yield()
			end
		end
		if fail_counter==0 then break end
	end

	for i,slotupgrades in pairs(GearFinder.UpgradeQueue) do 
		table.sort(slotupgrades,function(a,b)
			if a.future and b.future then -- future, find earliest
				if a.minLevel==b.minLevel and a.min_ilevel==b.min_ilevel then 
					return a.score>b.score -- same requirements, sort by score
				elseif a.minLevel==b.minLevel then
					return a.min_ilevel<b.min_ilevel -- same player level, sort by dungeon minilvl
				else 
					return a.minLevel<b.minLevel  -- sort by item min player level
				end
			else -- not future, sort by score
				return a.score>b.score
			end
		end)
	end

	local t3 = debugprofilestop()
	ZGV:Debug("&gear scoring future took %d",t3-t2)
	ZGV:Debug("&gear scoring all took %d",t3-GearFinder.TimeScoreStart)
	GearFinder.ResultsReady=true
	GearFinder.MainFrame.Progress:Hide()

	ZGV:CancelTimer(GearFinder.AntsTimer) 
	GearFinder.AntsTimer = nil
	GearFinder:DisplayResults()
end

-- show crawling dots while calculation is running
-- executed on timer
-- no params
-- no returns
local function progress_dots()
	local progress_time = math.floor(debugprofilestop())%1500

	local progress_dots = ""
	if progress_time < 500 then
		progress_dots = "."
	elseif progress_time < 1000 then
		progress_dots = ".."
	else
		progress_dots = "..."
	end

	local Buttons = GearFinder.MainFrame.Buttons
	local searchingKey = GearFinder.AntsMode == "future " and "gearfinder_status_searching_future" or "gearfinder_status_searching"
	for i,v in pairs(GearFinder.UpgradeQueue) do
		local button = Buttons[i]
		if not button.link then
			button.itemdungeon:SetText(L[searchingKey]:format(progress_dots))
		end
	end
end

-- prepares item lists for worker thread to work on
-- items from valid dungeons are added to ItemsToScore
-- items from dungeons that are not valid, but can be valid soon to ItemsToMaybeScore and dungeons to FutureDungeons
-- starts thread and resumes it 10 times a second
-- no params
-- no returns
GearFinder.ItemsToScore = {}
GearFinder.ItemsToMaybeScore = {}
GearFinder.FutureDungeons = {}
function GearFinder:ScoreDungeonItems()
	if GearFinder.ResultsReady then return end

	GearFinder.CurrentExpansion = (GetClassicExpansionLevel and GetClassicExpansionLevel()) or (GetServerExpansionLevel and GetServerExpansionLevel()) or 2 -- 2 = WOTLK

	GearFinder.TimeScoreStart = debugprofilestop()
	GearFinder.MainFrame.overlay:Hide()

	GearFinder.DungeonItemsScored = false

	local player = ZGV.ItemScore.playerclass or "ALL"
	for i,v in pairs(GearFinder.UpgradeQueue) do table.wipe(v) end
	table.wipe(GearFinder.ItemsToScore)
	table.wipe(GearFinder.ItemsToMaybeScore)
	table.wipe(GearFinder.FutureDungeons)

	local faction = self.playerfaction=="Alliance" and 1 or 2

	-- 3.3.5a: no mythic+, no modified instances
	for dungeon,dungeondata in pairs(ZGV.ItemScore.Items) do
		local valid, future, ident, maxscale, mythic, mythicplus, comment = GearFinder:IsValidDungeon(dungeondata.dungeon or dungeondata.dungeonmap, dungeondata.instanceId)
		local capped_player_level = math.min(maxscale or 80, ItemScore.playerlevel)

		if valid then
			GearFinder.ItemsToScore[ident] = {}
			for boss,bossdata in pairs(dungeondata) do
				if type(bossdata)=="table" and (not bossdata.phase or (ZGV.Dungeons and ZGV.Dungeons.Phases and ZGV.Dungeons.Phases[bossdata.phase])) then
					local player_items = bossdata[player] or bossdata["ALL"]
					if player_items then
						for _,itemlink in pairs(player_items) do
							if type(itemlink)=="number" then itemlink = "item:"..itemlink end
							-- 3.3.5a: no level scaling, no mythic bonuses
							local qname
							if bossdata.quest and bossdata.quest[faction] then
								qname = ZGV.QuestDB and ZGV.QuestDB:GetQuestName(bossdata.quest[faction])
							end
							table.insert(GearFinder.ItemsToScore[ident],{itemlink=itemlink,boss=bossdata.boss, bossname=bossdata.name, encounterId=bossdata.encounterId, quest=bossdata.quest and bossdata.quest[faction], questname=qname})
						end
					end
				end
			end
		elseif future then
			local future_dungeon = ZGV.Dungeons and ZGV.Dungeons[ident]
			if future_dungeon then
				table.insert(GearFinder.FutureDungeons,{ident=ident,minLevel=future_dungeon.minLevel or 0,min_ilevel=future_dungeon.min_ilevel or 0})
			end

			GearFinder.ItemsToMaybeScore[ident] = {}

			for boss,bossdata in pairs(dungeondata) do
				if type(bossdata)=="table" and (not bossdata.phase or (ZGV.Dungeons and ZGV.Dungeons.Phases and ZGV.Dungeons.Phases[bossdata.phase])) then
					local player_items = bossdata[player] or bossdata["ALL"]
					if player_items then
						for _,itemlink in pairs(player_items) do
							if type(itemlink)=="number" then itemlink = "item:"..itemlink end
							-- 3.3.5a: no level scaling, no mythic bonuses
							local qname
							if bossdata.quest and bossdata.quest[faction] then
								qname = ZGV.QuestDB and ZGV.QuestDB:GetQuestName(bossdata.quest[faction])
							end
							table.insert(GearFinder.ItemsToMaybeScore[ident],{itemlink=itemlink,boss=bossdata.boss, bossname=bossdata.name, encounterId=bossdata.encounterId, quest=bossdata.quest and bossdata.quest[faction], questname=qname})
						end
					end
				end
			end
		end
	end

	GearFinder.ScoreThread = coroutine.create(loot_score_dungeon_thread)
	if GearFinder.ScoreTimer then 
		ZGV:CancelTimer(GearFinder.ScoreTimer) 
		GearFinder.ScoreTimer = nil
	end
	GearFinder.ScoreTimer = ZGV:ScheduleRepeatingTimer(function()
		local ok,ret = coroutine.resume(GearFinder.ScoreThread)
		if not ok or coroutine.status(GearFinder.ScoreThread)=="dead" then 
			ZGV:CancelTimer(GearFinder.ScoreTimer) 

		end
	end,
	0.1)
	GearFinder.AntsMode = ""
	GearFinder.AntsTimer = ZGV:ScheduleRepeatingTimer(function() progress_dots() end, 0.5)
end

-- used to make item slots in gear finder window. creates texture and fontstrings, sets tooltip calls
-- params
--	object - array - int texture id, int slot id, string slot name
-- returns:
--	button - frame - pack of objects that make one slot
local function make_button(object)
	local parent = GearFinder.MainFrame.CenterColumn or GearFinder.MainFrame
	local button = CHAIN(CreateFrame("Button",nil,parent))
		:SetFrameLevel(parent:GetFrameLevel()+2)
		:SetSize(260,40)
		:Show()
	.__END
		button:SetScript("OnEnter",function()
			if button.dungeonguide then
				button.loadguide:Show()
			end
		end)
		button:SetScript("OnLeave",function()
			button.loadguide:Hide()
		end)


	button.tooltiphandler = CHAIN(CreateFrame("Button",nil,button))
		:SetFrameLevel(button:GetFrameLevel()+1)
		:SetPoint("TOPLEFT")
		:SetSize(40,40)
	.__END	
		button.itemicon = CHAIN(button.tooltiphandler:CreateTexture()) 
			:SetSize(40,40)
			:SetPoint("TOPLEFT",button) 
			:SetTexture(object[1])
		.__END

		button.tooltiphandler:SetScript("OnEnter",function()
			GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
			if button.link then
				GameTooltip:SetHyperlink(button.link)
			else
				GameTooltip:SetText(button.slotName)
			end
			GameTooltip:Show()
		end)
		button.tooltiphandler:SetScript("OnLeave",function()
			GameTooltip:FadeOut()
		end)


	button.itemlink = CHAIN(button:CreateFontString())
		:SetPoint("TOPLEFT",button.itemicon,"TOPRIGHT",5,0)
		:SetFont(FONT,12)
		:SetText("")
		:SetWidth(210)
		:SetJustifyH("LEFT")
		:SetWordWrap(false)
	.__END

	button.itemdungeon = CHAIN(button:CreateFontString())
		:SetPoint("TOPLEFT",button.itemlink,"BOTTOMLEFT",0,-3)
		:SetFont(FONT,10)
		:SetText(L["gearfinder_no_upgrade"])
		:SetWidth(210)
		:SetJustifyH("LEFT")
		:SetWordWrap(false)
	.__END
	button.itemencounter = CHAIN(button:CreateFontString())
		:SetPoint("TOPLEFT",button.itemdungeon,"BOTTOMLEFT",0,-3)
		:SetFont(FONT,10)
		:SetText("")
		:SetWidth(210)
		:SetJustifyH("LEFT")
		:SetWordWrap(false)
	.__END

	button.loadguide = CHAIN(ZGV.CreateFrameWithBG("Button", nil, button, nil))
		:SetBackdropColor(0,0,0,1)
		:SetBackdropBorderColor(0,0,0,0)
		:SetSize(20,20)
		:SetPoint("RIGHT")
		:Hide()
		:SetScript("OnEnter",function()
			button.loadguide:Show()
			GameTooltip:SetOwner(button, "ANCHOR_TOP")
			GameTooltip:SetText(L["gearfinder_load_guide"] or L["frame_selectguide"])
			GameTooltip:Show()
		end)
		:SetScript("OnLeave",function()
			button.loadguide:Hide()
			GameTooltip:Hide()
		end)
		:SetScript("OnClick",function(self,b)
			if button.dungeonguide then
				if ZGV.Tabs and ZGV.Tabs.LoadGuideToTab then
					ZGV.Tabs:LoadGuideToTab(button.dungeonguide,button.dungeonguide.CurrentStepNum or 1)
				end
			end
		end)
	.__END

	button.slotID = object[2]
	button.slotName = object[3]
	button.slotTexture = object[1]
	button.dungeonguide = nil
	return button
end

-- update gearfinder window to use current skin
-- no params
-- no returns
function GearFinder:ApplySkin()
	local MF = GearFinder.MainFrame
	if not MF then return end

	MF.Logo:SetTexture("Interface\\Icons\\INV_Chest_Chain_04")
	MF.Logo:SetSize(24, 24)
	MF.Logo:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- CenterColumn positioning set in CreateMainFrame

	MF.FooterSettingsButton:SetPoint("BOTTOMRIGHT",-12,8)
end

-- creates main frame, with header and footer, adds entries for all equip slots and guide info
-- no params
-- no returns
function GearFinder:CreateMainFrame()
	if self.MainFrame then return end

	GearFinder:AttachFrame()

	self.MainFrame = CHAIN(ZGV.CreateFrameWithBG("Frame","ZygorGearFinder",CharacterFrame))
		:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT")
		:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMLEFT")
		:SetWidth(580)
		:SetFrameStrata("HIGH")
		:SetFrameLevel(CharacterFrame:GetFrameLevel()+10)
		:SetToplevel(true)
		.__END
	-- Solid background so character sheet doesn't bleed through
	self.MainFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\white8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self.MainFrame:SetBackdropColor(0.05, 0.05, 0.08, 1.0)
	self.MainFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1.0)

	local MF = self.MainFrame

	MF.Logo = CHAIN(MF:CreateTexture())
		:SetPoint("TOP",MF,"TOP",0,-3)
	.__END
	MF.Title = CHAIN(MF:CreateFontString())
		:SetPoint("TOPLEFT",8,-8)
		:SetFont(FONT,14)
		:SetTextColor(1, 0.82, 0)
		:SetText(L["gearfinder_title"])
	 .__END
	MF.close = CHAIN(CreateFrame("Button",nil,MF,"UIPanelCloseButton"))
		:SetPoint("TOPRIGHT",-2,-2)
		:SetSize(20,20)
		:SetScript("OnClick", function()
			MF:Hide()
			HideUIPanel(CharacterFrame)
		end)
		.__END

	-- Footer
	MF.FooterSettingsButton = CHAIN(CreateFrame("Button",nil,MF))
		:SetPoint("BOTTOMRIGHT",-8,5)
		:SetSize(15,15)
		:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
		:SetScript("OnClick",function() ZGV:OpenOptions("gear") end)
	.__END

	-- content container
	MF.CenterColumn = CHAIN(ZGV.CreateFrameWithBG("Frame", nil, MF))
		:SetPoint("TOPLEFT", MF, "TOPLEFT", 10, -35)
		:SetPoint("BOTTOMRIGHT", MF, "BOTTOMRIGHT", -10, 25)
		:EnableMouse(true)
		:Show()
		.__END
	MF.CenterColumn:SetBackdropColor(0.03, 0.03, 0.05, 0.6)
	MF.CenterColumn:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.5)


	-- 3.3.5a: use texture paths instead of FileDataIDs
	local SLOT_TEXTURES = {
		Head      = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head",
		Neck      = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck",
		Shoulder  = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder",
		Back      = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
		Chest     = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
		Wrist     = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists",
		MainHand  = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
		OffHand   = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand",
		Ranged    = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged",
		Hands     = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands",
		Waist     = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist",
		Legs      = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs",
		Feet      = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet",
		Finger    = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
		Trinket   = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
	}

	local left_column = {
		{SLOT_TEXTURES.Head,     INVSLOT_HEAD,     GF_GetSlotLabel("HEADSLOT", "Head")},
		{SLOT_TEXTURES.Neck,     INVSLOT_NECK,     GF_GetSlotLabel("NECKSLOT", "Neck")},
		{SLOT_TEXTURES.Shoulder, INVSLOT_SHOULDER, GF_GetSlotLabel("SHOULDERSLOT", "Shoulder")},
		{SLOT_TEXTURES.Back,     INVSLOT_BACK,     GF_GetSlotLabel("BACKSLOT", "Back")},
		{SLOT_TEXTURES.Chest,    INVSLOT_CHEST,    GF_GetSlotLabel("CHESTSLOT", "Chest")},
		{SLOT_TEXTURES.Wrist,    INVSLOT_WRIST,    GF_GetSlotLabel("WRISTSLOT", "Wrist")},
		{SLOT_TEXTURES.MainHand, INVSLOT_MAINHAND, GF_GetSlotLabel("MAINHANDSLOT", "Main Hand")},
		{SLOT_TEXTURES.OffHand,  INVSLOT_OFFHAND,  GF_GetSlotLabel("SECONDARYHANDSLOT", "Off Hand")},
		{SLOT_TEXTURES.Ranged,   INVSLOT_RANGED,   GF_GetSlotLabel("RANGEDSLOT", "Ranged")},
	}

	local right_column = {
		{SLOT_TEXTURES.Hands,   INVSLOT_HAND,     GF_GetSlotLabel("HANDSSLOT", "Hands")},
		{SLOT_TEXTURES.Waist,   INVSLOT_WAIST,    GF_GetSlotLabel("WAISTSLOT", "Waist")},
		{SLOT_TEXTURES.Legs,    INVSLOT_LEGS,     GF_GetSlotLabel("LEGSSLOT", "Legs")},
		{SLOT_TEXTURES.Feet,    INVSLOT_FEET,     GF_GetSlotLabel("FEETSLOT", "Feet")},
		{SLOT_TEXTURES.Finger,  INVSLOT_FINGER1,  GF_GetSlotLabel("FINGER0SLOT", "Ring 1")},
		{SLOT_TEXTURES.Finger,  INVSLOT_FINGER2,  GF_GetSlotLabel("FINGER1SLOT", "Ring 2")},
		{SLOT_TEXTURES.Trinket, INVSLOT_TRINKET1, GF_GetSlotLabel("TRINKET0SLOT", "Trinket 1")},
		{SLOT_TEXTURES.Trinket, INVSLOT_TRINKET2, GF_GetSlotLabel("TRINKET1SLOT", "Trinket 2")},
	}

	MF.Buttons = {}
	local previous = nil
	for i,object in ipairs(left_column) do
		local button = make_button(object)
	
		if previous then
			button:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-6)
		else
			button:SetPoint("TOPLEFT",MF.CenterColumn,"TOPLEFT",10,-10)
		end
		previous = button
		MF.Buttons[object[2]] = button
	end

	local previous = nil
	for i,object in ipairs(right_column) do
		local button = make_button(object)
	
		if previous then
			button:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-6)
		else
			button:SetPoint("TOPLEFT",MF.Buttons[INVSLOT_HEAD],"TOPRIGHT",20,0)
		end
		previous = button
		MF.Buttons[object[2]] = button
	end

	MF.DungeonImage = CHAIN(MF.CenterColumn:CreateTexture(nil,"ARTWORK")) 
		:SetSize(140,89) 
		:SetPoint("TOPRIGHT",-10,-10) 
		:SetTexture(ZGV.DIR.."\\Skins\\menu_noguide")
		:SetTexCoord(0,220/256,0,139/256)
	.__END

	MF.DungeonMessage = CHAIN(MF.CenterColumn:CreateFontString())
		:SetPoint("TOPLEFT",MF.DungeonImage,"BOTTOMLEFT",0,-10)
		:SetFont(FONT,10)
		:SetText(L["gearfinder_suggested_dungeon"])
		:SetWidth(120)
		:SetJustifyH("CENTER")
		:Hide()
	.__END

	MF.AddButton = CHAIN(ZGV.CreateFrameWithBG("Button", nil, MF.CenterColumn, nil))
		:SetBackdropColor(0,0,0,1)
		:SetBackdropBorderColor(0,0,0,0)
		:SetSize(20,20)
		:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
		:SetScript("OnEnter",function()
			GameTooltip:SetOwner(MF.AddButton, "ANCHOR_TOP")
			GameTooltip:SetText(L["gearfinder_load_guide"] or L["frame_selectguide"])
			GameTooltip:Show()
		end)
		:SetScript("OnLeave",function()
			GameTooltip:Hide()
		end)
		:SetScript("OnClick",function()
			if GearFinder.BestDungeonGuide and ZGV.Tabs and ZGV.Tabs.LoadGuideToTab then
				ZGV.Tabs:LoadGuideToTab(GearFinder.BestDungeonGuide,GearFinder.BestDungeonGuide.CurrentStepNum or 1)
			end
		end)
		:SetPoint("TOPRIGHT",MF.DungeonMessage,"BOTTOMRIGHT",20,-10)
		:Hide()
	.__END

	MF.DungeonName = CHAIN(MF.CenterColumn:CreateFontString())
		:SetPoint("TOPLEFT",MF.DungeonMessage,"BOTTOMLEFT",0,-10)
		:SetFont(FONT,12)
		:SetText("")
		:SetWidth(120)
		:SetJustifyH("CENTER")
	.__END
	MF.DungeonDesc = CHAIN(MF.CenterColumn:CreateFontString())
		:SetPoint("TOPLEFT",MF.DungeonName,"BOTTOMLEFT",0,0)
		:SetFont(FONT,10)
		:SetText("")
		:SetWidth(120)
		:SetJustifyH("CENTER")
	.__END


	-- Simple progress bar (plain StatusBar instead of custom widget)
	MF.Progress = CreateFrame("StatusBar", nil, MF)
	MF.Progress:SetSize(500, 7)
	MF.Progress:SetFrameLevel(MF:GetFrameLevel()+3)
	MF.Progress:SetPoint("BOTTOMLEFT", MF, "BOTTOMLEFT", 5, 5)
	MF.Progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	MF.Progress:GetStatusBarTexture():SetVertexColor(0.2, 0.6, 1.0)
	MF.Progress:SetMinMaxValues(0, 100)
	MF.Progress:SetValue(0)
	MF.Progress.Texture = MF.Progress:GetStatusBarTexture()
	function MF.Progress:SetPercent(pct, mode)
		self:SetValue(pct or 0)
	end

	tinsert(UISpecialFrames, "ZygorGearFinder") -- allows the frame to be closable with ESC keypress

	MF.overlay = CHAIN(ZGV.CreateFrameWithBG("Button",nil,MF))
		:SetPoint("TOPLEFT",MF,"TOPLEFT",10,-27)
		:SetPoint("BOTTOMRIGHT",MF,"BOTTOMRIGHT",-10,20)
		:SetBackdropColor(0,0,0,0.7)
		:SetBackdropBorderColor(0,0,0,0.7)
		:SetFrameLevel(MF:GetFrameLevel()+5)
		:SetScript("OnClick", function() GearFinder:ScoreDungeonItems() end)
		:SetScript("OnEnter",function()
			GameTooltip:SetOwner(MF.overlay, "ANCHOR_CURSOR")
			GameTooltip:SetText(L["gearfinder_refresh"])
			GameTooltip:Show()
		end)
		:SetScript("OnLeave",function()
			GameTooltip:FadeOut()
		end)
		:Hide()
	.__END

	MF.overlay.tex = MF.overlay:CreateTexture()
	MF.overlay.tex:SetTexture(ZGV.DIR.."\\Skins\\refresh")
	MF.overlay.tex:SetSize(32,32)
	MF.overlay.tex:SetPoint("CENTER")


	ZGV:AddMessageHandler("SKIN_UPDATED",GearFinder.ApplySkin)
	GearFinder:ApplySkin()
	MF:Hide()
end

-- maps difficulty id to display name (normal, heroic etc)
local diff_to_name = {
	[1]=PLAYER_DIFFICULTY1,
	[2]=PLAYER_DIFFICULTY2,
	[3]=PLAYER_DIFFICULTY1,
	[4]=PLAYER_DIFFICULTY1,
	[5]=PLAYER_DIFFICULTY2,
	[6]=PLAYER_DIFFICULTY2,
	[7]=PLAYER_DIFFICULTY3,
	[23]=PLAYER_DIFFICULTY6,
	[24]=PLAYER_DIFFICULTY_TIMEWALKER,
	[17]=PLAYER_DIFFICULTY3,
	[14]=PLAYER_DIFFICULTY1,
	[15]=PLAYER_DIFFICULTY2,
	[16]=PLAYER_DIFFICULTY6,
}

local function find_dungeon_guide(ident)
	local dungeon = ZGV.Dungeons[ident]

	if not dungeon then return false end

	local dungeon_guide, dungeon_map, dungeon_lfg

	if type(dungeon.map)=="table" then
		for i,v in pairs(dungeon.map) do
			if not dungeon_map or v<dungeon_map then dungeon_map = v end
		end
	else
		dungeon.map = dungeon.map
	end
	dungeon_map = tonumber(dungeon_map)
	dungeon_lfg = tonumber(dungeon.id)

	if dungeon_lfg then
		for g,guide in ipairs(ZGV.registeredguides) do -- check by lfg codes first, for winded instances
			if tonumber(guide.lfgid)==(dungeon_lfg) then dungeon_guide=guide break end
		end
	end

	if not dungeon_guide and dungeon_map then
		for g,guide in ipairs(ZGV.registeredguides) do -- if nothing, then use dungeon maps
			if tonumber(guide.mapid)==tonumber(dungeon_map) then dungeon_guide=guide break end
		end
	end

	return dungeon_guide,dungeon
end

-- displays equipped items with scores and any bag upgrades found
function GearFinder:DisplayResults()
	if not GearFinder.MainFrame then return end

	local MF = GearFinder.MainFrame
	local Buttons = MF.Buttons
	local Upgrades = ItemScore.Upgrades

	-- First: show dungeon upgrades if any were found
	local hasDungeonUpgrades = false
	for i,v in pairs(GearFinder.UpgradeQueue) do
		if v[1] then hasDungeonUpgrades = true break end
	end

	for slotID, button in pairs(Buttons) do
		-- Check for dungeon upgrade first
		local dungeonUpgrade = GearFinder.UpgradeQueue[slotID] and GearFinder.UpgradeQueue[slotID][1]

		-- Check for bag upgrade
		local bagUpgrade = Upgrades and Upgrades.UpgradeQueue and Upgrades.UpgradeQueue[slotID]
		local hasBagUpgrade = bagUpgrade and bagUpgrade.itemlink

		-- Get currently equipped item
		local equippedLink = GetInventoryItemLink("player", slotID)
		local equippedItem = equippedLink and ItemScore:GetItemDetails(equippedLink)
		if not equippedItem then equippedItem = equippedLink and ItemScore:GetItemDetailsQueued(equippedLink, true) end
		local equippedScore = equippedItem and equippedItem.score
		if not equippedScore and equippedItem then
			equippedScore = select(1, ItemScore:GetItemScore(equippedItem.itemlink))
		end

		if dungeonUpgrade then
			-- Dungeon upgrade found
			local name, itemlink = ZGV:GetItemInfo(dungeonUpgrade.itemlink)
			button.itemicon:SetTexture(dungeonUpgrade.texture)
			button.itemlink:SetText(itemlink or dungeonUpgrade.itemlink)
			button.link = itemlink
			button.itemicon:SetDesaturated(dungeonUpgrade.future)
			button:SetAlpha(dungeonUpgrade.future and 0.5 or 1)

			local dungeon = ZGV.Dungeons[dungeonUpgrade.ident]
			button.itemdungeon:SetText(("|cff00ff00%s|r %s"):format(L["gearfinder_label_dungeon"], (dungeon and dungeon.name) or L["gearfinder_label_unknown"]))
			button.itemencounter:SetText(dungeonUpgrade.bossname or "")

		elseif hasBagUpgrade then
			-- Bag upgrade found
			local bagItem = ItemScore:GetItemDetails(bagUpgrade.itemlink)
			if not bagItem then bagItem = ItemScore:GetItemDetailsQueued(bagUpgrade.itemlink, true) end
			if bagItem then
				button.itemicon:SetTexture(bagItem.texture)
				button.itemlink:SetText(bagItem.itemlinkfull or bagUpgrade.itemlink)
				button.link = bagItem.itemlinkfull
				button:SetAlpha(1)
				local changeText = bagUpgrade.change and bagUpgrade.change > 0 and ("|cff00ff00" .. L["gearfinder_upgrade_percent"]:format(math.floor(bagUpgrade.change)) .. "|r") or ""
				button.itemdungeon:SetText(("|cff44ff44%s|r %s"):format(L["gearfinder_label_inbags"], changeText))
				button.itemencounter:SetText("")
			end

		elseif equippedItem then
			-- Show currently equipped item
			button.itemicon:SetTexture(equippedItem.texture)
			button.itemlink:SetText(equippedItem.itemlinkfull or equippedLink)
			button.link = equippedItem.itemlinkfull
			button:SetAlpha(0.7)
			local scoreText = equippedScore and equippedScore > 0 and L["gearfinder_label_score"]:format(math.floor(equippedScore)) or ""
			button.itemdungeon:SetText("|cffaaaaaa"..scoreText.."|r")
			button.itemencounter:SetText("|cffaaaaaa"..L["gearfinder_label_equipped"].."|r")

		else
			-- Empty slot
			button.itemicon:SetTexture(button.slotTexture)
			button.itemlink:SetText(" ")
			button.link = nil
			button.itemdungeon:SetText("|cffff8800"..L["gearfinder_label_empty"].."|r")
			button.itemencounter:SetText(" ")
			button.itemicon:SetDesaturated(false)
			button:SetAlpha(0.4)
		end
	end

	-- Dungeon suggestion (original logic)
	local dungeons = {}
	for i,v in pairs(GearFinder.UpgradeQueue) do
		if v[1] and not v[1].future then
			dungeons[v[1].ident] = (dungeons[v[1].ident] or 0) + 1
		end
	end

	local sorted_dungeons = {}
	for i,v in pairs(dungeons) do
		table.insert(sorted_dungeons,{i,v})
	end
	table.sort(sorted_dungeons,function(x,y) return x[2]>y[2] end)

	local best_dungeon = sorted_dungeons[1]

	if best_dungeon then
		-- find guide for it 
		local dungeon_guide, dungeon = find_dungeon_guide(best_dungeon[1])
		if dungeon_guide then 
			GearFinder.BestDungeonGuide = dungeon_guide

			MF.DungeonMessage:Show()
			if dungeon_guide.image then 
				MF.DungeonImage:SetTexture(dungeon_guide.image) 
				MF.DungeonImage:SetTexCoord(0,1,0,1)
			end
			MF.AddButton:Show()
		else
			MF.AddButton:Hide()
		end

		MF.DungeonName:SetText(dungeon.name)
		MF.DungeonName:Show()
			MF.DungeonDesc:SetText((diff_to_name[dungeon.difficulty] or "") .. "\n\n" .. L["gearfinder_items_found"]:format(best_dungeon[2]))
			MF.DungeonDesc:Show()
		end

end

-- clears all displayed results, to be used when gearfinder/itemscore settings are changed or when user changes level/spec
-- no params
-- no returns
function GearFinder:ClearResults()
	if not GearFinder.MainFrame then return end
	local MF = GearFinder.MainFrame
	GearFinder.ResultsReady = false

	for i,v in pairs(ItemScore.GearFinder.UpgradeQueue) do 
		table.wipe(v) 
	end

	MF.DungeonMessage:Hide()
	MF.DungeonImage:SetTexture(ZGV.DIR.."\\Skins\\menu_noguide")
	MF.DungeonImage:SetTexCoord(0,220/256,0,139/256)
	MF.DungeonName:Hide()
	MF.DungeonDesc:Hide()
	MF.AddButton:Hide()

	for i,button in pairs(MF.Buttons) do
		button.itemicon:SetTexture(button.slotTexture)
		button.itemlink:SetText(" ")
		button.link = nil
		button.dungeonguide = nil
		button.itemdungeon:SetText(L["gearfinder_no_upgrade"])
		button.itemencounter:SetText(" ")
		button.itemicon:SetDesaturated(false)
		button:SetAlpha(0.5)
	end

	MF.overlay:Show()
end
