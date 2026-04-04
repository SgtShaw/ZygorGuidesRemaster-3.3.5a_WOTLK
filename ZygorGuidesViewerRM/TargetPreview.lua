local me = ZygorGuidesViewer
if not me then return end

local L = me.L

local PREVIEW_DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local PREVIEW_WIDTH = 190
local PREVIEW_HEIGHT = 255
local PREVIEW_PADDING = 8
local PREVIEW_SNAP_THRESHOLD_X = 120
local PREVIEW_SNAP_THRESHOLD_Y = 90
local PREVIEW_CLOSE_SIZE = 16
local PREVIEW_ROTATION_SPEED = 0.008
local PREVIEW_TARGET_CAM_DISTANCE = 1.7

local function TP_ApplyIcon(texture, icon)
	if not texture then return end
	if type(icon) == "table" then
		texture:SetTexture(icon.file or PREVIEW_DEFAULT_ICON)
		if icon.coords then
			local l, r, t, b = unpack(icon.coords)
			local crop = icon.crop or 0.03
			local xinset = (r - l) * crop
			local yinset = (b - t) * crop
			texture:SetTexCoord(l + xinset, r - xinset, t + yinset, b - yinset)
		else
			texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end
	else
		texture:SetTexture(icon or PREVIEW_DEFAULT_ICON)
		texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
end

local function TP_GetClassificationText(unit)
	if not unit or not UnitExists(unit) then return nil end
	local class = UnitClassification(unit)
	if class == "worldboss" then return "Boss" end
	if class == "elite" then return "Elite" end
	if class == "rareelite" then return "Rare Elite" end
	if class == "rare" then return "Rare" end
end

local function TP_GetLevelText(unit)
	if not unit or not UnitExists(unit) then return nil end
	local level = UnitLevel(unit)
	if not level or level < 0 then
		return (LEVEL or "Level") .. " ??"
	end
	return string.format("%s %d", LEVEL or "Level", level)
end

local function TP_GetReactionColor(unit)
	if not unit or not UnitExists(unit) then
		return 1, 1, 1
	end
	if UnitIsFriend and UnitIsFriend("player", unit) then
		return 0.10, 0.85, 0.20
	end
	if UnitCanAttack and UnitCanAttack("player", unit) then
		return 0.92, 0.18, 0.18
	end
	local reaction = UnitReaction(unit, "player")
	if not reaction then
		return 1, 1, 1
	end
	if reaction == 4 then
		return 1.00, 0.82, 0.12
	end
	return 1, 1, 1
end

local function TP_SubjectMatchesTarget(subject)
	if not subject or not subject.target or not UnitExists("target") then return false end
	local name = UnitName("target")
	if not name then return false end
	if name == subject.target then return true end
	if subject.targetaliases then
		for _, alias in ipairs(subject.targetaliases) do
			if alias == name then
				return true
			end
		end
	end
	return false
end

local function TP_CopySubject(spec, step)
	if not spec then return nil end
	return {
		kind = spec.kind,
		type = spec.type,
		target = spec.target,
		creatureid = spec.creatureid,
		targetaliases = spec.targetaliases,
		icon = spec.icon,
		fallbackicon = spec.fallbackicon,
		label = spec.label,
		signature = spec.signature,
		goal = spec.goal,
		step = step,
	}
end

function me:TargetPreview_GetGoalSubject(goal)
	if not goal or not self.GetGoalActionSpec then return nil end
	local spec = self:GetGoalActionSpec(goal)
	if spec and (spec.kind == "talk" or spec.kind == "kill") and spec.target then
		spec.goal = goal
		spec.label = goal.GetText and goal:GetText() or spec.kind
		return spec
	end
	return nil
end

function me:TargetPreview_IsFocusedSubject(subject)
	if not subject then return false end
	local sig = subject.signature
	if not sig then return false end
	return self.targetPreviewSelectedSignature == sig or self.targetPreviewHoveredSignature == sig
end

function me:TargetPreview_IsSelectedSubject(subject)
	if not subject then return false end
	local sig = subject.signature
	if not sig then return false end
	return self.targetPreviewSelectedSignature == sig
end

function me:TargetPreview_SetGoalFocus(goal, sticky)
	if not self.db or not self.db.profile or not goal then return end
	if goal and goal.parentStep and goal.parentStep ~= self.CurrentStep then
		return
	end
	local spec = self:TargetPreview_GetGoalSubject(goal)
	if not spec then return end
	if sticky then
		self.targetPreviewSelectedSignature = spec.signature
		self.targetPreviewSelectedStep = self.CurrentStep
		self.targetPreviewSelectedSubject = TP_CopySubject(spec, self.CurrentStep)
		self.targetPreviewHoveredSignature = spec.signature
		self.targetPreviewHoveredStep = self.CurrentStep
		self.targetPreviewHoveredSubject = TP_CopySubject(spec, self.CurrentStep)
	else
		self.targetPreviewHoveredSignature = spec.signature
		self.targetPreviewHoveredStep = self.CurrentStep
		self.targetPreviewHoveredSubject = TP_CopySubject(spec, self.CurrentStep)
	end
	if self.TargetPreview_Refresh then
		self:TargetPreview_Refresh()
	end
end

function me:TargetPreview_SelectHoveredSubject()
	if not self.targetPreviewHoveredSubject or self.targetPreviewHoveredStep ~= self.CurrentStep then return false end
	self.targetPreviewSelectedSignature = self.targetPreviewHoveredSignature
	self.targetPreviewSelectedStep = self.targetPreviewHoveredStep
	self.targetPreviewSelectedSubject = TP_CopySubject(self.targetPreviewHoveredSubject, self.targetPreviewHoveredStep)
	if self.TargetPreview_Refresh then
		self:TargetPreview_Refresh()
	end
	return true
end

function me:TargetPreview_SelectActionSpec(spec)
	if not spec or (spec.kind ~= "talk" and spec.kind ~= "kill") then return false end
	self.targetPreviewSelectedSignature = spec.signature
	self.targetPreviewSelectedStep = self.CurrentStep
	self.targetPreviewSelectedSubject = TP_CopySubject(spec, self.CurrentStep)
	if self.TargetPreview_Refresh then
		self:TargetPreview_Refresh()
	end
	return true
end

function me:TargetPreview_GetCurrentSubject()
	if self.targetPreviewSelectedStep and self.targetPreviewSelectedStep ~= self.CurrentStep then
		self.targetPreviewSelectedSignature = nil
		self.targetPreviewSelectedStep = nil
		self.targetPreviewSelectedSubject = nil
	end
	if self.targetPreviewHoveredStep and self.targetPreviewHoveredStep ~= self.CurrentStep then
		self.targetPreviewHoveredSignature = nil
		self.targetPreviewHoveredStep = nil
		self.targetPreviewHoveredSubject = nil
	end

	if self.targetPreviewHoveredSubject and self.targetPreviewHoveredStep == self.CurrentStep then
		return self.targetPreviewHoveredSubject
	end
	if self.targetPreviewSelectedSubject and self.targetPreviewSelectedStep == self.CurrentStep then
		return self.targetPreviewSelectedSubject
	end

	local specs = self.GetCurrentStepActionSpecs and self:GetCurrentStepActionSpecs() or {}
	if self.targetPreviewHoveredSignature then
		for _, spec in ipairs(specs) do
			if spec and spec.signature == self.targetPreviewHoveredSignature then
				return spec
			end
		end
	end
	if self.targetPreviewSelectedSignature then
		for _, spec in ipairs(specs) do
			if spec and spec.signature == self.targetPreviewSelectedSignature then
				return spec
			end
		end
	end
	for _, spec in ipairs(specs) do
		if spec and (spec.kind == "talk" or spec.kind == "kill") and spec.target then
			return spec
		end
	end
	if not self.CurrentStep or not self.CurrentStep.goals or not self.GetGoalActionSpec then return end
	if self.targetPreviewHoveredSignature then
		for _, goal in ipairs(self.CurrentStep.goals) do
			local spec = self:TargetPreview_GetGoalSubject(goal)
			if spec and spec.signature == self.targetPreviewHoveredSignature then
				return spec
			end
		end
	end
	if self.targetPreviewSelectedSignature then
		for _, goal in ipairs(self.CurrentStep.goals) do
			local spec = self:TargetPreview_GetGoalSubject(goal)
			if spec and spec.signature == self.targetPreviewSelectedSignature then
				return spec
			end
		end
	end
	for _, goal in ipairs(self.CurrentStep.goals) do
		local spec = self:TargetPreview_GetGoalSubject(goal)
		if spec then return spec end
	end
end

function me:TargetPreview_GetSnapFrame()
	if self.RemasterFrames and self.RemasterFrames.root then
		return self.RemasterFrames.root
	end
	return self.Frame or ZygorGuidesViewerFrame
end

function me:TargetPreview_GetSnapSide()
	return (self.db and self.db.profile and self.db.profile.targetpreview_pinside) or "right"
end

function me:TargetPreview_AnchorToViewer(frame, viewer)
	if not frame then return end
	viewer = viewer or self:TargetPreview_GetSnapFrame()
	if not viewer then
		frame.snapped = false
		frame:SetPoint("CENTER", UIParent, "CENTER", 180, -60)
		return
	end
	frame.snapped = true
	local side = self:TargetPreview_GetSnapSide()
	if side == "bottom" then
		frame:SetPoint("TOPLEFT", viewer, "BOTTOMLEFT", 0, -10)
	elseif side == "left" then
		frame:SetPoint("TOPRIGHT", viewer, "TOPLEFT", -10, 0)
	elseif side == "top" then
		frame:SetPoint("BOTTOMLEFT", viewer, "TOPLEFT", 0, 10)
	else
		frame:SetPoint("TOPLEFT", viewer, "TOPRIGHT", 10, 0)
	end
end

function me:TargetPreview_IsNearSnap(frame, viewer)
	if not frame or not viewer then return false end
	local ssc = frame:GetEffectiveScale()
	local zsc = viewer:GetEffectiveScale()
	local left = (frame:GetLeft() or 0) * ssc
	local right = (frame:GetRight() or 0) * ssc
	local top = (frame:GetTop() or 0) * ssc
	local bottom = (frame:GetBottom() or 0) * ssc
	local viewerLeft = (viewer:GetLeft() or 0) * zsc
	local viewerRight = (viewer:GetRight() or 0) * zsc
	local viewerTop = (viewer:GetTop() or 0) * zsc
	local viewerBottom = (viewer:GetBottom() or 0) * zsc
	local centerX = (left + right) / 2
	local centerY = (top + bottom) / 2
	local viewerCenterX = (viewerLeft + viewerRight) / 2
	local viewerCenterY = (viewerTop + viewerBottom) / 2
	local withinViewerWidth = centerX >= (viewerLeft - PREVIEW_SNAP_THRESHOLD_X) and centerX <= (viewerRight + PREVIEW_SNAP_THRESHOLD_X)
	local withinViewerHeight = centerY >= (viewerBottom - PREVIEW_SNAP_THRESHOLD_Y) and centerY <= (viewerTop + PREVIEW_SNAP_THRESHOLD_Y)
	local side = self:TargetPreview_GetSnapSide()
	if side == "bottom" then
		return withinViewerWidth and centerY <= viewerCenterY and math.abs(top - (viewerBottom - 10 * zsc)) <= PREVIEW_SNAP_THRESHOLD_Y
	elseif side == "left" then
		return withinViewerHeight and centerX <= viewerCenterX and math.abs(right - (viewerLeft - 10 * zsc)) <= PREVIEW_SNAP_THRESHOLD_X
	elseif side == "top" then
		return withinViewerWidth and centerY >= viewerCenterY and math.abs(bottom - (viewerTop + 10 * zsc)) <= PREVIEW_SNAP_THRESHOLD_Y
	end
	return withinViewerHeight and centerX >= viewerCenterX and math.abs(left - (viewerRight + 10 * zsc)) <= PREVIEW_SNAP_THRESHOLD_X
end

function me:TargetPreview_IsOverViewer(frame, viewer)
	if not frame or not viewer then return false end
	local ssc = frame:GetEffectiveScale()
	local zsc = viewer:GetEffectiveScale()
	local left = (frame:GetLeft() or 0) * ssc
	local right = (frame:GetRight() or 0) * ssc
	local top = (frame:GetTop() or 0) * ssc
	local bottom = (frame:GetBottom() or 0) * ssc
	local viewerLeft = (viewer:GetLeft() or 0) * zsc
	local viewerRight = (viewer:GetRight() or 0) * zsc
	local viewerTop = (viewer:GetTop() or 0) * zsc
	local viewerBottom = (viewer:GetBottom() or 0) * zsc
	return right >= viewerLeft and left <= viewerRight and top >= viewerBottom and bottom <= viewerTop
end

function me:TargetPreview_SaveAnchor()
	local frame = self.TargetPreviewPane
	if not frame or not self.db or not self.db.profile then return end
	if frame.snapped then
		self.db.profile.targetpreview_anchor = { snapped = true, custom = true }
		return
	end
	local point, _, relPoint, x, y = frame:GetPoint(1)
	self.db.profile.targetpreview_anchor = { point = point, relPoint = relPoint, x = x, y = y, custom = true, snapped = false }
end

function me:TargetPreview_SnapNow(frame, viewer)
	if not frame or not viewer then return false end
	frame.snapped = self:TargetPreview_IsOverViewer(frame, viewer) or self:TargetPreview_IsNearSnap(frame, viewer)
	if frame.snapped then
		frame:ClearAllPoints()
		self:TargetPreview_AnchorToViewer(frame, viewer)
	end
	self:TargetPreview_SaveAnchor()
	return frame.snapped
end

function me:TargetPreview_PrepareForDrag(frame)
	if not frame then return end
	local ssc = frame:GetEffectiveScale()
	local left = (frame:GetLeft() or 0) * ssc
	local bottom = (frame:GetBottom() or 0) * ssc
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left / ssc, bottom / ssc)
end

function me:TargetPreview_BeginDrag(frame)
	if not frame then return end
	local ssc = frame:GetEffectiveScale()
	local left = (frame:GetLeft() or 0) * ssc
	local bottom = (frame:GetBottom() or 0) * ssc
	local cx, cy = GetCursorPosition()
	frame.dragCursorOffsetX = cx - left
	frame.dragCursorOffsetY = cy - bottom
	frame.draggingManual = true
end

function me:TargetPreview_UpdateManualDrag(frame)
	if not frame or not frame.draggingManual then return end
	local ssc = frame:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	local left = cx - (frame.dragCursorOffsetX or 0)
	local bottom = cy - (frame.dragCursorOffsetY or 0)
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left / ssc, bottom / ssc)
end

function me:TargetPreview_EndDrag(frame)
	if not frame then return end
	frame.draggingManual = nil
	frame.dragCursorOffsetX = nil
	frame.dragCursorOffsetY = nil
end

function me:TargetPreview_ApplyAnchor()
	local frame = self.TargetPreviewPane
	if not frame or not self.db or not self.db.profile then return end
	local anchor = self.db.profile.targetpreview_anchor
	frame:ClearAllPoints()
	if anchor and anchor.custom then
		frame.snapped = not not anchor.snapped
		if frame.snapped then
			self:TargetPreview_AnchorToViewer(frame)
		else
			frame:SetPoint(anchor.point or "CENTER", UIParent, anchor.relPoint or "CENTER", anchor.x or 0, anchor.y or 0)
		end
		return
	end
	self:TargetPreview_AnchorToViewer(frame)
end

function me:TargetPreview_UpdateDragState()
	local frame = self.TargetPreviewPane
	if not frame then return end
	local locked = self.db.profile.targetpreview_locked
	frame:EnableMouse(not locked)
	frame:SetMovable(not locked)
	if frame.close then
		if locked then frame.close:Hide() else frame.close:Show() end
	end
end

function me:TargetPreview_Layout()
	local frame = self.TargetPreviewPane
	if not frame then return end
	local profile = self.db.profile
	local width = profile.targetpreview_width or PREVIEW_WIDTH
	local height = profile.targetpreview_height or PREVIEW_HEIGHT
	frame:SetScale(profile.targetpreview_scale or 1)
	frame:SetWidth(width)
	frame:SetHeight(height)

	frame.title:ClearAllPoints()
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PREVIEW_PADDING, -PREVIEW_PADDING + 1)
	frame.close:ClearAllPoints()
	frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

	frame.info:ClearAllPoints()
	frame.info:SetPoint("TOPLEFT", frame, "TOPLEFT", PREVIEW_PADDING, -28)
	frame.info:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PREVIEW_PADDING, -28)
	frame.info:SetHeight(54)

	frame.roleText:ClearAllPoints()
	frame.roleText:SetPoint("TOPLEFT", frame.info, "TOPLEFT", 8, -6)
	frame.roleText:SetPoint("TOPRIGHT", frame.info, "TOPRIGHT", -6, 0)

	frame.nameText:ClearAllPoints()
	frame.nameText:SetPoint("TOPLEFT", frame.roleText, "BOTTOMLEFT", 0, -1)
	frame.nameText:SetPoint("TOPRIGHT", frame.info, "TOPRIGHT", -6, 0)

	frame.metaText:ClearAllPoints()
	frame.metaText:SetPoint("TOPLEFT", frame.nameText, "BOTTOMLEFT", 0, -2)
	frame.metaText:SetPoint("TOPRIGHT", frame.info, "TOPRIGHT", -6, 0)

	frame.viewport:ClearAllPoints()
	frame.viewport:SetPoint("TOPLEFT", frame.info, "BOTTOMLEFT", 0, -8)
	frame.viewport:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PREVIEW_PADDING, PREVIEW_PADDING)

	frame.model:ClearAllPoints()
	frame.model:SetPoint("TOPLEFT", frame.viewport, "TOPLEFT", 6, -6)
	frame.model:SetPoint("BOTTOMRIGHT", frame.viewport, "BOTTOMRIGHT", -6, 6)

	frame.placeholderIcon:ClearAllPoints()
	frame.placeholderIcon:SetPoint("CENTER", frame.viewport, "CENTER", 0, 12)
	frame.placeholderIcon:SetWidth(52)
	frame.placeholderIcon:SetHeight(52)

	frame.hintText:ClearAllPoints()
	frame.hintText:SetPoint("TOPLEFT", frame.placeholderIcon, "BOTTOMLEFT", -40, -10)
	frame.hintText:SetPoint("TOPRIGHT", frame.placeholderIcon, "BOTTOMRIGHT", 40, -10)
end

function me:TargetPreview_ApplyTheme()
	local frame = self.TargetPreviewPane
	if not frame or not self.db or not self.db.profile then return end
	local textc = self.db.profile.skincolors and self.db.profile.skincolors.text or {0.90, 0.92, 0.98}
	local backc = self.db.profile.skincolors and self.db.profile.skincolors.back or {0.08, 0.09, 0.12}
	local backalpha = self.db.profile.backopacity or 0.3
	local opacitymain = self.db.profile.opacitymain or 1.0
	local remastercolor = self.db.profile.remastercolor or "dark"
	local isGoldAccent = (remastercolor == "goldaccent" or remastercolor == "goals")
	local border = { 0.18, 0.18, 0.20, 0.92 }
	local insetBg = { 0.10, 0.10, 0.11, 0.95 }
	local insetBorder = { 0.20, 0.20, 0.22, 0.90 }
	local rolec = { 1.0, 0.86, 0.45, 1 }
	if isGoldAccent then
		backc = { 0.04, 0.04, 0.05 }
		border = { 0.17, 0.15, 0.10, 0.88 }
		insetBg = { 0.05, 0.05, 0.06, 0.97 }
		insetBorder = { 0.22, 0.18, 0.10, 0.90 }
		rolec = { 0.92, 0.80, 0.50, 1.00 }
	end
	frame:SetAlpha(opacitymain)
	frame:SetBackdropColor(backc[1], backc[2], backc[3], backalpha)
	frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
	frame.info:SetBackdropColor(insetBg[1], insetBg[2], insetBg[3], math.min(1, (insetBg[4] or 0.95) * (backalpha / 0.3)))
	frame.info:SetBackdropBorderColor(insetBorder[1], insetBorder[2], insetBorder[3], insetBorder[4] or 1)
	frame.viewport:SetBackdropColor(insetBg[1], insetBg[2], insetBg[3], math.min(1, (insetBg[4] or 0.95) * (backalpha / 0.3)))
	frame.viewport:SetBackdropBorderColor(insetBorder[1], insetBorder[2], insetBorder[3], insetBorder[4] or 1)
	frame.title:SetTextColor(textc[1], textc[2], textc[3], 0.95)
	frame.roleText:SetTextColor(rolec[1], rolec[2], rolec[3], rolec[4] or 1)
	frame.metaText:SetTextColor(0.73, 0.77, 0.84, 1)
	frame.hintText:SetTextColor(0.65, 0.68, 0.74, 1)
end

function me:TargetPreview_GetUnitData(subject)
	if not subject or not subject.target then return end
	if not UnitExists("target") then return end
	local name = UnitName("target")
	if not name or not TP_SubjectMatchesTarget(subject) then return end
	local parts = {}
	local level = TP_GetLevelText("target")
	if level then parts[#parts + 1] = level end
	local creatureType = UnitCreatureType("target")
	if creatureType then parts[#parts + 1] = creatureType end
	local classText = TP_GetClassificationText("target")
	if classText then parts[#parts + 1] = classText end
	return {
		name = name,
		meta = table.concat(parts, "  |  "),
	}
end

function me:TargetPreview_ShowModel(subject)
	local frame = self.TargetPreviewPane
	if not frame or not subject then return false end
	local modelKey
	local useTarget = TP_SubjectMatchesTarget(subject)
	if useTarget then
		modelKey = "target:" .. tostring(UnitGUID("target") or "")
	else
		return false
	end
	if frame.modelSubjectKey and frame.modelSubjectKey == modelKey and frame.model:IsShown() then
		return true
	end
	local ok = pcall(function()
		if frame.model.ClearModel then frame.model:ClearModel() end
		frame.model:SetUnit("target")
		if frame.model.SetPortraitZoom then frame.model:SetPortraitZoom(0) end
		if frame.model.SetCamDistanceScale then
			frame.model:SetCamDistanceScale(PREVIEW_TARGET_CAM_DISTANCE)
		end
		if frame.model.SetCamera then frame.model:SetCamera(0) end
		if frame.model.SetFacing then
			if frame.modelSubjectKey ~= modelKey then
				frame.modelFacing = 0
			end
			frame.model:SetFacing(frame.modelFacing or 0)
		end
		frame.model:Show()
	end)
	if ok then
		frame.modelSubjectKey = modelKey
	else
		frame.modelSubjectKey = nil
	end
	return ok
end

function me:TargetPreview_ApplySubject(subject)
	local frame = self.TargetPreviewPane
	if not frame then return false end
	frame.previewSubject = subject

	local mode = self.db.profile.targetpreview_mode or "hybrid"
	local hasSubject = subject and subject.target
	local isSelectedSubject = hasSubject and self:TargetPreview_IsSelectedSubject(subject)
	local roleText = subject and ((subject.kind == "kill" and L["targetpreview_role_kill"]) or L["targetpreview_role_talk"]) or ""
	local liveData = isSelectedSubject and self:TargetPreview_GetUnitData(subject) or nil
	local allowLiveModel = isSelectedSubject
	local canShowModel = allowLiveModel and mode ~= "card" and self:TargetPreview_ShowModel(subject)
	local hasLiveTarget = liveData and true or false
	local allowFallbackCard = subject and self:TargetPreview_IsFocusedSubject(subject)

	if mode == "model" and not canShowModel then
		frame.modelSubjectKey = nil
		return false
	end
	if mode ~= "card" and not hasLiveTarget and not allowFallbackCard then
		if frame.model.ClearModel then frame.model:ClearModel() end
		frame.model:Hide()
		frame.modelSubjectKey = nil
		return false
	end

	frame.title:SetText(L["targetpreview_title_locked"])
	frame.roleText:SetText(roleText)
	frame.nameText:SetText((liveData and liveData.name) or (subject and subject.target) or L["targetpreview_empty_name"])
	frame.metaText:SetText((liveData and liveData.meta) or (subject and subject.label) or "")
	if liveData and TP_SubjectMatchesTarget(subject) then
		frame.nameText:SetTextColor(TP_GetReactionColor("target"))
	else
		local textc = self.db.profile.skincolors and self.db.profile.skincolors.text or {0.90, 0.92, 0.98}
		frame.nameText:SetTextColor(textc[1], textc[2], textc[3], 1)
	end
	TP_ApplyIcon(frame.placeholderIcon, subject and (subject.icon or subject.fallbackicon) or PREVIEW_DEFAULT_ICON)

	if canShowModel and mode ~= "card" then
		frame.model:Show()
		frame.placeholderIcon:Hide()
		frame.hintText:SetText("")
	else
		if frame.model.ClearModel then frame.model:ClearModel() end
		frame.model:Hide()
		frame.modelSubjectKey = nil
		frame.placeholderIcon:Show()
		if hasSubject then
			frame.hintText:SetText(L["targetpreview_hint"])
		else
			frame.hintText:SetText(L["targetpreview_hint_empty"])
		end
	end

	return hasSubject
end

function me:TargetPreview_CreatePane()
	if self.TargetPreviewPane then return self.TargetPreviewPane end

	local frame = CreateFrame("Frame", "ZygorGuidesViewerTargetPreview", UIParent)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("LOW")
	frame:SetFrameLevel(10)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetScript("OnDragStart", function(selfFrame)
		if not me.db.profile.targetpreview_locked then
			selfFrame.snapped = false
			selfFrame:SetClampedToScreen(false)
			me:TargetPreview_PrepareForDrag(selfFrame)
			me:TargetPreview_BeginDrag(selfFrame)
		end
	end)
	frame:SetScript("OnDragStop", function(selfFrame)
		me:TargetPreview_EndDrag(selfFrame)
		selfFrame:SetClampedToScreen(true)
		me:TargetPreview_SnapNow(selfFrame, me:TargetPreview_GetSnapFrame())
	end)
	frame:SetScript("OnUpdate", function(selfFrame)
		if me.db.profile.targetpreview_locked then return end
		if selfFrame.modelRotating and selfFrame.model and selfFrame.model.SetFacing then
			local cx = GetCursorPosition()
			local last = selfFrame.modelRotateCursorX or cx
			local delta = cx - last
			selfFrame.modelRotateCursorX = cx
			selfFrame.modelFacing = (selfFrame.modelFacing or 0) + (delta * PREVIEW_ROTATION_SPEED)
			selfFrame.model:SetFacing(selfFrame.modelFacing)
		end
		if selfFrame.draggingManual then
			me:TargetPreview_UpdateManualDrag(selfFrame)
			return
		end
		if me.framemoving and selfFrame.snapped then
			me:TargetPreview_ApplyAnchor()
		end
	end)
	frame:RegisterForDrag("LeftButton")

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetJustifyH("LEFT")

	frame.close = CreateFrame("Button", nil, frame)
	frame.close:SetWidth(PREVIEW_CLOSE_SIZE)
	frame.close:SetHeight(PREVIEW_CLOSE_SIZE)
	frame.close:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	frame.close:SetPushedTexture("Interface\\Buttons\\WHITE8x8")
	frame.close:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	frame.close:GetNormalTexture():SetVertexColor(0.08, 0.08, 0.08, 1)
	frame.close:GetPushedTexture():SetVertexColor(0.14, 0.14, 0.14, 1)
	frame.close.x = frame.close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.close.x:SetPoint("CENTER", 0, 0)
	frame.close.x:SetText("x")
	frame.close.x:SetTextColor(1, 1, 1, 0.95)
	frame.close:SetScript("OnClick", function()
		me.db.profile.targetpreview_enabled = false
		LibStub("AceConfigRegistry-3.0"):NotifyChange("ZygorGuidesViewer")
		me:TargetPreview_Refresh(true)
	end)

	frame.info = CreateFrame("Frame", nil, frame)
	frame.info:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame.roleText = frame.info:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.roleText:SetJustifyH("LEFT")
	frame.nameText = frame.info:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.nameText:SetJustifyH("LEFT")
	frame.nameText:SetWordWrap(true)
	frame.metaText = frame.info:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.metaText:SetJustifyH("LEFT")
	frame.metaText:SetWordWrap(true)

	frame.viewport = CreateFrame("Frame", nil, frame)
	frame.viewport:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame.viewport:EnableMouse(true)
	frame.viewport:SetScript("OnMouseUp", function(selfViewport, button)
		if button ~= "LeftButton" then return end
		local owner = selfViewport:GetParent()
		if not owner or not owner.previewSubject then return end
		if owner.model and owner.model:IsShown() then return end
		if me.TargetPreview_SelectActionSpec then
			me:TargetPreview_SelectActionSpec(owner.previewSubject)
		end
	end)
	frame.model = CreateFrame("PlayerModel", nil, frame.viewport)
	frame.model:SetFrameLevel(frame.viewport:GetFrameLevel() + 1)
	frame.model:EnableMouse(true)
	frame.model:RegisterForDrag("RightButton")
	frame.model:SetScript("OnMouseDown", function(selfModel, button)
		if button ~= "RightButton" then return end
		local owner = selfModel:GetParent() and selfModel:GetParent():GetParent()
		if not owner then return end
		owner.modelRotating = true
		owner.modelRotateCursorX = GetCursorPosition()
	end)
	frame.model:SetScript("OnMouseUp", function(selfModel, button)
		if button ~= "RightButton" then return end
		local owner = selfModel:GetParent() and selfModel:GetParent():GetParent()
		if not owner then return end
		owner.modelRotating = nil
		owner.modelRotateCursorX = nil
	end)
	frame.model:SetScript("OnDragStop", function(selfModel)
		local owner = selfModel:GetParent() and selfModel:GetParent():GetParent()
		if not owner then return end
		owner.modelRotating = nil
		owner.modelRotateCursorX = nil
	end)
	frame.model:SetScript("OnHide", function(selfModel)
		local owner = selfModel:GetParent() and selfModel:GetParent():GetParent()
		if not owner then return end
		owner.modelRotating = nil
		owner.modelRotateCursorX = nil
	end)
	frame.placeholderIcon = frame.viewport:CreateTexture(nil, "ARTWORK")
	frame.hintText = frame.viewport:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.hintText:SetJustifyH("CENTER")
	frame.hintText:SetJustifyV("TOP")
	frame.hintText:SetWordWrap(true)
	frame.hintText:SetNonSpaceWrap(true)

	self.TargetPreviewPane = frame
	self:TargetPreview_ApplyTheme()
	self:TargetPreview_Layout()
	self:TargetPreview_ApplyAnchor()
	self:TargetPreview_UpdateDragState()
	return frame
end

function me:TargetPreview_ResetAnchor()
	if not self.db or not self.db.profile then return end
	self.db.profile.targetpreview_anchor = { snapped = true, custom = true }
end

function me:TargetPreview_ValidateProfile()
	if not self.db or not self.db.profile then return end
	local profile = self.db.profile
	local validSides = { top = true, bottom = true, left = true, right = true }
	local validModes = { hybrid = true, model = true, card = true }
	local validPoints = {
		TOPLEFT = true, TOP = true, TOPRIGHT = true,
		LEFT = true, CENTER = true, RIGHT = true,
		BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
	}

	if not validSides[profile.targetpreview_pinside] then
		profile.targetpreview_pinside = "right"
	end
	if not validModes[profile.targetpreview_mode] then
		profile.targetpreview_mode = "hybrid"
	end

	profile.targetpreview_scale = tonumber(profile.targetpreview_scale) or 1
	if profile.targetpreview_scale < 0.5 then profile.targetpreview_scale = 0.5 end
	if profile.targetpreview_scale > 2 then profile.targetpreview_scale = 2 end

	profile.targetpreview_width = tonumber(profile.targetpreview_width) or PREVIEW_WIDTH
	if profile.targetpreview_width < 150 then profile.targetpreview_width = 150 end
	if profile.targetpreview_width > 340 then profile.targetpreview_width = 340 end

	profile.targetpreview_height = tonumber(profile.targetpreview_height) or PREVIEW_HEIGHT
	if profile.targetpreview_height < 170 then profile.targetpreview_height = 170 end
	if profile.targetpreview_height > 460 then profile.targetpreview_height = 460 end

	local anchor = profile.targetpreview_anchor
	if type(anchor) ~= "table" then
		self:TargetPreview_ResetAnchor()
		return
	end
	if anchor.snapped == nil then anchor.snapped = true end
	if anchor.custom == nil then anchor.custom = true end
	if anchor.snapped then
		profile.targetpreview_anchor = { snapped = true, custom = true }
		return
	end
	if not validPoints[anchor.point] or not validPoints[anchor.relPoint] then
		self:TargetPreview_ResetAnchor()
		return
	end
	anchor.x = tonumber(anchor.x)
	anchor.y = tonumber(anchor.y)
	if not anchor.x or not anchor.y then
		self:TargetPreview_ResetAnchor()
	end
end

function me:TargetPreview_ApplyProfile()
	if not self.db or not self.db.profile then return end
	self:TargetPreview_ValidateProfile()
	self:TargetPreview_CreatePane()
	self:TargetPreview_ApplyTheme()
	self:TargetPreview_Layout()
	self:TargetPreview_ApplyAnchor()
	self:TargetPreview_UpdateDragState()
	self:TargetPreview_Refresh(true)
end

function me:TargetPreview_Refresh(force)
	if not self.db or not self.db.profile or not self.db.profile.targetpreview_enabled then
		if self.TargetPreviewPane then self.TargetPreviewPane:Hide() end
		return
	end
	if not self.Frame or not self.Frame:IsShown() then
		if self.TargetPreviewPane then self.TargetPreviewPane:Hide() end
		return
	end

	local frame = self:TargetPreview_CreatePane()
	local subject = self:TargetPreview_GetCurrentSubject()
	local mode = self.db.profile.targetpreview_mode or "hybrid"
	self:TargetPreview_ApplyTheme()
	local applied = self:TargetPreview_ApplySubject(subject)
	local shouldShow = applied or not self.db.profile.targetpreview_onlywhenneeded

	if mode == "model" and not applied then
		shouldShow = false
	end

	self:TargetPreview_ApplyAnchor()
	self:TargetPreview_Layout()
	self:TargetPreview_UpdateDragState()

	if shouldShow then frame:Show() else frame:Hide() end
end

function me:TargetPreview_TargetChanged()
	if not UnitExists("target") then
		self.targetPreviewSelectedSignature = nil
		self.targetPreviewSelectedStep = nil
		self.targetPreviewSelectedSubject = nil
	end
	if self.TargetPreview_Refresh then
		self:TargetPreview_Refresh()
	end
end

function me:TargetPreview_HandleActionButtonPostClick(button)
	local spec = button and button.actionSpec
	if not spec or (spec.kind ~= "talk" and spec.kind ~= "kill") then return end
	self:TargetPreview_SelectActionSpec(spec)
	self:TargetPreview_Refresh()
	if self.ScheduleTimer then
		self:ScheduleTimer(function()
			if ZGV and ZGV.TargetPreview_Refresh then ZGV:TargetPreview_Refresh() end
		end, 0.08)
		self:ScheduleTimer(function()
			if ZGV and ZGV.TargetPreview_Refresh then ZGV:TargetPreview_Refresh() end
		end, 0.20)
	end
end

tinsert(me.startups, function(self)
	self:AddEvent("PLAYER_TARGET_CHANGED", "TargetPreview_TargetChanged")
end)

hooksecurefunc(me, "UpdateFrameCurrent", function(self)
	if self.targetPreviewHoveredStep and self.targetPreviewHoveredStep ~= self.CurrentStep then
		self.targetPreviewHoveredSignature = nil
		self.targetPreviewHoveredStep = nil
		self.targetPreviewHoveredSubject = nil
	end
	if self.targetPreviewSelectedStep and self.targetPreviewSelectedStep ~= self.CurrentStep then
		self.targetPreviewSelectedSignature = nil
		self.targetPreviewSelectedStep = nil
		self.targetPreviewSelectedSubject = nil
	end
	if self.TargetPreview_Refresh then self:TargetPreview_Refresh() end
end)

hooksecurefunc(me, "ActionButtons_HandlePostClick", function(self, button)
	if self.TargetPreview_HandleActionButtonPostClick then
		self:TargetPreview_HandleActionButtonPostClick(button)
	end
end)

hooksecurefunc(me, "GoalOnEnter", function(self, goalframe)
	local goal = goalframe and goalframe:GetParent() and goalframe:GetParent().goal
	local spec = goal and self.TargetPreview_GetGoalSubject and self:TargetPreview_GetGoalSubject(goal)
	if spec then
		self:TargetPreview_SetGoalFocus(goal, false)
	end
end)

hooksecurefunc(me, "GoalOnLeave", function(self, goalframe)
	local goal = goalframe and goalframe:GetParent() and goalframe:GetParent().goal
	local spec = goal and self.TargetPreview_GetGoalSubject and self:TargetPreview_GetGoalSubject(goal)
	if spec and self.targetPreviewHoveredSignature == spec.signature then
		self.targetPreviewHoveredSignature = nil
		self.targetPreviewHoveredStep = nil
		self.targetPreviewHoveredSubject = nil
		if self.TargetPreview_Refresh then self:TargetPreview_Refresh() end
	end
end)

hooksecurefunc(me, "GoalOnClick", function(self, goalframe)
	local goal = goalframe and goalframe:GetParent() and goalframe:GetParent().goal
	local spec = goal and self.TargetPreview_GetGoalSubject and self:TargetPreview_GetGoalSubject(goal)
	if spec then
		self:TargetPreview_SetGoalFocus(goal, true)
	end
end)

hooksecurefunc(me, "UpdateSkin", function(self)
	if self.ActionButtons_ApplyTheme then self:ActionButtons_ApplyTheme() end
	if self.TargetPreview_ApplyProfile then self:TargetPreview_ApplyProfile() end
end)

hooksecurefunc(me, "Frame_OnHide", function(self)
	if self.TargetPreviewPane then self.TargetPreviewPane:Hide() end
end)

hooksecurefunc(me, "OnDisable", function(self)
	if self.TargetPreviewPane then self.TargetPreviewPane:Hide() end
end)
