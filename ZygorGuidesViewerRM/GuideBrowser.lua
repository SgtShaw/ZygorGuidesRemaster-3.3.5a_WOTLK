local me = ZygorGuidesViewer
if not me then return end

local L = me.L
local tinsert = tinsert
local tremove = tremove
local pairs = pairs
local ipairs = ipairs
local type = type
local strlower = string.lower
local strfind = string.find
local strmatch = string.match
local wipe = wipe

local GetNodeByPath

local function LT(key, ...)
	local text = (L and L[key]) or key
	if select("#", ...) > 0 then
		return text:format(...)
	end
	return text
end

local function SplitGuideTitle(title)
	local parts = {}
	local s = (title or "") .. "\\"
	s:gsub("(.-)\\", function(c)
		if c ~= "" then tinsert(parts, c) end
	end)
	if #parts == 0 then tinsert(parts, title or "") end
	return parts
end

local function PathToString(path)
	if not path or #path == 0 then return "" end
	return table.concat(path, "\\")
end

local function StringToPath(s)
	local path = {}
	for part in string.gmatch(s or "", "[^\\]+") do
		if part ~= "" then tinsert(path, part) end
	end
	return path
end

local function PathIsRoot(path)
	return not path or #path == 0
end

local function NewNode(name)
	return { name = name, children = {}, child_order = {}, guides = {} }
end

function me:BuildGuideBrowserTree()
	if not self.registeredguides then return NewNode("root") end

	local count = #self.registeredguides
	if self._guideBrowserTree and self._guideBrowserTreeCount == count then
		return self._guideBrowserTree
	end

	local root = NewNode("root")
	for _,guide in ipairs(self.registeredguides) do
		local title = guide and guide.title
		if title and title ~= "" then
			local parts = SplitGuideTitle(title)
			local leaf = parts[#parts]
			local node = root
			for i = 1, #parts - 1 do
				local seg = parts[i]
				if not node.children[seg] then
					node.children[seg] = NewNode(seg)
					tinsert(node.child_order, seg)
				end
				node = node.children[seg]
			end
			tinsert(node.guides, { title = title, leaf = leaf })
		end
	end

	self._guideBrowserTree = root
	self._guideBrowserTreeCount = count
	return root
end

function me:GetGuideBrowserPath()
	return (self.db and self.db.profile and self.db.profile.guidebrowserpath) or ""
end

function me:SetGuideBrowserPath(pathString)
	if not (self.db and self.db.profile) then return end
	self.db.profile.guidebrowserpath = pathString or ""
end

function me:GetGuideBrowserPathDisplay()
	local p = StringToPath(self:GetGuideBrowserPath())
	if PathIsRoot(p) then return LT("gb_root") end
	return table.concat(p, " > ")
end

function me:GuideBrowserUp()
	local p = StringToPath(self:GetGuideBrowserPath())
	if #p > 0 then
		tremove(p)
		self:SetGuideBrowserPath(PathToString(p))
	end
end

function me:GetGuideBrowserFolderValues()
	local out = {}
	local root = self:BuildGuideBrowserTree()
	local node = GetNodeByPath(root, StringToPath(self:GetGuideBrowserPath())) or root
	for _,name in ipairs(node.child_order or {}) do out[name] = name end
	return out
end

function me:GuideBrowserEnterFolder(name)
	if not name or name=="" then return end
	local p = StringToPath(self:GetGuideBrowserPath())
	tinsert(p, name)
	self:SetGuideBrowserPath(PathToString(p))
	if self.db and self.db.profile then
		self.db.profile.guidebrowserselectedguide = nil
	end
end

function me:GetGuideBrowserGuideValues()
	local out = {}
	local root = self:BuildGuideBrowserTree()
	local node = GetNodeByPath(root, StringToPath(self:GetGuideBrowserPath())) or root
	local search = strlower((self.db and self.db.profile and self.db.profile.guidebrowsersearch) or "")
	local guides = {}
	for _,g in ipairs(node.guides or {}) do
		local label = g.leaf or g.title
		local hay = strlower((label or "") .. " " .. (g.title or ""))
		if search=="" or strfind(hay, search, 1, true) then
			tinsert(guides, g)
		end
	end
	for _,g in ipairs(guides) do
		out[g.title] = g.leaf or g.title
	end
	return out
end

function me:GetGuideBrowserFolders()
	local out = {}
	local root = self:BuildGuideBrowserTree()
	local node = GetNodeByPath(root, StringToPath(self:GetGuideBrowserPath())) or root
	for _,name in ipairs(node.child_order or {}) do tinsert(out, name) end
	return out
end

function me:GetGuideBrowserGuides()
	local out = {}
	local root = self:BuildGuideBrowserTree()
	local node = GetNodeByPath(root, StringToPath(self:GetGuideBrowserPath())) or root
	local search = strlower((self.db and self.db.profile and self.db.profile.guidebrowsersearch) or "")
	for _,g in ipairs(node.guides or {}) do
		local label = g.leaf or g.title
		local hay = strlower((label or "") .. " " .. (g.title or ""))
		if search=="" or strfind(hay, search, 1, true) then
			tinsert(out, { title=g.title, label=label })
		end
	end
	return out
end

GetNodeByPath = function(root, path)
	local node = root
	for _,seg in ipairs(path or {}) do
		node = node and node.children and node.children[seg]
		if not node then return nil end
	end
	return node
end

local function CollectGuidesRecursive(node, prefix, out)
	if not node then return end
	for _,g in ipairs(node.guides or {}) do
		local label = prefix ~= "" and (prefix .. "\\" .. g.leaf) or g.leaf
		tinsert(out, { title = g.title, label = label, leaf = g.leaf })
	end
	for _,name in ipairs(node.child_order or {}) do
		local child = node.children and node.children[name]
		local nextPrefix = prefix ~= "" and (prefix .. "\\" .. name) or name
		CollectGuidesRecursive(child, nextPrefix, out)
	end
end

local function EnsureGuideBrowserFrame(self)
	if self.GuideBrowserFrame then return self.GuideBrowserFrame end

	local f = CreateFrame("Frame", "ZGVGuideBrowserFrame", UIParent, "UIPanelDialogTemplate")
	f:SetWidth(760)
	f:SetHeight(520)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
	f:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
	f:Hide()

	local titleObj = _G[f:GetName() .. "Title"]
	if titleObj and titleObj.SetText then
		titleObj:SetText(LT("gb_window_title"))
	end

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

	local breadcrumb = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	breadcrumb:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -34)
	breadcrumb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -34)
	breadcrumb:SetJustifyH("LEFT")
	f.breadcrumb = breadcrumb

	local searchLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	searchLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -56)
	searchLabel:SetText(LT("gb_search"))

	local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	search:SetAutoFocus(false)
	search:SetWidth(220)
	search:SetHeight(20)
	search:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
	search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
	f.search = search

	local leftHeader = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	leftHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -84)
	leftHeader:SetText(LT("gb_folders"))

	local rightHeader = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	rightHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 300, -84)
	rightHeader:SetText(LT("gb_guides"))

	local left = CreateFrame("Frame", nil, f)
	left:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -102)
	left:SetWidth(260)
	left:SetHeight(355)
	left:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
	left:SetBackdropColor(0, 0, 0, 0.4)
	f.leftPane = left

	local right = CreateFrame("Frame", nil, f)
	right:SetPoint("TOPLEFT", f, "TOPLEFT", 300, -102)
	right:SetWidth(444)
	right:SetHeight(355)
	right:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
	right:SetBackdropColor(0, 0, 0, 0.4)
	f.rightPane = right

	local leftScroll = CreateFrame("ScrollFrame", "ZGVGuideBrowserLeftScroll", left, "FauxScrollFrameTemplate")
	leftScroll:SetPoint("TOPLEFT", left, "TOPLEFT", 4, -4)
	leftScroll:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -24, 4)
	f.leftScroll = leftScroll

	local rightScroll = CreateFrame("ScrollFrame", "ZGVGuideBrowserRightScroll", right, "FauxScrollFrameTemplate")
	rightScroll:SetPoint("TOPLEFT", right, "TOPLEFT", 4, -4)
	rightScroll:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -24, 4)
	f.rightScroll = rightScroll

	f.leftButtons = {}
	f.rightButtons = {}
	for i = 1, 16 do
		local b = CreateFrame("Button", nil, left)
		b:SetHeight(20)
		b:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -6 - ((i - 1) * 21))
		b:SetPoint("RIGHT", left, "RIGHT", -26, 0)
		b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		b.text:SetAllPoints()
		b.text:SetJustifyH("LEFT")
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		f.leftButtons[i] = b

		local g = CreateFrame("Button", nil, right)
		g:SetHeight(20)
		g:SetPoint("TOPLEFT", right, "TOPLEFT", 8, -6 - ((i - 1) * 21))
		g:SetPoint("RIGHT", right, "RIGHT", -26, 0)
		g.text = g:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		g.text:SetAllPoints()
		g.text:SetJustifyH("LEFT")
		g:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		f.rightButtons[i] = g
	end

	local load = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	load:SetWidth(130)
	load:SetHeight(22)
	load:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
	load:SetText(LT("gb_load_guide"))
	f.loadButton = load

	local legacy = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	legacy:SetWidth(180)
	legacy:SetHeight(22)
	legacy:SetPoint("RIGHT", load, "LEFT", -8, 0)
	legacy:SetText(LT("gb_open_legacy"))
	f.legacyButton = legacy

	self.GuideBrowserFrame = f
	return f
end

local function UpdateGuideBrowser(self)
	local f = self.GuideBrowserFrame
	if not f then return end

	local tree = self:BuildGuideBrowserTree()
	local path = f.path or {}
	local node = GetNodeByPath(tree, path)
	if not node then
		f.path = {}
		path = f.path
		node = tree
	end

	local breadcrumb = (#path > 0) and table.concat(path, "  >  ") or LT("gb_root")
	f.breadcrumb:SetText(LT("gb_path_format", breadcrumb))

	local folders = {}
	if #path > 0 then tinsert(folders, { label = "..", isUp = true }) end
	for _,name in ipairs(node.child_order or {}) do
		tinsert(folders, { label = name })
	end
	f.folders = folders

	local guides = {}
	local search = strlower(strmatch((f.search:GetText() or ""), "^%s*(.-)%s*$") or "")
	if search ~= "" then
		local tmp = {}
		CollectGuidesRecursive(node, "", tmp)
		for _,g in ipairs(tmp) do
			local hay = strlower(g.label .. " " .. (g.title or ""))
			if strfind(hay, search, 1, true) then
				tinsert(guides, g)
			end
		end
	else
		for _,g in ipairs(node.guides or {}) do
			tinsert(guides, { title = g.title, label = g.leaf })
		end
	end
	f.guides = guides

	local leftCount = #f.leftButtons
	FauxScrollFrame_Update(f.leftScroll, #folders, leftCount, 21)
	local leftOff = FauxScrollFrame_GetOffset(f.leftScroll)
	for i = 1, leftCount do
		local row = f.leftButtons[i]
		local data = folders[i + leftOff]
		if data then
			row.data = data
			row.text:SetText(data.isUp and ".." or data.label)
			row:Show()
		else
			row.data = nil
			row:Hide()
		end
	end

	local rightCount = #f.rightButtons
	FauxScrollFrame_Update(f.rightScroll, #guides, rightCount, 21)
	local rightOff = FauxScrollFrame_GetOffset(f.rightScroll)
	for i = 1, rightCount do
		local row = f.rightButtons[i]
		local data = guides[i + rightOff]
		if data then
			row.data = data
			if data.title == f.selectedGuide then
				row.text:SetText("|cffdfe3eb" .. data.label .. "|r")
			else
				row.text:SetText(data.label)
			end
			row:Show()
		else
			row.data = nil
			row:Hide()
		end
	end

	if f.selectedGuide then f.loadButton:Enable() else f.loadButton:Disable() end
end

function me:OpenGuideBrowser()
	local f = EnsureGuideBrowserFrame(self)
	f.path = StringToPath((self.db and self.db.profile and self.db.profile.guidebrowserpath) or "")
	f.selectedGuide = nil
	f.search:SetText((self.db and self.db.profile and self.db.profile.guidebrowsersearch) or "")

	for _,b in ipairs(f.leftButtons) do
		b:SetScript("OnClick", function(btn)
			if not btn.data then return end
			if btn.data.isUp then
				tremove(f.path)
			else
				tinsert(f.path, btn.data.label)
			end
			f.selectedGuide = nil
			UpdateGuideBrowser(self)
		end)
	end

	for _,b in ipairs(f.rightButtons) do
		b:SetScript("OnClick", function(btn)
			if not btn.data then return end
			if f.selectedGuide == btn.data.title then
				self:SetGuide(btn.data.title)
				self:FocusStep(1)
				f:Hide()
				return
			end
			f.selectedGuide = btn.data.title
			UpdateGuideBrowser(self)
		end)
	end

	f.leftScroll:SetScript("OnVerticalScroll", function(scroll, offset)
		FauxScrollFrame_OnVerticalScroll(scroll, offset, 21, function() UpdateGuideBrowser(self) end)
	end)
	f.rightScroll:SetScript("OnVerticalScroll", function(scroll, offset)
		FauxScrollFrame_OnVerticalScroll(scroll, offset, 21, function() UpdateGuideBrowser(self) end)
	end)
	f.search:SetScript("OnTextChanged", function()
		UpdateGuideBrowser(self)
	end)
	f.loadButton:SetScript("OnClick", function()
		if not f.selectedGuide then return end
		self:SetGuide(f.selectedGuide)
		self:FocusStep(1)
		f:Hide()
	end)
	f.legacyButton:SetScript("OnClick", function()
		InterfaceOptionsFrame_OpenToCategory(self.options and self.options.name or LT("gb_addon_title"))
	end)
	f:SetScript("OnHide", function()
		if self.db and self.db.profile then
			self.db.profile.guidebrowserpath = PathToString(f.path)
			self.db.profile.guidebrowsersearch = f.search:GetText() or ""
		end
	end)

	UpdateGuideBrowser(self)
	f:Show()
end

local function BuildGuideManagerRows(self, search, filterFn, browsePath, useDrilldown)
	local rows = {}
	local root = self:BuildGuideBrowserTree()
	if not root then return rows end
	local guideCache = {}

	self.db.profile.guidebrowsertreeexpanded = self.db.profile.guidebrowsertreeexpanded or {}
	local expanded = self.db.profile.guidebrowsertreeexpanded
	local needle = strlower((search or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	local inSearch = (needle ~= "")

	local function GuideMatches(g, prefix)
		local leaf = g.leaf or g.title or ""
		local title = g.title or ""
		local full = (prefix ~= "" and (prefix .. "\\" .. leaf)) or leaf
		local hay = strlower(full .. " " .. title)
		if needle ~= "" and not strfind(hay, needle, 1, true) then return false end
		local fullGuide = guideCache[title]
		if fullGuide == nil then
			fullGuide = self:GetGuideByTitle(title) or false
			guideCache[title] = fullGuide
		end
		if fullGuide == false then fullGuide = nil end
		if filterFn and not filterFn(title, full, fullGuide or g) then return false end
		return true
	end

	local function NodeHasMatches(node, prefix)
		for _,name in ipairs(node.child_order or {}) do
			local child = node.children and node.children[name]
			local nextPrefix = (prefix ~= "" and (prefix .. "\\" .. name)) or name
			if child and NodeHasMatches(child, nextPrefix) then return true end
		end
		for _,g in ipairs(node.guides or {}) do
			if GuideMatches(g, prefix) then return true end
		end
		return false
	end

	local function addNode(node, depth, basePath, noDisclosure)
		for _,name in ipairs(node.child_order or {}) do
			local child = node.children and node.children[name]
			local path = (basePath ~= "" and (basePath .. "\\" .. name)) or name
			local hasMatch = child and NodeHasMatches(child, path)
			if hasMatch then
				local open = (inSearch and true) or (expanded[path] and true or false)
				tinsert(rows, { kind = "folder", depth = depth, label = name, path = path, open = open, nodisc = noDisclosure })
				if open then addNode(child, depth + 1, path, noDisclosure) end
			end
		end
		for _,g in ipairs(node.guides or {}) do
			if GuideMatches(g, basePath) then
				tinsert(rows, { kind = "guide", depth = depth, label = g.leaf or g.title, title = g.title })
			end
		end
	end
	if useDrilldown then
		local path = StringToPath(browsePath or "")
		local node = GetNodeByPath(root, path) or root
		local basePath = PathToString(path)
		if inSearch then
			-- Search stays deep/broad like retail, but still in guide order.
			addNode(root, 0, "", true)
		else
			for _,name in ipairs(node.child_order or {}) do
				local child = node.children and node.children[name]
				local childPath = (basePath ~= "" and (basePath .. "\\" .. name)) or name
				if child and NodeHasMatches(child, childPath) then
					tinsert(rows, { kind = "folder", depth = 0, label = name, path = childPath, open = false, nodisc = true, naventer = true })
				end
			end
			for _,g in ipairs(node.guides or {}) do
				if GuideMatches(g, basePath) then
					tinsert(rows, { kind = "guide", depth = 0, label = g.leaf or g.title, title = g.title })
				end
			end
		end
	else
		addNode(root, 0, "", false)
	end
	return rows
end

local GUIDE_MANAGER_ROW_HEIGHT = 10
local GUIDE_MANAGER_FONT_SIZE = 10
local GUIDE_MANAGER_VISIBLE_ROWS = 21
local GUIDE_SMALL_ICON_FILE = ZGV.DIR.."\\Skins\\guideicons-small"

local function GetIconTexCoord(col, row, cols, rows)
	local l = (col - 1) / cols
	local r = col / cols
	local t = (row - 1) / rows
	local b = row / rows
	return l, r, t, b
end

local GUIDE_SMALL_ICON_COORDS = {
	folder = { GetIconTexCoord(1, 1, 4, 2) },
	guide = { GetIconTexCoord(2, 1, 4, 2) },
	star = { GetIconTexCoord(1, 2, 4, 2) },
}

local FEATURED_BUCKET_ORDER = { "next", "progress", "level", "featured" }
local FEATURED_BUCKET_LABELS = {
	next = LT("gb_featured_bucket_next"),
	progress = LT("gb_featured_bucket_progress"),
	level = LT("gb_featured_bucket_level"),
	featured = LT("gb_featured_bucket_featured"),
}
local FEATURED_CONFIDENCE_LABELS = {
	strong = LT("gb_featured_confidence_strong"),
	good = LT("gb_featured_confidence_good"),
	fallback = LT("gb_featured_confidence_fallback"),
}
local FEATURED_CONFIDENCE_COLORS = {
	strong = { 0.46, 0.86, 0.36, 0.95 },
	good = { 0.98, 0.78, 0.34, 0.95 },
	fallback = { 0.72, 0.74, 0.80, 0.90 },
}

local function ApplyActionRowStyle(row)
	row.icon:Hide()
	row.favButton:Hide()
	row.text:ClearAllPoints()
	row.text:SetPoint("LEFT", row, "LEFT", 14, 0)
	row.text:SetPoint("RIGHT", row, "RIGHT", -28, 0)
	row.text:SetTextColor(0.60, 0.84, 1.00, 1)
	row.bg:Show()
	row.bg:SetVertexColor(0.11, 0.16, 0.20, 0.78)
	row.disclosure:Show()
	row.disclosure:ClearAllPoints()
	row.disclosure:SetPoint("RIGHT", row, "RIGHT", -10, 0)
	row.disclosure:SetText(">")
	row.disclosure:SetTextColor(0.60, 0.84, 1.00, 0.90)
end

function me:RefreshGuideManagerPanel(panel)
	local f = panel or self.GuideManagerPanel
	if not f then return end
	local rowHeight = f.rowHeight or GUIDE_MANAGER_ROW_HEIGHT
	local blankRows = f.firstBlankRow and 1 or 0

	local rows
	if f.rowsBuilder then
		rows = f.rowsBuilder()
	else
		rows = BuildGuideManagerRows(self, f.search:GetText() or "", f.filterFn, f.browsePath, f.useDrilldown)
	end
	if #rows == 0 then
		local hasSearch = ((f.search and f.search:GetText()) or "") ~= ""
		if hasSearch then
			rows = {
				{ kind = "header", depth = 0, label = LT("gb_empty_no_guides_search") },
				{ kind = "action", depth = 0, label = LT("gb_action_clear_search"), action = "clear_search" },
			}
		else
			rows = {
				{ kind = "header", depth = 0, label = LT("gb_empty_no_guides_category") },
				{ kind = "action", depth = 0, label = LT("gb_action_show_all_categories"), action = "go_home_leveling" },
			}
		end
	end
	f.rowsData = rows

	local shown = f.visibleRows or #f.rows
	FauxScrollFrame_Update(f.scroll, #rows + blankRows, shown, rowHeight)
	local off = FauxScrollFrame_GetOffset(f.scroll)
	local maxoff = math.max(0, (#rows + blankRows) - shown)
	if off > maxoff then
		off = maxoff
		FauxScrollFrame_SetOffset(f.scroll, off)
		f.scroll:SetVerticalScroll(off * rowHeight)
		local sbar = _G[f.scroll:GetName() .. "ScrollBar"]
		if sbar and sbar.SetValue then sbar:SetValue(off * rowHeight) end
	end

	for i = 1, shown do
		local row = f.rows[i]
		local dataIndex = (i + off) - blankRows
		local data = (dataIndex > 0 and dataIndex <= #rows) and rows[dataIndex] or nil
		if data then
			row.data = data
			local text
			local depth = (data.depth or 0)
			local baseX = 6 + (depth * 12)
			row.text:ClearAllPoints()
			row.text:SetPoint("LEFT", row, "LEFT", baseX + 24, 0)
			row.text:SetPoint("RIGHT", row, "RIGHT", -18, 0)
			row.icon:SetTexture(GUIDE_SMALL_ICON_FILE)
			row.bg:Hide()
			row.favButton:Hide()
			row.disclosure:Hide()
			row.icon:ClearAllPoints()
			row.icon:SetPoint("LEFT", row, "LEFT", baseX + 10, 0)
			if data.kind == "folder" then
				text = data.label
				if data.nodisc then
					row.disclosure:Hide()
				else
					row.disclosure:Show()
					row.disclosure:ClearAllPoints()
					row.disclosure:SetPoint("LEFT", row, "LEFT", baseX, 0)
					row.disclosure:SetText(data.open and "v" or ">")
				end
				row.icon:SetTexCoord(unpack(GUIDE_SMALL_ICON_COORDS.folder))
				row.text:SetTextColor(0.86, 0.86, 0.86, 1)
			elseif data.kind == "header" then
				text = data.label
				row.icon:Hide()
				row.text:ClearAllPoints()
				row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
				row.text:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				row.text:SetTextColor(1, 0.88, 0.25, 1)
			elseif data.kind == "action" then
				text = data.label
				ApplyActionRowStyle(row)
			else
				text = data.label or ""
				row.icon:SetTexCoord(unpack(GUIDE_SMALL_ICON_COORDS.guide))
				local isFav = data.title and self:IsGuideFavorite(data.title) or false
				local isSelected = (f.selectedGuideTitle and data.title == f.selectedGuideTitle)
				if isFav or isSelected then
					row.favButton:Show()
				else
					row.favButton:Hide()
				end
				row.favButton:SetChecked(isFav)
				if isFav then
					row.favButton:GetNormalTexture():SetVertexColor(0.95, 0.95, 0.95, 1)
					row.favButton:GetNormalTexture():SetAlpha(1.0)
				else
					row.favButton:GetNormalTexture():SetVertexColor(0.72, 0.72, 0.75, 1)
					row.favButton:GetNormalTexture():SetAlpha(isSelected and 0.55 or 0.0)
				end
				if isSelected then
					row.bg:Show()
					row.bg:SetVertexColor(0.28, 0.28, 0.28, 0.95)
					row.text:SetTextColor(1, 1, 1, 1)
				elseif self.CurrentGuide and data.title == self.CurrentGuide.title then
					row.text:SetTextColor(1, 0.9, 0.35, 1)
				else
					row.text:SetTextColor(0.9, 0.9, 0.9, 1)
				end
				if data.featuredbucket == "next" then
					row.icon:SetTexCoord(unpack(GUIDE_SMALL_ICON_COORDS.star))
					row.text:SetTextColor(1.00, 0.93, 0.55, 1.0)
				end
			end
			row.text:SetText(text)
			if data.kind == "folder" or data.kind == "guide" then
				row.icon:Show()
			else
				row.icon:Hide()
			end
			row:Show()
		else
			row.data = nil
			row.text:SetText(" ")
			row.icon:Hide()
			row.bg:Hide()
			row.favButton:Hide()
			row.disclosure:Hide()
			row:Show()
		end
	end
end

local function EnsureGuideManagerRows(self, panel, wanted)
	panel.rows = panel.rows or {}
	panel.visibleRows = wanted
	local have = #panel.rows
	for i = have + 1, wanted do
		local row = CreateFrame("Button", nil, panel.list)
		local rowHeight = panel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT
		row:SetHeight(rowHeight)
		row:SetPoint("TOPLEFT", panel.list, "TOPLEFT", 6, -1 - ((i - 1) * rowHeight))
		row:SetPoint("RIGHT", panel.list, "RIGHT", -26, 0)
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		row.bg:Hide()
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(14, 14)
		row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
		row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.text:SetPoint("LEFT", row, "LEFT", 20, 0)
		row.text:SetPoint("RIGHT", row, "RIGHT", -18, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetFont(STANDARD_TEXT_FONT, panel.fontSize or GUIDE_MANAGER_FONT_SIZE)
		row.disclosure = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.disclosure:SetPoint("LEFT", row, "LEFT", 6, 0)
		row.disclosure:SetTextColor(0.70, 0.70, 0.70, 1)
		row.disclosure:Hide()
		row.favButton = CreateFrame("CheckButton", nil, row)
		row.favButton:SetSize(14, 14)
		row.favButton:SetPoint("RIGHT", row, "RIGHT", -2, 0)
		row.favButton:SetNormalTexture(GUIDE_SMALL_ICON_FILE)
		row.favButton:GetNormalTexture():SetTexCoord(unpack(GUIDE_SMALL_ICON_COORDS.star))
		row.favButton:SetPushedTexture(GUIDE_SMALL_ICON_FILE)
		row.favButton:GetPushedTexture():SetTexCoord(unpack(GUIDE_SMALL_ICON_COORDS.star))
		row.favButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		row.favButton:SetCheckedTexture(GUIDE_SMALL_ICON_FILE)
		row.favButton:GetCheckedTexture():SetTexCoord(unpack(GUIDE_SMALL_ICON_COORDS.star))
		row.favButton:SetScript("OnClick", function(btn)
			local r = btn:GetParent()
			local data = r and r.data
			if not data or data.kind ~= "guide" or not data.title then return end
			self:ToggleGuideFavorite(data.title)
			if panel and panel.ownerFrame and panel.ownerFrame.SetSelectedGuide and panel.selectedGuideTitle == data.title then
				panel.ownerFrame:SetSelectedGuide(data.title)
			end
			self:RefreshGuideManagerPanel(panel)
		end)
		row.favButton:Hide()
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		row:EnableMouseWheel(true)
		row:SetScript("OnMouseWheel", function(btn, delta)
			local parentList = btn:GetParent()
			if parentList and parentList:GetScript("OnMouseWheel") then
				parentList:GetScript("OnMouseWheel")(parentList, delta)
			end
		end)
		row:SetScript("OnClick", function(btn)
			local data = btn.data
			if not data then return end
			if data.kind == "folder" then
				panel.selectedGuideTitle = nil
				panel.selectedFolderPath = data.path or panel.browsePath or ""
				if panel.ownerFrame and panel.ownerFrame.SetSelectedFolder then
					panel.ownerFrame:SetSelectedFolder(panel.selectedFolderPath)
				end
				if panel.useDrilldown and data.path then
					panel.browsePath = data.path
					if self.db and self.db.profile then
						self.db.profile.guidebrowserpath = data.path
					end
					if panel.ownerFrame and panel.ownerFrame.UpdateCenterHeader then
						panel.ownerFrame:UpdateCenterHeader()
					end
				else
					self.db.profile.guidebrowsertreeexpanded = self.db.profile.guidebrowsertreeexpanded or {}
					self.db.profile.guidebrowsertreeexpanded[data.path] = not self.db.profile.guidebrowsertreeexpanded[data.path]
				end
				self:RefreshGuideManagerPanel(panel)
				return
			end
			if data.kind == "header" then
				return
			end
			if data.kind == "action" then
				if type(data.func) == "function" then
					data.func()
					self:RefreshGuideManagerPanel(panel)
					if panel.ownerFrame and panel.ownerFrame.SetSelectedGuide then
						panel.ownerFrame:SetSelectedGuide(nil)
					end
					return
				end
				if data.action == "clear_search" then
					if panel.search and panel.search.SetText then panel.search:SetText("") end
				elseif data.action == "reset_hidden_featured" then
					if self.db and self.db.profile then
						self.db.profile.guidebrowser_featured_hidden = {}
					end
					if self.db and self.db.char then
						self.db.char.guidebrowser_featured_snooze = {}
					end
					self._featuredSessionHide = {}
				elseif data.action == "go_home" then
					if panel.ownerFrame and panel.ownerFrame.SetSection then panel.ownerFrame:SetSection("home") end
				elseif data.action == "go_home_leveling" then
					if panel.ownerFrame and panel.ownerFrame.SetSection then panel.ownerFrame:SetSection("home") end
					if panel.ownerFrame and panel.ownerFrame.SetCategory then panel.ownerFrame:SetCategory("leveling") end
				end
				return
			end
			if data.title and data.title ~= "" then
				local wasSelected = (panel.selectedGuideTitle == data.title)
				self.db.profile.guidebrowserselectedguide = data.title
				panel.selectedFolderPath = nil
				panel.selectedGuideTitle = data.title
				if panel.ownerFrame and panel.ownerFrame.SetSelectedGuide then
					panel.ownerFrame:SetSelectedGuide(data.title)
				end
				if panel.loadOnClick ~= false or wasSelected then
					self:SetGuide(data.title)
					self:FocusStep(1)
				end
				self:RefreshGuideManagerPanel(panel)
			end
		end)
		panel.rows[i] = row
	end
	-- Reflow all rows to current density, including rows created in older layouts.
	for i = 1, #panel.rows do
		local row = panel.rows[i]
		local rowHeight = panel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT
		row:SetHeight(rowHeight)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", panel.list, "TOPLEFT", 6, -1 - ((i - 1) * rowHeight))
		row:SetPoint("RIGHT", panel.list, "RIGHT", -26, 0)
		if row.text and row.text.SetFont then
			row.text:SetFont(STANDARD_TEXT_FONT, panel.fontSize or GUIDE_MANAGER_FONT_SIZE)
		end
		if row.favButton then
			row.favButton:ClearAllPoints()
			row.favButton:SetPoint("RIGHT", row, "RIGHT", -2, 0)
		end
	end
	for i = wanted + 1, #panel.rows do
		panel.rows[i]:Hide()
	end
end

function me:SetupGuideManagerInlinePanel(parentPanel)
	if self.GuideManagerPanel then return self.GuideManagerPanel end
	if not parentPanel then return nil end

	local panel = CreateFrame("Frame", "ZGVGuideManagerInlinePanel", parentPanel)
	panel:SetPoint("TOPLEFT", parentPanel, "TOPLEFT", 0, -92)
	panel:SetWidth(584)
	panel:SetHeight(248)
	panel:Show()

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
	title:SetText("")

	local searchLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	searchLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -5)
	searchLabel:SetText(LT("gb_search"))

	local search = CreateFrame("EditBox", "ZGVGuideManagerSearchBox", panel, "InputBoxTemplate")
	search:SetAutoFocus(false)
	search:SetWidth(260)
	search:SetHeight(16)
	search:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
	search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
	panel.search = search

	local list = CreateFrame("Frame", nil, panel)
	list:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -1)
	list:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 1)
	list:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
	list:SetBackdropColor(0.03, 0.04, 0.06, 0.70)
	panel.list = list

	local scroll = CreateFrame("ScrollFrame", "ZGVGuideManagerInlineScroll", list, "FauxScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 1, -0)
	scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -22, 0)
	panel.scroll = scroll

	panel.rows = {}

	scroll:SetScript("OnVerticalScroll", function(sf, offset)
		FauxScrollFrame_OnVerticalScroll(sf, offset, GUIDE_MANAGER_ROW_HEIGHT, function() self:RefreshGuideManagerPanel() end)
	end)
	local function ScrollTreeBy(deltaLines)
		local rows = BuildGuideManagerRows(self, search:GetText() or "", panel.filterFn, panel.browsePath, panel.useDrilldown)
		local shown = panel.visibleRows or #panel.rows
		local blankRows = panel.firstBlankRow and 1 or 0
		local total = #rows + blankRows
		local maxoff = math.max(0, total - shown)
		local off = FauxScrollFrame_GetOffset(scroll) or 0
		off = off - deltaLines
		if off < 0 then off = 0 end
		if off > maxoff then off = maxoff end
		FauxScrollFrame_SetOffset(scroll, off)
		-- Keep scrollbar thumb in sync with wheel-driven offset.
		scroll:SetVerticalScroll(off * GUIDE_MANAGER_ROW_HEIGHT)
		local sbar = _G[scroll:GetName() .. "ScrollBar"]
		if sbar and sbar.SetValue then
			sbar:SetValue(off * GUIDE_MANAGER_ROW_HEIGHT)
		end
		self:RefreshGuideManagerPanel()
	end
	local function OnWheel(_, delta)
		ScrollTreeBy((delta or 0) * 3)
	end
	panel:EnableMouseWheel(true)
	panel:SetScript("OnMouseWheel", OnWheel)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", OnWheel)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", OnWheel)
	local sbar = _G[scroll:GetName() .. "ScrollBar"]
	if sbar then
		sbar:EnableMouseWheel(true)
		sbar:SetScript("OnMouseWheel", OnWheel)
	end
	search:SetScript("OnTextChanged", function()
		self.db.profile.guidebrowsersearch = search:GetText() or ""
		FauxScrollFrame_SetOffset(scroll, 0)
		self:RefreshGuideManagerPanel()
	end)

	panel:SetScript("OnShow", function()
		search:SetText((self.db.profile.guidebrowsersearch or ""))
		self:RefreshGuideManagerPanel()
	end)

	local function AnchorInsideGuideManagerGroup()
		panel:ClearAllPoints()
		panel:SetParent(parentPanel)
		panel:SetPoint("TOPLEFT", parentPanel, "TOPLEFT", 0, -92)
		panel:SetWidth(584)
		panel:SetHeight(248)
	end

	parentPanel:HookScript("OnShow", function()
		AnchorInsideGuideManagerGroup()
		EnsureGuideManagerRows(self, panel, GUIDE_MANAGER_VISIBLE_ROWS)
		panel:Show()
		self:RefreshGuideManagerPanel()
	end)
	panel:SetScript("OnSizeChanged", function()
		EnsureGuideManagerRows(self, panel, GUIDE_MANAGER_VISIBLE_ROWS)
		self:RefreshGuideManagerPanel()
	end)
	parentPanel:HookScript("OnHide", function()
		panel:Hide()
	end)

	AnchorInsideGuideManagerGroup()
	EnsureGuideManagerRows(self, panel, GUIDE_MANAGER_VISIBLE_ROWS)
	self.GuideManagerPanel = panel
	return panel
end

function me:OpenGuideManagerOptions()
	local frame = self.GuideManagerStandaloneFrame
	if frame and frame.SetSection then
		frame:SetSection("options")
		return
	end
	InterfaceOptionsFrame_OpenToCategory((self.options and self.options.name) or LT("gb_addon_title"))
end

local GUIDE_MANAGER_TOP_TABS = {
	{ id = "home", label = LT("gb_tab_home") },
	{ id = "featured", label = LT("gb_tab_featured") },
	{ id = "current", label = LT("gb_tab_current") },
	{ id = "recent", label = LT("gb_tab_recent") },
}

local GUIDE_MANAGER_LEFT_MENU = {
	{ id = "leveling", label = LT("gb_cat_leveling"), icon = "Interface\\Icons\\INV_Misc_Book_11", keywords = { "leveling", "levels" } },
	{ id = "dungeons", label = LT("gb_cat_dungeons"), icon = "Interface\\Icons\\INV_Misc_GroupNeedMore", keywords = { "dungeon", "dungeons", "instance" } },
	{ id = "daily", label = LT("gb_cat_daily"), icon = "Interface\\Icons\\Achievement_Daily_5", keywords = { "daily", "dailies" } },
	{ id = "events", label = LT("gb_cat_events"), icon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Lunacy", keywords = { "event", "events", "holiday" } },
	{ id = "reputations", label = LT("gb_cat_reputations"), icon = "Interface\\Icons\\INV_Misc_Note_01", keywords = { "reputation", "reputations" } },
	{ id = "gold", label = LT("gb_cat_gold"), icon = "Interface\\Icons\\INV_Misc_Coin_02", keywords = { "gold", "farm", "farming" } },
	{ id = "professions", label = LT("gb_cat_professions"), icon = "Interface\\Icons\\Trade_BlackSmithing", keywords = { "profession", "professions", "cooking", "fishing", "first aid" } },
	{ id = "petsmounts", label = LT("gb_cat_petsmounts"), icon = "Interface\\Icons\\Ability_Mount_RidingHorse", keywords = { "pet", "pets", "mount", "mounts" } },
	{ id = "titles", label = LT("gb_cat_titles"), icon = "Interface\\Icons\\INV_Inscription_ScrollOfWisdom_01", keywords = { "title", "titles" } },
	{ id = "achievements", label = LT("gb_cat_achievements"), icon = "Interface\\Icons\\Achievement_Quests_Completed_08", keywords = { "achievement", "achievements" } },
	{ id = "misc", label = LT("gb_cat_misc"), icon = "Interface\\Icons\\INV_Misc_Note_06", keywords = nil },
	{ id = "favorites", label = LT("gb_cat_favorites"), icon = "Interface\\Icons\\Ability_Hunter_MasterMarksman", keywords = { "favorite", "favourite" } },
}

local GUIDE_MANAGER_OPTIONS_APPS = {
	{ id = "general", label = LT("gb_opt_guides"), app = "ZygorGuidesViewer", desc = LT("gb_opt_desc_guides") },
	{ id = "stepdisplay", label = LT("gb_opt_stepdisplay"), app = "ZygorGuidesViewer-StepDisplay", desc = LT("gb_opt_desc_stepdisplay") },
	{ id = "progress", label = LT("gb_opt_progress"), app = "ZygorGuidesViewer-Progress", desc = LT("gb_opt_desc_progress") },
	{ id = "travel", label = LT("gb_opt_travel"), app = "ZygorGuidesViewer-Travel", desc = LT("gb_opt_desc_travel") },
	{ id = "map", label = LT("gb_opt_map"), app = "ZygorGuidesViewer-Maps", desc = LT("gb_opt_desc_map") },
	{ id = "notifications", label = LT("gb_opt_notifications"), app = "ZygorGuidesViewer-Notifications", desc = LT("gb_opt_desc_notifications") },
	{ id = "actionbuttons", label = LT("gb_opt_actionbuttons"), app = "ZygorGuidesViewer-ActionButtons", desc = LT("gb_opt_desc_actionbuttons") },
	{ id = "convenience", label = LT("gb_opt_convenience"), app = "ZygorGuidesViewer-Conv", desc = LT("gb_opt_desc_convenience") },
	{ id = "accessibility", label = LT("gb_opt_accessibility"), app = "ZygorGuidesViewer-Accessibility", desc = LT("gb_opt_desc_accessibility") },
	{ id = "profile", label = LT("gb_opt_profile"), app = "ZygorGuidesViewer-Profile", desc = LT("gb_opt_desc_profile") },
	{ id = "about", label = LT("gb_opt_about"), app = "ZygorGuidesViewer-About", desc = LT("gb_opt_desc_about") },
}

local GUIDE_MANAGER_OPTIONS_ICONS = {
	["ZygorGuidesViewer"] = "Interface\\Icons\\INV_Misc_Gear_01",
	["ZygorGuidesViewer-Display"] = "Interface\\Icons\\INV_Misc_Spyglass_03",
	["ZygorGuidesViewer-StepDisplay"] = "Interface\\Icons\\INV_Misc_Book_11",
	["ZygorGuidesViewer-Progress"] = "Interface\\Icons\\INV_Misc_Book_11",
	["ZygorGuidesViewer-Travel"] = "Interface\\Icons\\INV_Misc_Map_01",
	["ZygorGuidesViewer-Maps"] = "Interface\\Icons\\INV_Misc_Map_01",
	["ZygorGuidesViewer-Notifications"] = "Interface\\Icons\\INV_Misc_Note_01",
	["ZygorGuidesViewer-ActionButtons"] = "Interface\\Icons\\INV_Misc_QuestionMark",
	["ZygorGuidesViewer-Conv"] = "Interface\\Icons\\INV_Misc_Toy_10",
	["ZygorGuidesViewer-Accessibility"] = "Interface\\Icons\\INV_Misc_Eye_01",
	["ZygorGuidesViewer-Profile"] = "Interface\\Icons\\INV_Misc_Book_09",
	["ZygorGuidesViewer-About"] = "Interface\\Icons\\INV_Misc_Note_05",
	["ZygorGuidesViewer-Debug"] = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local function BuildGuideManagerOptionsApps(self)
	local apps = {}
	for _,opt in ipairs(GUIDE_MANAGER_OPTIONS_APPS) do
		tinsert(apps, opt)
	end
	if self and self.db and self.db.profile and self.db.profile.debug then
		tinsert(apps, { id = "debug", label = LT("gb_opt_advanced"), app = "ZygorGuidesViewer-Debug", desc = LT("gb_opt_desc_advanced") })
	end
	return apps
end

local function GetOptionsAppMeta(appName)
	for _,opt in ipairs(GUIDE_MANAGER_OPTIONS_APPS) do
		if opt.app == appName then return opt end
	end
	if appName == "ZygorGuidesViewer-Debug" then
		return { label = LT("gb_opt_advanced"), desc = LT("gb_opt_desc_advanced") }
	end
	return { label = LT("gb_opt_general"), desc = LT("gb_opt_desc_general") }
end

local function BuildOptionsTableSearchText(tbl, out)
	if type(tbl) ~= "table" then return end
	if type(tbl.name) == "string" then tinsert(out, tbl.name) end
	if type(tbl.desc) == "string" then tinsert(out, tbl.desc) end
	if type(tbl.values) == "table" then
		for _,v in pairs(tbl.values) do
			if type(v) == "string" then tinsert(out, v) end
		end
	end
	if type(tbl.args) == "table" then
		for _,node in pairs(tbl.args) do
			BuildOptionsTableSearchText(node, out)
		end
	end
end

local function GetOptionsAppSearchHay(self, appName)
	if not self then return "" end
	self._optionsSearchIndex = self._optionsSearchIndex or {}
	if self._optionsSearchIndex[appName] then return self._optionsSearchIndex[appName] end

	local src
	if appName=="ZygorGuidesViewer" then src=self.options
	elseif appName=="ZygorGuidesViewer-Display" then src=self.optionsdisplay
	elseif appName=="ZygorGuidesViewer-StepDisplay" then src=self.optionsstepdisplay
	elseif appName=="ZygorGuidesViewer-Progress" then src=self.optionsprogress
	elseif appName=="ZygorGuidesViewer-Travel" then src=self.optionstravelsystem
	elseif appName=="ZygorGuidesViewer-Maps" then src=self.optionsmapswaypoints
	elseif appName=="ZygorGuidesViewer-Notifications" then src=self.optionsnotifications
	elseif appName=="ZygorGuidesViewer-ActionButtons" then src=self.optionsactionbuttons
	elseif appName=="ZygorGuidesViewer-Conv" then src=self.optionsconv
	elseif appName=="ZygorGuidesViewer-Accessibility" then src=self.optionsaccessibility
	elseif appName=="ZygorGuidesViewer-Profile" then src=self.optionsprofile
	elseif appName=="ZygorGuidesViewer-About" then src=self.optionsabout
	elseif appName=="ZygorGuidesViewer-Debug" then src=self.optionsdebug
	end

	local chunks = {}
	BuildOptionsTableSearchText(src, chunks)
	local hay = strlower(table.concat(chunks, " "):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""))
	self._optionsSearchIndex[appName] = hay
	return hay
end

local GUIDE_MANAGER_TAB_ICON_COORDS = {
	leveling = {1,1},
	events = {2,1},
	daily = {3,1},
	gold = {1,2},
	professions = {2,2},
	petsmounts = {3,2},
	achievements = {4,2},
	titles = {1,3},
	reputations = {2,3},
	dungeons = {4,3},
	-- Retail TabsIcons uses QUESTS at {3,4}; this is the closest "misc catch-all" fit.
	misc = {3,4},
	favorites = {4,4},
}

local function GetTabsIconTexCoord(categoryId)
	local cr = GUIDE_MANAGER_TAB_ICON_COORDS[categoryId]
	if not cr then return 0,1,0,1 end
	local col,row = cr[1],cr[2]
	local cols,rows = 8,4
	local l = (col-1)/cols
	local r = col/cols
	local t = (row-1)/rows
	local b = row/rows
	return l,r,t,b
end

local GUIDE_MANAGER_OPTIONS_ICON_COORDS = {
	general = {2,1},
	stepdisplay = {2,2},
	display = {2,3},
	travelsystem = {2,4},
	poi = {2,5},
	notification = {2,6},
	gear = {2,7},
	itemscore = {2,8},
	gold = {2,9},
	extras = {2,10},
	profile = {2,11},
	about = {2,12},
	share = {2,13},
	automation = {2,16},
	actionbuttons = {2,17},
	maps = {2,18},
}

local function GetOptionsIconTexCoord(iconId)
	local cr = GUIDE_MANAGER_OPTIONS_ICON_COORDS[iconId]
	if not cr then return 0,1,0,1 end
	local col,row = cr[1],cr[2]
	local cols,rows = 2,32
	local l = (col-1)/cols
	local r = col/cols
	local t = (row-1)/rows
	local b = row/rows
	return l,r,t,b
end

local GUIDE_MANAGER_OPTIONS_APP_ICON = {
	["ZygorGuidesViewer"] = "general",
	["ZygorGuidesViewer-Display"] = "display",
	["ZygorGuidesViewer-StepDisplay"] = "stepdisplay",
	["ZygorGuidesViewer-Progress"] = "notification",
	["ZygorGuidesViewer-Travel"] = "travelsystem",
	["ZygorGuidesViewer-Maps"] = "maps",
	["ZygorGuidesViewer-Notifications"] = "notification",
	["ZygorGuidesViewer-ActionButtons"] = "actionbuttons",
	["ZygorGuidesViewer-Conv"] = "automation",
	["ZygorGuidesViewer-Accessibility"] = "extras",
	["ZygorGuidesViewer-Profile"] = "profile",
	["ZygorGuidesViewer-About"] = "about",
	["ZygorGuidesViewer-Debug"] = "about",
}

local function StripColorCodes(text)
	return (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function FormatReasonLines(text)
	local raw = tostring(text or "")
	if raw == "" then return "" end
	if not strfind(raw, "|", 1, true) then return raw end
	local out = {}
	for part in raw:gmatch("[^|]+") do
		local line = part:gsub("^%s+", ""):gsub("%s+$", "")
		if line ~= "" then tinsert(out, line) end
	end
	if #out == 0 then return raw end
	return table.concat(out, "\n")
end

local function ParseWhyGainFromContext(text)
	local context = tostring(text or "")
	local whyPrefix = LT("gb_meta_why_prefix")
	local gainPrefix = LT("gb_meta_gain_prefix")
	local why, gain = "", ""
	for part in context:gmatch("[^|]+") do
		local line = part:gsub("^%s+", ""):gsub("%s+$", "")
		if line:sub(1, #whyPrefix) == whyPrefix then
			why = line:sub(#whyPrefix + 1):gsub("^%s+", ""):gsub("%s+$", "")
		elseif line:sub(1, #gainPrefix) == gainPrefix then
			gain = line:sub(#gainPrefix + 1):gsub("^%s+", ""):gsub("%s+$", "")
		end
	end
	return why or "", gain or ""
end

local function CountKeys(tbl)
	local n = 0
	for _ in pairs(tbl or {}) do n = n + 1 end
	return n
end

local GUIDE_CATEGORY_ALIASES = {
	leveling = "leveling", level = "leveling", levels = "leveling", questing = "leveling",
	dungeon = "dungeons", dungeons = "dungeons", instance = "dungeons", instances = "dungeons",
	daily = "daily", dailies = "daily",
	event = "events", events = "events", holiday = "events", holidays = "events",
	reputation = "reputations", reputations = "reputations", rep = "reputations", reps = "reputations",
	gold = "gold", farming = "gold", farm = "gold", money = "gold",
	profession = "professions", professions = "professions", tradeskill = "professions", tradeskills = "professions",
	pet = "petsmounts", pets = "petsmounts", mount = "petsmounts", mounts = "petsmounts",
	title = "titles", titles = "titles",
	achievement = "achievements", achievements = "achievements",
}

local function NormalizeGuideCategory(cat)
	if not cat or cat == "" then return nil end
	cat = strlower(tostring(cat):gsub("%s+", ""))
	return GUIDE_CATEGORY_ALIASES[cat] or nil
end

local function InferGuideCategory(guide, title, full)
	if guide then
		local meta = NormalizeGuideCategory(guide.type)
		if meta then return meta end
	end

	local hay = strlower((title or "") .. " " .. (full or "") .. " " .. (guide and guide.title_short or ""))
	-- Prefer stronger distinctions first.
	if strfind(hay, "achievement", 1, true) then return "achievements" end
	if strfind(hay, "reputation", 1, true) or strfind(hay, " rep", 1, true) then return "reputations" end
	if strfind(hay, "dungeon", 1, true) or strfind(hay, "instance", 1, true) then return "dungeons" end
	if strfind(hay, "dailies", 1, true) or strfind(hay, "daily", 1, true) then return "daily" end
	if strfind(hay, "event", 1, true) or strfind(hay, "holiday", 1, true) then return "events" end
	if strfind(hay, "profession", 1, true) or strfind(hay, "tradeskill", 1, true) then return "professions" end
	if strfind(hay, "pet", 1, true) or strfind(hay, "mount", 1, true) then return "petsmounts" end
	if strfind(hay, "title", 1, true) then return "titles" end
	if strfind(hay, "gold", 1, true) or strfind(hay, "farm", 1, true) then return "gold" end
	if strfind(hay, "level", 1, true) or strfind(hay, "quest", 1, true) then return "leveling" end
	return nil
end

local function CategoryFilterFor(id)
	if id == "misc" then
		return function(title, full, guide)
			-- Explicit audit bucket: no metadata and no confident inferred category.
			return InferGuideCategory(guide, title, full) == nil
		end
	end
	for _,entry in ipairs(GUIDE_MANAGER_LEFT_MENU) do
		if entry.id == id then
			local keys = entry.keywords
			return function(title, full, guide)
				local inferred = InferGuideCategory(guide, title, full)
				if inferred then return inferred == id end
				if not keys then return false end
				local hay = strlower((title or "") .. " " .. (full or ""))
				for _,k in ipairs(keys) do
					if strfind(hay, strlower(k), 1, true) then return true end
				end
				return false
			end
		end
	end
	return nil
end

local function CountGuidesForCategory(self, categoryId, searchText)
	local needle = strlower((searchText or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	local function includeText(txt)
		if needle == "" then return true end
		return strfind(strlower(txt or ""), needle, 1, true) ~= nil
	end

	if categoryId == "favorites" then
		local fav = self.db and self.db.profile and self.db.profile.guidefavorites or {}
		local n = 0
		for title,_ in pairs(fav or {}) do
			local g = self:GetGuideByTitle(title)
			local label = (g and g.title_short) or title
			if includeText((label or "") .. " " .. (title or "")) then
				n = n + 1
			end
		end
		return n
	end

	local filter = CategoryFilterFor(categoryId)
	local n = 0
	for _,g in ipairs(self.registeredguides or {}) do
		local title = g and g.title
		if title and title ~= "" then
			local label = g.title_short or title
			local full = title
			local matchesSearch = includeText((label or "") .. " " .. full)
			local matchesCategory = (not filter) or filter(title, full, g)
			if matchesSearch and matchesCategory then
				n = n + 1
			end
		end
	end
	return n
end

local function GetGuideLastUsedText(self, title)
	if not (self and self.db and self.db.char and self.db.char.guides_history and title) then return "Never" end
	local hist = self.db.char.guides_history
	local rank = 0
	for i = #hist, 1, -1 do
		if hist[i] and hist[i].full == title then
			rank = (#hist - i) + 1
			break
		end
	end
	if rank == 0 then return "Never" end
	if rank == 1 then return "Now" end
	return ("Recent #%d"):format(rank)
end

local function GetGuideTypeText(guide)
	if not guide then return "Guide" end
	if guide.type and guide.type ~= "" then return tostring(guide.type) end
	local t = strlower(guide.title or "")
	if strfind(t, "dungeon", 1, true) then return "Dungeon" end
	if strfind(t, "daily", 1, true) then return "Daily" end
	if strfind(t, "achievement", 1, true) then return "Achievement" end
	if strfind(t, "reputation", 1, true) then return "Reputation" end
	if strfind(t, "profession", 1, true) then return "Profession" end
	return "Guide"
end

function me:IsGuideFavorite(title)
	if not (self and self.db and self.db.profile and title and title ~= "") then return false end
	self.db.profile.guidefavorites = self.db.profile.guidefavorites or {}
	return self.db.profile.guidefavorites[title] and true or false
end

function me:ToggleGuideFavorite(title)
	if not (self and self.db and self.db.profile and title and title ~= "") then return end
	self.db.profile.guidefavorites = self.db.profile.guidefavorites or {}
	if self.db.profile.guidefavorites[title] then
		self.db.profile.guidefavorites[title] = nil
	else
		self.db.profile.guidefavorites[title] = true
	end
end

local function BuildSpecialSectionRows(self, section, searchText)
	local rows = {}
	local needle = strlower((searchText or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	local function includeText(txt)
		if needle == "" then return true end
		return strfind(strlower(txt or ""), needle, 1, true) ~= nil
	end

	if section == "current" then
		local g = self.CurrentGuide
		if g and g.title then
			local label = (g.title_short and g.title_short ~= "" and g.title_short) or g.title
			if includeText((label or "") .. " " .. g.title) then
				tinsert(rows, { kind = "guide", depth = 0, label = label, title = g.title })
			end
		end
		if #rows == 0 then
			tinsert(rows, { kind = "header", depth = 0, label = LT("gb_empty_no_current_guide") })
			tinsert(rows, { kind = "action", depth = 0, label = LT("gb_action_go_home"), action = "go_home" })
		end
		return rows
	end

	if section == "recent" then
		local hist = self.db and self.db.char and self.db.char.guides_history or {}
		local seen = {}
		local grouped = {}
		local count = 0
		for i = #hist, 1, -1 do
			local h = hist[i]
			local full = h and h.full
			if full and not seen[full] then
				seen[full] = true
				local label = h.short or full
				local group = (full:match("^([^\\]+)\\") or LT("gb_other"))
				local txt = label .. " " .. full .. " " .. group
				if includeText(txt) then
					if not grouped[group] then
						grouped[group] = {}
					end
					tinsert(grouped[group], { kind = "guide", depth = 0, label = label, title = full })
					count = count + 1
				end
			end
			if count >= 80 then break end
		end
		local emitted = {}
		local groups = self.registered_groups and self.registered_groups.groups or {}
		for _,group in ipairs(groups) do
			local gname = group and group.name
			if gname and grouped[gname] and not emitted[gname] then
				emitted[gname] = true
				tinsert(rows, { kind = "header", depth = 0, label = gname })
				for _,r in ipairs(grouped[gname]) do
					tinsert(rows, r)
				end
			end
		end
		for gname,grows in pairs(grouped) do
			if not emitted[gname] then
				tinsert(rows, { kind = "header", depth = 0, label = gname })
				for _,r in ipairs(grows) do
					tinsert(rows, r)
				end
			end
		end
		if #rows == 0 then
			tinsert(rows, { kind = "header", depth = 0, label = LT("gb_empty_no_recent_guides") })
			tinsert(rows, { kind = "action", depth = 0, label = LT("gb_action_open_home"), action = "go_home" })
		end
		return rows
	end

	if section == "featured" then
		local list = self.registeredguides or {}
		local playerLevel = tonumber(UnitLevel("player") or 1) or 1
		local _,playerClassFile = UnitClass("player")
		local _,playerRaceFile = UnitRace("player")
		local playerClassToken = strlower((playerClassFile or ""):gsub("%s+", ""))
		local playerRaceToken = strlower((playerRaceFile or ""):gsub("%s+", ""))
		local currentGuide = self.CurrentGuide
		local currentTitle = currentGuide and currentGuide.title or nil
		local currentNext = currentGuide and currentGuide.next or nil
		local currentStep = tonumber(self.CurrentStepNum or 1) or 1
		local progressDB = self.db and self.db.char and self.db.char.guide_progress or {}
		if self.db and self.db.profile then
			self.db.profile.guidebrowser_featured_hidden = self.db.profile.guidebrowser_featured_hidden or {}
		end
		if self.db and self.db.char then
			self.db.char.guidebrowser_featured_snooze = self.db.char.guidebrowser_featured_snooze or {}
		end
		self._featuredSessionHide = self._featuredSessionHide or {}
		local legacyHiddenFeatured = (self.db and self.db.profile and self.db.profile.guidebrowser_featured_hidden) or {}
		local featuredSnooze = (self.db and self.db.char and self.db.char.guidebrowser_featured_snooze) or {}
		local featuredSessionHide = self._featuredSessionHide or {}
		local nowEpoch = time()
		local function IsSnoozed(title)
			if not title or title == "" then return false end
			if featuredSessionHide[title] then return true end
			local untilTs = tonumber(featuredSnooze[title] or 0) or 0
			if untilTs > nowEpoch then return true end
			if untilTs > 0 and untilTs <= nowEpoch then featuredSnooze[title] = nil end
			if legacyHiddenFeatured[title] then
				-- Migrate legacy hidden state into a 24h snooze once.
				featuredSnooze[title] = nowEpoch + (24 * 60 * 60)
				legacyHiddenFeatured[title] = nil
				return true
			end
			return false
		end
		local optEnableFallback = not (self.db and self.db.profile) or self.db.profile.guidebrowser_featured_enablefallback ~= false
		local optHideRecentCompleted = not (self.db and self.db.profile) or self.db.profile.guidebrowser_featured_hiderecentcompleted ~= false
		local optShowConfidence = not (self.db and self.db.profile) or self.db.profile.guidebrowser_featured_showconfidence ~= false
		local bucketOrder = { next = 1, progress = 2, level = 3, featured = 4 }
		local history = self.db and self.db.char and self.db.char.guides_history or {}
		local currentParent = currentTitle and currentTitle:match("^(.*)\\[^\\]+$") or nil
		local nextGuideExists = currentNext and self.GetGuideByTitle and self:GetGuideByTitle(currentNext) and true or false
		local chainRank = {}
		do
			local curTitle = currentTitle
			local depth = 0
			local seen = {}
			while curTitle and curTitle ~= "" and depth < 8 do
				local curGuide = self.GetGuideByTitle and self:GetGuideByTitle(curTitle) or nil
				local nxt = curGuide and curGuide.next or nil
				if not nxt or nxt == "" or seen[nxt] then break end
				seen[nxt] = true
				depth = depth + 1
				chainRank[nxt] = depth
				curTitle = nxt
			end
		end
		local recentRank = {}
		do
			local seen = {}
			local rank = 0
			for i = #history, 1, -1 do
				local h = history[i]
				local full = h and h.full
				if full and not seen[full] then
					seen[full] = true
					rank = rank + 1
					recentRank[full] = rank
					if rank >= 40 then break end
				end
			end
		end
		local playerProfessions = {}
		if GetProfessions and GetProfessionInfo then
			local p1,p2,a1,a2,cooking,firstaid = GetProfessions()
			local plist = {p1,p2,a1,a2,cooking,firstaid}
			for _,pid in ipairs(plist) do
				if pid then
					local pname = GetProfessionInfo(pid)
					if pname and pname ~= "" then
						playerProfessions[strlower(pname)] = true
					end
				end
			end
		end
		local CLASS_PATTERNS = {
			{ token = "warrior", key = "warrior" },
			{ token = "paladin", key = "paladin" },
			{ token = "hunter", key = "hunter" },
			{ token = "rogue", key = "rogue" },
			{ token = "priest", key = "priest" },
			{ token = "death knight", key = "deathknight" },
			{ token = "deathknight", key = "deathknight" },
			{ token = " dk ", key = "deathknight" },
			{ token = "shaman", key = "shaman" },
			{ token = "mage", key = "mage" },
			{ token = "warlock", key = "warlock" },
			{ token = "druid", key = "druid" },
		}
		local RACE_PATTERNS = {
			{ token = "human", key = "human" },
			{ token = "dwarf", key = "dwarf" },
			{ token = "night elf", key = "nightelf" },
			{ token = "gnome", key = "gnome" },
			{ token = "draenei", key = "draenei" },
			{ token = "orc", key = "orc" },
			{ token = "undead", key = "scourge" },
			{ token = "tauren", key = "tauren" },
			{ token = "troll", key = "troll" },
			{ token = "blood elf", key = "bloodelf" },
		}
		local PROF_PATTERNS = {
			"alchemy", "blacksmithing", "enchanting", "engineering", "herbalism", "inscription",
			"jewelcrafting", "leatherworking", "mining", "skinning", "tailoring", "cooking", "first aid", "fishing",
		}
		local function DetectAudience(text, patterns)
			local found = {}
			for _,p in ipairs(patterns) do
				if strfind(text, p.token, 1, true) then
					found[p.key] = true
				end
			end
			return found
		end
		local function HasAnyKey(tbl)
			for _ in pairs(tbl or {}) do return true end
			return false
		end
		local function ProfMatch(text)
			local detected = {}
			for _,p in ipairs(PROF_PATTERNS) do
				if strfind(text, p, 1, true) then
					detected[p] = true
				end
			end
			local hasDetected = HasAnyKey(detected)
			if not hasDetected then return false,false end
			for p,_ in pairs(detected) do
				if playerProfessions[p] then return true,true end
			end
			return true,false
		end

		local function ParseLevelRange(text)
			if not text or text == "" then return nil,nil end
			local lo,hi = text:match("%((%d+)%s*%-%s*(%d+)%)")
			if not lo or not hi then lo,hi = text:match("(%d+)%s*%-%s*(%d+)") end
			lo,hi = tonumber(lo or 0), tonumber(hi or 0)
			if lo and hi and lo > 0 and hi > 0 then
				if lo > hi then lo,hi = hi,lo end
				return lo,hi
			end
			return nil,nil
		end
		local inferredChainRank = {}
		do
			if currentTitle and currentTitle ~= "" and (not nextGuideExists) then
				local curGuide = self.GetGuideByTitle and self:GetGuideByTitle(currentTitle) or nil
				local curLabel = (curGuide and curGuide.title_short) or currentTitle
				local clo,chi = ParseLevelRange((curLabel or "") .. " " .. currentTitle)
				local currentMid = playerLevel
				if clo and chi then currentMid = math.floor((clo + chi) / 2) end
				local curParent = currentTitle:match("^(.*)\\[^\\]+$")
				local pool = {}
				for _,ig in ipairs(list or {}) do
					local it = ig and ig.title
					if it and it ~= "" and it ~= currentTitle then
						local ipar = it:match("^(.*)\\[^\\]+$")
						if curParent and ipar == curParent then
							local ilabel = ig.title_short or it
							local lo,hi = ParseLevelRange((ilabel or "") .. " " .. it)
							local mid = lo and hi and math.floor((lo + hi) / 2) or currentMid
							local ahead = (mid >= currentMid) and 0 or 1
							tinsert(pool, { title = it, mid = mid, ahead = ahead, dist = math.abs(mid - currentMid) })
						end
					end
				end
				table.sort(pool, function(a,b)
					if a.ahead ~= b.ahead then return a.ahead < b.ahead end
					if a.dist ~= b.dist then return a.dist < b.dist end
					return strlower(a.title or "") < strlower(b.title or "")
				end)
				for i,p in ipairs(pool) do
					inferredChainRank[p.title] = i
					if i >= 6 then break end
				end
			end
		end

		local candidates = {}
		local function InferGuideGain(cat, title)
			local t = strlower(title or "")
			if strfind(t, "unlock", 1, true) or strfind(t, "attun", 1, true) then return "Unlock progression" end
			if cat == "leveling" then return "XP progression" end
			if cat == "dungeons" then return "Dungeon progression" end
			if cat == "daily" then return "Daily rewards" end
			if cat == "reputations" then return "Reputation gains" end
			if cat == "professions" then return "Profession progression" end
			if cat == "achievements" then return "Achievement progress" end
			if strfind(t, "dungeon", 1, true) then return "Dungeon progression" end
			if strfind(t, "daily", 1, true) then return "Daily rewards" end
			if strfind(t, "reputation", 1, true) or strfind(t, " rep", 1, true) then return "Reputation gains" end
			if strfind(t, "profession", 1, true) then return "Profession progression" end
			if strfind(t, "achievement", 1, true) then return "Achievement progress" end
			return "XP progression"
		end
		local function AddReason(reasons, reason)
			if not reason or reason == "" then return end
			for _,r in ipairs(reasons) do if r == reason then return end end
			tinsert(reasons, reason)
		end
		local function ResolveGainType(cat, title)
			local t = strlower(title or "")
			if strfind(t, "unlock", 1, true) or strfind(t, "attun", 1, true) then return "unlock" end
			if cat == "leveling" then return "xp" end
			if cat == "dungeons" then return "dungeon" end
			if cat == "daily" then return "daily" end
			if cat == "reputations" then return "reputation" end
			if cat == "professions" then return "profession" end
			if cat == "achievements" then return "achievement" end
			if strfind(t, "dungeon", 1, true) then return "dungeon" end
			if strfind(t, "daily", 1, true) then return "daily" end
			if strfind(t, "reputation", 1, true) or strfind(t, " rep", 1, true) then return "reputation" end
			if strfind(t, "profession", 1, true) then return "profession" end
			if strfind(t, "achievement", 1, true) then return "achievement" end
			return "xp"
		end
		local function ConfidenceByScore(bucket, score)
			if bucket == "next" or score >= 1030 then return "strong" end
			if score >= 760 then return "good" end
			return "fallback"
		end
		local function ComputeGuideProgress(guide, title, steps, remembered)
			local complete = 0
			if guide and guide.GetCompletion then
				local ok, _, cur, total = pcall(function() return guide:GetCompletion() end)
				if ok and total and total > 0 and cur then
					complete = math.floor((cur / total) * 100 + 0.5)
				end
			end
			if complete <= 0 and steps > 0 and currentTitle and title == currentTitle then
				local stepnum = currentStep
				if stepnum < 1 then stepnum = 1 end
				if stepnum > (steps + 1) then stepnum = steps + 1 end
				complete = math.floor(((stepnum - 1) / steps) * 100 + 0.5)
			end
			if complete <= 0 and steps > 0 and remembered and remembered > 0 then
				local stepnum = remembered
				if stepnum < 1 then stepnum = 1 end
				if stepnum > (steps + 1) then stepnum = steps + 1 end
				if currentTitle and title == currentTitle then
					complete = math.floor(((stepnum - 1) / steps) * 100 + 0.5)
				else
					complete = math.floor((stepnum / steps) * 100 + 0.5)
				end
			end
			if complete < 0 then complete = 0 end
			if complete > 100 then complete = 100 end
			return complete
		end
		local function OrdinalLabel(n)
			n = tonumber(n or 1) or 1
			if n % 100 >= 11 and n % 100 <= 13 then return tostring(n) .. "th Next" end
			local d = n % 10
			if d == 1 then return tostring(n) .. "st Next" end
			if d == 2 then return tostring(n) .. "nd Next" end
			if d == 3 then return tostring(n) .. "rd Next" end
			return tostring(n) .. "th Next"
		end

		local keptCounts = { next = 0, progress = 0, level = 0, featured = 0 }
		local fallbackByBucket = { next = {}, progress = {}, level = {}, featured = {} }
		for _,g in ipairs(list) do
			local title = g and g.title
			if title and title ~= "" then
				local label = g.title_short or title
				local searchHay = (label or "") .. " " .. title
				if includeText(searchHay) then
					local lowerHay = " " .. strlower(searchHay) .. " "
					local classAudience = DetectAudience(lowerHay, CLASS_PATTERNS)
					local raceAudience = DetectAudience(lowerHay, RACE_PATTERNS)
					local hasClassAudience = HasAnyKey(classAudience)
					local hasRaceAudience = HasAnyKey(raceAudience)
					local classAudienceCount = CountKeys(classAudience)
					local raceAudienceCount = CountKeys(raceAudience)
					local classMismatch = hasClassAudience and (not classAudience[playerClassToken]) and classAudienceCount <= 2
					local raceMismatch = hasRaceAudience and (not raceAudience[playerRaceToken]) and raceAudienceCount <= 1
					local profTagged,profMatch = ProfMatch(lowerHay)

					local cat = InferGuideCategory(g, title, title)
					local featuredFlag = (g.condition_suggested_raw and true) or (cat == "leveling")
					local lo,hi = ParseLevelRange(searchHay)
					local steps = (g.steps and #g.steps) or 0
					local remembered = nil
					if self.GetRememberedGuideStep then
						remembered = self:GetRememberedGuideStep(title)
					end
					if not remembered and progressDB and progressDB[title] and progressDB[title].step then
						remembered = progressDB[title].step
					end
					remembered = tonumber(remembered or 0) or 0
					local complete = ComputeGuideProgress(g, title, steps, remembered)
					if complete >= 100 then
						complete = 100
					end
					local inProgress = (steps > 0 and complete > 0 and complete < 100)
					local recentlyCompleted = false
					if optHideRecentCompleted and steps > 0 and remembered >= steps and (recentRank[title] and recentRank[title] <= 3) then
						recentlyCompleted = true
					end
					local inLevelBand = false
					local nearLevelBand = false
					if lo and hi then
						inLevelBand = (playerLevel >= lo - 2 and playerLevel <= hi + 2)
						if not inLevelBand then
							local dlo = math.abs(playerLevel - lo)
							local dhi = math.abs(playerLevel - hi)
							nearLevelBand = (math.min(dlo, dhi) <= 4)
						end
					end

					local reasons = {}
					local gain = InferGuideGain(cat, title)
					local gainType = ResolveGainType(cat, title)
					local isFavorite = self.IsGuideFavorite and self:IsGuideFavorite(title) or false
					local parentPath = title:match("^(.*)\\[^\\]+$")
					local sameParent = currentParent and parentPath and currentParent == parentPath
					local recency = recentRank[title]
					if recency and recency <= 5 then AddReason(reasons, LT("gb_reason_recently_used")) end
					if complete < 100 then AddReason(reasons, LT("gb_reason_incomplete")) end
					if inLevelBand then AddReason(reasons, LT("gb_reason_your_level_range"))
					elseif nearLevelBand then AddReason(reasons, LT("gb_reason_near_your_level"))
					end
					if hasClassAudience and not classMismatch then AddReason(reasons, LT("gb_reason_your_class")) end
					if hasRaceAudience and not raceMismatch then AddReason(reasons, LT("gb_reason_your_race")) end
					if profTagged and profMatch then AddReason(reasons, LT("gb_reason_your_profession")) end
					if isFavorite then AddReason(reasons, LT("gb_reason_favorite")) end

					local bucket,score
					local chainStep = nil
					local keepForChain = false
					if complete < 100 then
						local rankInChain = chainRank[title]
						if rankInChain and rankInChain >= 1 then
							bucket = "next"
							score = 1160 - ((rankInChain - 1) * 26)
							chainStep = rankInChain
							keepForChain = true
							if rankInChain == 1 then
								AddReason(reasons, LT("gb_reason_current_chain"))
							else
								AddReason(reasons, LT("gb_reason_chain_step_format", rankInChain))
							end
						elseif inferredChainRank[title] and inferredChainRank[title] >= 1 then
							local ifallback = inferredChainRank[title]
							bucket = "next"
							score = 980 - ((ifallback - 1) * 18)
							chainStep = ifallback
							AddReason(reasons, LT("gb_reason_inferred_continuation"))
						elseif currentNext and title == currentNext and nextGuideExists then
							bucket = "next"
							score = 1100
							keepForChain = true
							AddReason(reasons, LT("gb_reason_current_chain"))
						elseif sameParent and title ~= currentTitle then
							bucket = "next"
							score = 1020
							AddReason(reasons, LT("gb_reason_chapter_continuation"))
						elseif currentTitle and title == currentTitle then
							bucket = "progress"
							score = 980
							AddReason(reasons, LT("gb_reason_current_chain"))
						elseif inProgress then
							bucket = "progress"
							score = 900 + math.max(0, math.min(100, complete))
						elseif inLevelBand or nearLevelBand then
							local distanceBonus = 0
							if lo and hi then
								if playerLevel < lo then distanceBonus = math.max(0, 40 - (lo - playerLevel) * 8)
								elseif playerLevel > hi then distanceBonus = math.max(0, 40 - (playerLevel - hi) * 8)
								else distanceBonus = 60 end
							end
							bucket = "level"
							score = 760 + distanceBonus
							AddReason(reasons, inLevelBand and LT("gb_reason_your_level_range") or LT("gb_reason_near_your_level"))
						elseif featuredFlag then
							bucket = "featured"
							score = 520
						end
					end

					if bucket then
						keepForChain = keepForChain or (currentTitle and title == currentTitle)
						if IsSnoozed(title) then
							bucket = nil
						end
						if (classMismatch or raceMismatch or (cat == "professions" and profTagged and not profMatch)) and not keepForChain then
							bucket = nil
						end
						if recentlyCompleted and not keepForChain and not inProgress then
							bucket = nil
						end
					end

					local confidence = nil
					if bucket then
						if recency then
							score = score + math.max(0, 22 - (recency * 3))
						end
						if lo and hi then
							local levelDistance = 0
							if playerLevel < lo then levelDistance = lo - playerLevel end
							if playerLevel > hi then levelDistance = playerLevel - hi end
							if levelDistance >= 10 then score = score - 110
							elseif levelDistance >= 6 then score = score - 45
							end
						end
						if isFavorite then
							score = score + 30
						end
						confidence = ConfidenceByScore(bucket, score or 0)

						local meta = ""
						if bucket == "next" then
							meta = OrdinalLabel((chainStep and chainStep > 0) and chainStep or 1)
						elseif bucket == "progress" then
							meta = ("%d%%"):format(complete)
						elseif bucket == "level" then
							if lo and hi then
								meta = ("%d-%d"):format(lo, hi)
							else
								meta = ("~%d"):format(playerLevel)
							end
						else
							meta = LT("gb_meta_suggested")
						end
						if optShowConfidence then
							meta = meta .. " | " .. (FEATURED_CONFIDENCE_LABELS[confidence] or LT("gb_featured_confidence_good"))
						end
						if #reasons == 0 then AddReason(reasons, LT("gb_meta_recommended")) end
						local reasonRank = {
							["current chain"] = 1,
							["inferred continuation"] = 2,
							["chapter continuation"] = 3,
							["your level range"] = 4,
							["near your level"] = 5,
							["your class"] = 6,
							["your race"] = 7,
							["your profession"] = 8,
							["favorite"] = 9,
							["recently used"] = 10,
							["incomplete"] = 11,
							["recommended"] = 12,
						}
						local ranked = {}
						for _,r in ipairs(reasons) do
							tinsert(ranked, { reason = r, rank = reasonRank[r] or 99 })
						end
						table.sort(ranked, function(a,b)
							if a.rank ~= b.rank then return a.rank < b.rank end
							return a.reason < b.reason
						end)
						local reasonText = (ranked[1] and ranked[1].reason) or LT("gb_meta_recommended")
						if ranked[2] then reasonText = reasonText .. ", " .. ranked[2].reason end
						local context = LT("gb_meta_why_prefix") .. reasonText .. " | " .. LT("gb_meta_gain_prefix") .. gain
						local candidate = {
							bucket = bucket,
							score = score or 0,
							label = label,
							title = title,
							complete = complete,
							meta = meta,
							context = context,
							chainStep = chainStep,
							confidence = confidence,
							gaintype = gainType,
							currentselected = (currentTitle and title == currentTitle) and true or false,
						}
						tinsert(candidates, candidate)
						keptCounts[bucket] = (keptCounts[bucket] or 0) + 1
					end

					if not bucket and optEnableFallback then
						-- Soft fallback pool for empty buckets: keep relevant near-misses.
						local fbucket = nil
						if recentlyCompleted then
							fbucket = "progress"
						end
						if fbucket then
							tinsert(fallbackByBucket[fbucket], {
								bucket = fbucket,
								score = 420,
								label = label,
								title = title,
								complete = complete,
								meta = LT("gb_meta_suggested") .. " | " .. FEATURED_CONFIDENCE_LABELS.fallback,
								context = LT("gb_meta_why_prefix") .. LT("gb_meta_other_useful_option") .. " | " .. LT("gb_meta_gain_prefix") .. gain,
								chainStep = nil,
								confidence = "fallback",
								gaintype = gainType,
								fallback = true,
							})
						end
					end
				end
			end
		end
		if currentTitle and currentTitle ~= "" then
			local curGuide = self.GetGuideByTitle and self:GetGuideByTitle(currentTitle) or nil
			local curLabel = (curGuide and curGuide.title_short) or currentTitle
			local curHay = (curLabel or "") .. " " .. currentTitle
			if includeText(curHay) then
				local curGain = InferGuideGain(curGuide and InferGuideCategory(curGuide, currentTitle, currentTitle) or nil, currentTitle)
				tinsert(candidates, {
					bucket = "next",
					score = 1250,
					label = curLabel,
					title = currentTitle,
					complete = 0,
					meta = LT("gb_meta_current") .. " | " .. FEATURED_CONFIDENCE_LABELS.strong,
					context = LT("gb_meta_why_prefix") .. LT("gb_meta_current_selection") .. " | " .. LT("gb_meta_gain_prefix") .. curGain,
					chainStep = 0,
					confidence = "strong",
					gaintype = ResolveGainType(curGuide and InferGuideCategory(curGuide, currentTitle, currentTitle) or nil, currentTitle),
					currentselected = true,
				})
			end
		end

		do
			local bestByTitle = {}
			for _,c in ipairs(candidates) do
				local prev = bestByTitle[c.title]
				if not prev then
					bestByTitle[c.title] = c
				else
					local po = bucketOrder[prev.bucket] or 99
					local co = bucketOrder[c.bucket] or 99
					if (co < po) or (co == po and (c.score or 0) > (prev.score or 0)) then
						bestByTitle[c.title] = c
					end
				end
			end
			local deduped = {}
			for _,c in pairs(bestByTitle) do tinsert(deduped, c) end
			candidates = deduped
		end
		table.sort(candidates, function(a,b)
			local ao = bucketOrder[a.bucket] or 99
			local bo = bucketOrder[b.bucket] or 99
			if ao ~= bo then return ao < bo end
			if a.score ~= b.score then return a.score > b.score end
			return strlower(a.label or a.title or "") < strlower(b.label or b.title or "")
		end)
		for _,b in ipairs(FEATURED_BUCKET_ORDER) do
			if (keptCounts[b] or 0) == 0 and fallbackByBucket[b] and #fallbackByBucket[b] > 0 then
				local addn = 0
				for _,fc in ipairs(fallbackByBucket[b]) do
					if not IsSnoozed(fc.title) then
						tinsert(candidates, fc)
						addn = addn + 1
						if addn >= 3 then break end
					end
				end
			end
		end

		local seenTitle = {}
		local added = 0
		for _,c in ipairs(candidates) do
			if not seenTitle[c.title] then
				seenTitle[c.title] = true
				tinsert(rows, {
					kind = "guide",
					depth = 0,
					label = c.label,
					title = c.title,
					meta = c.meta,
					context = c.context,
					featuredbucket = c.bucket,
					chainStep = c.chainStep,
					confidence = c.confidence,
					gaintype = c.gaintype,
					fallback = c.fallback,
					currentselected = c.currentselected,
				})
				added = added + 1
				if added >= 24 then break end
			end
		end
		if #rows == 0 then
			tinsert(rows, { kind = "header", depth = 0, label = LT("gb_empty_no_featured_match") })
			tinsert(rows, { kind = "action", depth = 0, label = LT("gb_action_clear_search"), action = "clear_search" })
			if (featuredSnooze and next(featuredSnooze)) or (featuredSessionHide and next(featuredSessionHide)) or (legacyHiddenFeatured and next(legacyHiddenFeatured)) then
				tinsert(rows, { kind = "action", depth = 0, label = LT("gb_action_reset_snoozed"), action = "reset_hidden_featured" })
			end
		end
	end

	return rows
end

local function BuildCurrentSectionRows(self, searchText)
	local rows = {}
	local g = self.CurrentGuide
	if not (g and g.title and g.title ~= "") then
		tinsert(rows, { kind = "header", depth = 0, label = LT("gb_empty_no_current_guide_short") })
		return rows
	end

	local root = self:BuildGuideBrowserTree()
	if not root then return rows end

	local parts = SplitGuideTitle(g.title)
	if #parts < 2 then
		tinsert(rows, { kind = "guide", depth = 0, label = g.title_short or g.title, title = g.title })
		return rows
	end

	local parentParts = {}
	for i = 1, #parts - 1 do tinsert(parentParts, parts[i]) end
	local parentPath = PathToString(parentParts)
	local node = GetNodeByPath(root, parentParts)
	if not node then
		tinsert(rows, { kind = "guide", depth = 0, label = g.title_short or g.title, title = g.title })
		return rows
	end

	self.db.profile.guidebrowsertreeexpanded = self.db.profile.guidebrowsertreeexpanded or {}
	local expanded = self.db.profile.guidebrowsertreeexpanded
	local needle = strlower((searchText or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	local inSearch = (needle ~= "")

	local function GuideMatches(entry, prefix)
		local leaf = entry.leaf or entry.title or ""
		local title = entry.title or ""
		local full = (prefix ~= "" and (prefix .. "\\" .. leaf)) or leaf
		local hay = strlower(full .. " " .. title)
		if needle ~= "" and not strfind(hay, needle, 1, true) then return false end
		return true
	end

	local function NodeHasMatches(curNode, prefix)
		for _,name in ipairs(curNode.child_order or {}) do
			local child = curNode.children and curNode.children[name]
			local nextPrefix = (prefix ~= "" and (prefix .. "\\" .. name)) or name
			if child and NodeHasMatches(child, nextPrefix) then return true end
		end
		for _,entry in ipairs(curNode.guides or {}) do
			if GuideMatches(entry, prefix) then return true end
		end
		return false
	end

	local function AddNode(curNode, depth, basePath)
		for _,name in ipairs(curNode.child_order or {}) do
			local child = curNode.children and curNode.children[name]
			local path = (basePath ~= "" and (basePath .. "\\" .. name)) or name
			if child and NodeHasMatches(child, path) then
				local open = (inSearch and true) or (expanded[path] and true or false)
				tinsert(rows, { kind = "folder", depth = depth, label = name, path = path, open = open })
				if open then AddNode(child, depth + 1, path) end
			end
		end
		for _,entry in ipairs(curNode.guides or {}) do
			if GuideMatches(entry, basePath) then
				tinsert(rows, { kind = "guide", depth = depth, label = entry.leaf or entry.title, title = entry.title })
			end
		end
	end

	tinsert(rows, { kind = "header", depth = 0, label = parentPath })
	AddNode(node, 0, parentPath)
	return rows
end

local RETAIL_UI_FONT = ZGV.DIR.."\\Skins\\segoeui.ttf"
local RETAIL_UI_FONT_BOLD = ZGV.DIR.."\\Skins\\segoeuib.ttf"
local RETAIL_GUIDE_ICONS_BIG = ZGV.DIR.."\\Skins\\guideicons-big"
local RETAIL_MENU_IMAGE_FALLBACK = ZGV.DIR.."\\Skins\\menu_noimage"
local RETAIL_TITLEBUTTONS_TEXTURE = ZGV.DIR.."\\Skins\\Default\\Stealth\\titlebuttons.tga"

local function GetTitleButtonsTexCoord(n, stateRow)
	local count = 8
	local rows = 4
	local idx = math.max(1, math.min(count, tonumber(n) or 1))
	local row = math.max(1, math.min(rows, tonumber(stateRow) or 1))
	local l = (idx - 1) / count
	local r = idx / count
	local t = (row - 1) / rows
	local b = row / rows
	return l, r, t, b
end

-- Stealth titlebuttons (512x128) are effectively a 16x2 atlas, with glyphs in
-- the top half of each 32x64 cell. This returns that visible top-half region.
local function GetStealthTopHalfIconTexCoord(n)
	local cols,rows = 16,2
	local idx = math.max(1, math.min(cols * rows, tonumber(n) or 1))
	local i = idx - 1
	local col = i % cols
	local row = math.floor(i / cols)
	local l = col / cols
	local r = (col + 1) / cols
	local t = row / rows
	local b = t + (1 / (rows * 2))
	return l,r,t,b
end

local function ApplyRetailFont(fs, size, flags, bold)
	if not fs or not fs.SetFont then return end
	local font = bold and RETAIL_UI_FONT_BOLD or RETAIL_UI_FONT
	if font and font ~= "" then
		local ok = pcall(function() fs:SetFont(font, size or 13, flags or "") end)
		if not ok and fs.SetFontObject then
			fs:SetFontObject(GameFontHighlight)
		end
	end
end

local function ApplyTitleButtonIcon(button, iconN, fallbackText, rotate90)
	if not button then return end
	if not button:GetNormalTexture() then button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2") end
	if not button:GetPushedTexture() then button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot2") end
	if not button:GetHighlightTexture() then button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD") end
	local l1,r1,t1,b1 = GetTitleButtonsTexCoord(iconN, 1)
	local l2,r2,t2,b2 = GetTitleButtonsTexCoord(iconN, 2)
	local l3,r3,t3,b3 = GetTitleButtonsTexCoord(iconN, 3)
	local l4,r4,t4,b4 = GetTitleButtonsTexCoord(iconN, 4)
	local nt = button:GetNormalTexture()
	nt:SetTexture(RETAIL_TITLEBUTTONS_TEXTURE)
	nt:SetTexCoord(l1,r1,t1,b1)
	nt:SetVertexColor(0.88, 0.88, 0.90, 0.95)
	if rotate90 and nt.SetRotation then nt:SetRotation(1.57079633) end
	local pt = button:GetPushedTexture()
	pt:SetTexture(RETAIL_TITLEBUTTONS_TEXTURE)
	pt:SetTexCoord(l2,r2,t2,b2)
	pt:SetVertexColor(0.72, 0.72, 0.75, 0.95)
	if rotate90 and pt.SetRotation then pt:SetRotation(1.57079633) end
	local ht = button:GetHighlightTexture()
	if ht then
		ht:SetTexture(RETAIL_TITLEBUTTONS_TEXTURE)
		ht:SetTexCoord(l3,r3,t3,b3)
		if rotate90 and ht.SetRotation then ht:SetRotation(1.57079633) end
		ht:SetVertexColor(1, 1, 1, 0.25)
	end
	if not button:GetDisabledTexture() then button:SetDisabledTexture(RETAIL_TITLEBUTTONS_TEXTURE) end
	local dt = button:GetDisabledTexture()
	if dt then
		dt:SetTexture(RETAIL_TITLEBUTTONS_TEXTURE)
		dt:SetTexCoord(l4,r4,t4,b4)
		dt:SetVertexColor(0.55, 0.55, 0.58, 0.95)
		if rotate90 and dt.SetRotation then dt:SetRotation(1.57079633) end
	end
	if button.text then
		button.text:SetText(fallbackText or "")
		button.text:Hide()
	end
end

local GUIDE_HERO_IMAGE_DIR = ZGV.DIR.."\\Skins\\GuideImages\\"
local GUIDE_HERO_CATEGORY_DEFAULTS = {
	leveling = GUIDE_HERO_IMAGE_DIR .. "elwynn.blp",
	dungeons = GUIDE_HERO_IMAGE_DIR .. "icecrown.blp",
	daily = GUIDE_HERO_IMAGE_DIR .. "tanaris.blp",
	events = GUIDE_HERO_IMAGE_DIR .. "tanaris.blp",
	reputations = GUIDE_HERO_IMAGE_DIR .. "terokkar.blp",
	gold = GUIDE_HERO_IMAGE_DIR .. "stranglethorn.blp",
	professions = GUIDE_HERO_IMAGE_DIR .. "nagrand.blp",
	petsmounts = GUIDE_HERO_IMAGE_DIR .. "grizzlyhills.blp",
	titles = GUIDE_HERO_IMAGE_DIR .. "stormpeaks.blp",
	achievements = GUIDE_HERO_IMAGE_DIR .. "dragonblight.blp",
	misc = GUIDE_HERO_IMAGE_DIR .. "hinterlands.blp",
	favorites = GUIDE_HERO_IMAGE_DIR .. "stormpeaks.blp",
}
local GUIDE_HERO_SECTION_DEFAULTS = {
	home = GUIDE_HERO_IMAGE_DIR .. "elwynn.blp",
	featured = GUIDE_HERO_IMAGE_DIR .. "dragonblight.blp",
	current = GUIDE_HERO_IMAGE_DIR .. "howling.blp",
	recent = GUIDE_HERO_IMAGE_DIR .. "borean.blp",
	options = ZGV.DIR.."\\Skins\\menu_mascot-classic",
}
local GUIDE_HERO_GLOBAL_DEFAULT = GUIDE_HERO_IMAGE_DIR .. "elwynn.blp"
local GUIDE_HERO_KEYWORDS = {
	{ "northrend", "howling" },
	{ "outland", "hellfire" },
	{ "eastern kingdoms", "elwynn" },
	{ "kalimdor", "ashenvale" },
	{ "alliance leveling guides", "elwynn" },
	{ "horde leveling guides", "stranglethorn" },
	{ "dungeon", "icecrown" },
	{ "dungeons", "icecrown" },
	{ "daily", "tanaris" },
	{ "dailies", "tanaris" },
	{ "event", "tanaris" },
	{ "events", "tanaris" },
	{ "reputation", "terokkar" },
	{ "reputations", "terokkar" },
	{ "profession", "nagrand" },
	{ "professions", "nagrand" },
	{ "achievement", "dragonblight" },
	{ "achievements", "dragonblight" },
	{ "pet", "grizzlyhills" },
	{ "pets", "grizzlyhills" },
	{ "mount", "grizzlyhills" },
	{ "mounts", "grizzlyhills" },
	{ "title", "stormpeaks" },
	{ "titles", "stormpeaks" },
	{ "gold", "stranglethorn" },
	{ "farm", "stranglethorn" },
	{ "farming", "stranglethorn" },
	{ "misc", "hinterlands" },
	{ "dragonblight", "dragonblight" },
	{ "howling fjord", "howling" },
	{ "borean", "borean" },
	{ "grizzly hills", "grizzlyhills" },
	{ "sholazar", "sholazar" },
	{ "storm peaks", "stormpeaks" },
	{ "icecrown", "icecrown" },
	{ "zuldrak", "zuldrak" },
	{ "terokkar", "terokkar" },
	{ "hellfire", "hellfire" },
	{ "zangarmarsh", "zangarmarsh" },
	{ "nagrand", "nagrand" },
	{ "netherstorm", "netherstorm" },
	{ "shadowmoon", "shadowmoon" },
	{ "blade's edge", "bladesedge" },
	{ "blades edge", "bladesedge" },
	{ "elwynn", "elwynn" },
	{ "westfall", "westfall" },
	{ "redridge", "redridge" },
	{ "duskwood", "duskwood" },
	{ "loch modan", "lochmodan" },
	{ "wetlands", "wetlands" },
	{ "arathi", "arathi" },
	{ "hinterlands", "hinterlands" },
	{ "stranglethorn", "stranglethorn" },
	{ "tanaris", "tanaris" },
	{ "silithus", "silithus" },
	{ "winterspring", "winterspring" },
	{ "ashenvale", "ashenvale" },
	{ "desolace", "desolace" },
	{ "felwood", "felwood" },
	{ "feralas", "feralas" },
	{ "badlands", "badlands" },
	{ "burning steppes", "burningsteppes" },
	{ "swamp of sorrows", "swampofsorrows" },
}

local function ResolveGuideHeroFallback(category, section)
	local cat = NormalizeGuideCategory(category or "")
	if cat and GUIDE_HERO_CATEGORY_DEFAULTS[cat] then
		return GUIDE_HERO_CATEGORY_DEFAULTS[cat]
	end
	if category and GUIDE_HERO_CATEGORY_DEFAULTS[category] then
		return GUIDE_HERO_CATEGORY_DEFAULTS[category]
	end
	if section and GUIDE_HERO_SECTION_DEFAULTS[section] then
		return GUIDE_HERO_SECTION_DEFAULTS[section]
	end
	return GUIDE_HERO_GLOBAL_DEFAULT
end

local function ResolveGuideHeroImageFromText(text, category, section, strictOnly)
	local hay = strlower(text or "")
	for _,entry in ipairs(GUIDE_HERO_KEYWORDS) do
		if strfind(hay, entry[1], 1, true) then
			return GUIDE_HERO_IMAGE_DIR .. entry[2] .. ".blp"
		end
	end
	if strictOnly then return nil end
	return ResolveGuideHeroFallback(category, section)
end

local function ResolveGuideDominantMapImage(guide)
	if not guide then return nil end
	local key = guide.title or tostring(guide)
	ZGV._guideHeroMapCache = ZGV._guideHeroMapCache or {}
	if ZGV._guideHeroMapCache[key] ~= nil then
		return ZGV._guideHeroMapCache[key] or nil
	end

	local weights = {}
	local function Bump(mapName, amount)
		if not mapName or mapName == "" then return end
		local m = tostring(mapName)
		weights[m] = (weights[m] or 0) + (amount or 1)
	end

	for _,step in ipairs(guide.steps or {}) do
		Bump(step.map, 3)
		for _,goal in ipairs(step.goals or {}) do
			Bump(goal.map, (goal.action == "goto") and 3 or 2)
		end
	end

	local bestMap, bestWeight
	for mapName, weight in pairs(weights) do
		if (not bestWeight) or weight > bestWeight then
			bestMap, bestWeight = mapName, weight
		end
	end

	local image = bestMap and ResolveGuideHeroImageFromText(bestMap, nil, nil, true) or nil
	ZGV._guideHeroMapCache[key] = image or false
	return image
end

local function ResolveGuideHeroImage(guide, category, section)
	if not guide then return ResolveGuideHeroFallback(category, section) end
	local mapImage = ResolveGuideDominantMapImage(guide)
	if mapImage then return mapImage end

	local full = (guide.title or "") .. " " .. (guide.title_short or "")
	local image = ResolveGuideHeroImageFromText(full, nil, nil, true)
	if image then return image end

	local hay = strlower(full)
	if strfind(hay, "northrend", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "howling.blp" end
	if strfind(hay, "outland", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "hellfire.blp" end
	if strfind(hay, "human", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "elwynn.blp" end
	if strfind(hay, "night elf", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "ashenvale.blp" end
	if strfind(hay, "gnome", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "lochmodan.blp" end
	if strfind(hay, "dwarf", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "wetlands.blp" end
	if strfind(hay, "draenei", 1, true) then return GUIDE_HERO_IMAGE_DIR .. "terokkar.blp" end

	if strfind(hay, "leveling guides", 1, true) or strfind(hay, "levels (", 1, true) then
		local lo, hi = full:match("%((%d+)%-(%d+)%)")
		lo = tonumber(lo or 0) or 0
		hi = tonumber(hi or 0) or 0
		if hi >= 68 then return GUIDE_HERO_IMAGE_DIR .. "borean.blp" end
		if hi >= 60 then return GUIDE_HERO_IMAGE_DIR .. "hellfire.blp" end
		if hi >= 50 then return GUIDE_HERO_IMAGE_DIR .. "burningsteppes.blp" end
		if hi >= 40 then return GUIDE_HERO_IMAGE_DIR .. "tanaris.blp" end
		if hi >= 30 then return GUIDE_HERO_IMAGE_DIR .. "stranglethorn.blp" end
		if hi >= 20 then return GUIDE_HERO_IMAGE_DIR .. "duskwood.blp" end
		return GUIDE_HERO_IMAGE_DIR .. "elwynn.blp"
	end

	local inferred = InferGuideCategory(guide, guide.title or "", guide.title or "")
	if inferred == "achievements" then return ZGV.DIR.."\\Skins\\menu_mascot-classic" end
	if inferred == "reputations" then return ZGV.DIR.."\\Skins\\menu_mascot-classic" end
	if inferred == "professions" then return ZGV.DIR.."\\Skins\\menu_mascot-classic" end
	if inferred == "dungeons" then return ZGV.DIR.."\\Skins\\menu_mascot-cata" end
	if inferred == "events" or inferred == "daily" then return ZGV.DIR.."\\Skins\\menu_mascot" end
	return ResolveGuideHeroFallback(inferred or category, section)
end

local function EnsureGuideManagerStandaloneFrame(self)
	if self.GuideManagerStandaloneFrame then return self.GuideManagerStandaloneFrame end

	local frame = CreateFrame("Frame", "ZGVGuideManagerFrame", UIParent, "UIPanelDialogTemplate")
	frame:SetWidth(1144)
	frame:SetHeight(760)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
	frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
	frame:Hide()
	tinsert(UISpecialFrames, "ZGVGuideManagerFrame")

	local titleObj = _G[frame:GetName() .. "Title"]
	if titleObj and titleObj.SetText then
		titleObj:SetText(LT("gb_addon_title"))
	end
	if titleObj then
		titleObj:SetTextColor(0.87, 0.89, 0.93)
		ApplyRetailFont(titleObj, 22, "", true)
	end

	local chromeBg = frame:CreateTexture(nil, "BACKGROUND")
	chromeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	chromeBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -26)
	chromeBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
	chromeBg:SetVertexColor(0.04, 0.045, 0.06, 0.86)

	local chromeArt = frame:CreateTexture(nil, "BORDER")
	chromeArt:SetTexture(RETAIL_MENU_IMAGE_FALLBACK)
	chromeArt:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -26)
	chromeArt:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
	chromeArt:SetVertexColor(0.25, 0.25, 0.25, 0.22)

	local tabBar = CreateFrame("Frame", nil, frame)
	tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -34)
	tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -34)
	tabBar:SetHeight(28)
	frame.tabBar = tabBar

	local left = CreateFrame("Frame", nil, frame)
	left:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -10)
	left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
	left:SetWidth(250)
	left:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	left:SetBackdropColor(0.09, 0.095, 0.11, 0.94)
	left:SetBackdropBorderColor(0.24, 0.24, 0.28, 0.96)
	frame.leftPane = left

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", left, "TOPRIGHT", 10, 0)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
	content:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	content:SetBackdropColor(0.07, 0.075, 0.09, 0.94)
	content:SetBackdropBorderColor(0.24, 0.24, 0.28, 0.96)
	frame.contentPane = content

	local center = CreateFrame("Frame", nil, content)
	center:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
	center:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 10)
	center:SetWidth(560)
	frame.centerPane = center

	local details = CreateFrame("Frame", nil, content)
	details:SetPoint("TOPLEFT", center, "TOPRIGHT", 8, 0)
	details:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
	details:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	details:SetBackdropColor(0.11, 0.115, 0.13, 0.95)
	details:SetBackdropBorderColor(0.26, 0.26, 0.30, 0.96)
	frame.details = details

	local optionsPane = CreateFrame("Frame", nil, content)
	optionsPane:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
	optionsPane:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
	optionsPane:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	optionsPane:SetBackdropColor(0.08, 0.085, 0.10, 0.96)
	optionsPane:SetBackdropBorderColor(0.24, 0.24, 0.28, 0.96)
	if optionsPane.SetClipsChildren then
		optionsPane:SetClipsChildren(true)
	end
	optionsPane:Hide()
	frame.optionsPane = optionsPane

	local optionsTitle = optionsPane:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	optionsTitle:SetPoint("TOPLEFT", optionsPane, "TOPLEFT", 10, -10)
	optionsTitle:SetText(LT("gb_tab_options"))
	ApplyRetailFont(optionsTitle, 20, "", true)
	frame.optionsTitle = optionsTitle

	local optionsBreadcrumb = optionsPane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	optionsBreadcrumb:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -2)
	optionsBreadcrumb:SetPoint("TOPRIGHT", optionsPane, "TOPRIGHT", -10, -12)
	optionsBreadcrumb:SetJustifyH("LEFT")
	optionsBreadcrumb:SetText("")
	ApplyRetailFont(optionsBreadcrumb, 12, "", false)
	optionsBreadcrumb:Hide()
	frame.optionsBreadcrumb = optionsBreadcrumb

	local optionsHeaderLine = optionsPane:CreateTexture(nil, "BORDER")
	optionsHeaderLine:SetTexture("Interface\\Buttons\\WHITE8x8")
	optionsHeaderLine:SetVertexColor(0.30, 0.30, 0.30, 0.85)
	optionsHeaderLine:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -10)
	optionsHeaderLine:SetPoint("TOPRIGHT", optionsPane, "TOPRIGHT", -10, -6)
	optionsHeaderLine:SetHeight(1)
	frame.optionsHeaderLine = optionsHeaderLine

	local optionsInfo = optionsPane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	optionsInfo:SetPoint("TOPLEFT", optionsHeaderLine, "BOTTOMLEFT", 0, -8)
	optionsInfo:SetPoint("TOPRIGHT", optionsPane, "TOPRIGHT", -10, -8)
	optionsInfo:SetJustifyH("LEFT")
	optionsInfo:SetWordWrap(true)
	optionsInfo:SetNonSpaceWrap(true)
	optionsInfo:SetText("")
	ApplyRetailFont(optionsInfo, 12, "", false)
	optionsInfo:Hide()
	frame.optionsInfo = optionsInfo

	local optionsContent = CreateFrame("Frame", nil, optionsPane)
	optionsContent:SetPoint("TOPLEFT", optionsHeaderLine, "BOTTOMLEFT", 0, -10)
	optionsContent:SetPoint("BOTTOMRIGHT", optionsPane, "BOTTOMRIGHT", -236, 40)
	optionsContent:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	optionsContent:SetBackdropColor(0.08, 0.08, 0.08, 0.92)
	optionsContent:SetBackdropBorderColor(0.26, 0.26, 0.26, 0.92)
	if optionsContent.SetClipsChildren then
		optionsContent:SetClipsChildren(true)
	end
	frame.optionsContent = optionsContent

	local optionsDetail = CreateFrame("Frame", nil, optionsPane)
	optionsDetail:SetPoint("TOPLEFT", optionsContent, "TOPRIGHT", 8, 0)
	optionsDetail:SetPoint("BOTTOMRIGHT", optionsPane, "BOTTOMRIGHT", -2, 40)
	optionsDetail:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	optionsDetail:SetBackdropColor(0.13, 0.13, 0.13, 0.94)
	optionsDetail:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.94)
	frame.optionsDetail = optionsDetail

	local optionsDetailTitle = optionsDetail:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	optionsDetailTitle:SetPoint("TOPLEFT", optionsDetail, "TOPLEFT", 10, -10)
	optionsDetailTitle:SetPoint("TOPRIGHT", optionsDetail, "TOPRIGHT", -10, -10)
	optionsDetailTitle:SetJustifyH("LEFT")
	optionsDetailTitle:SetText(LT("gb_title_viewer"))
	ApplyRetailFont(optionsDetailTitle, 14, "", true)
	frame.optionsDetailTitle = optionsDetailTitle

	local optionsDetailBody = optionsDetail:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	optionsDetailBody:SetPoint("TOPLEFT", optionsDetailTitle, "BOTTOMLEFT", 0, -6)
	optionsDetailBody:SetJustifyH("LEFT")
	optionsDetailBody:SetJustifyV("TOP")
	optionsDetailBody:SetWidth(218)
	optionsDetailBody:SetWordWrap(true)
	optionsDetailBody:SetNonSpaceWrap(true)
	optionsDetailBody:SetText(LT("gb_options_viewer_desc"))
	ApplyRetailFont(optionsDetailBody, 12, "", false)
	frame.optionsDetailBody = optionsDetailBody

	local optionsDetailHintLine = optionsDetail:CreateTexture(nil, "BORDER")
	optionsDetailHintLine:SetTexture("Interface\\Buttons\\WHITE8x8")
	optionsDetailHintLine:SetVertexColor(0.26, 0.26, 0.26, 0.80)
	optionsDetailHintLine:SetPoint("TOPLEFT", optionsDetailBody, "BOTTOMLEFT", 0, -8)
	optionsDetailHintLine:SetPoint("TOPRIGHT", optionsDetail, "TOPRIGHT", -10, -8)
	optionsDetailHintLine:SetHeight(1)

	local optionsDetailHint = optionsDetail:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	optionsDetailHint:SetPoint("TOPLEFT", optionsDetailHintLine, "BOTTOMLEFT", 0, -8)
	optionsDetailHint:SetJustifyH("LEFT")
	optionsDetailHint:SetJustifyV("TOP")
	optionsDetailHint:SetWidth(218)
	optionsDetailHint:SetWordWrap(true)
	optionsDetailHint:SetNonSpaceWrap(true)
	optionsDetailHint:SetText(LT("gb_hint_search_settings"))
	ApplyRetailFont(optionsDetailHint, 12, "", false)
	frame.optionsDetailHint = optionsDetailHint

	local optionsFooterLine = optionsPane:CreateTexture(nil, "BORDER")
	optionsFooterLine:SetTexture("Interface\\Buttons\\WHITE8x8")
	optionsFooterLine:SetVertexColor(0.30, 0.30, 0.30, 0.85)
	optionsFooterLine:SetPoint("BOTTOMLEFT", optionsPane, "BOTTOMLEFT", 10, 36)
	optionsFooterLine:SetPoint("BOTTOMRIGHT", optionsPane, "BOTTOMRIGHT", -10, 36)
	optionsFooterLine:SetHeight(1)
	frame.optionsFooterLine = optionsFooterLine

	local optionsFooter = CreateFrame("Frame", nil, optionsPane)
	optionsFooter:SetPoint("BOTTOMLEFT", optionsPane, "BOTTOMLEFT", 10, 6)
	optionsFooter:SetPoint("BOTTOMRIGHT", optionsPane, "BOTTOMRIGHT", -10, 32)
	frame.optionsFooter = optionsFooter

	local optionsBackButton = CreateFrame("Button", nil, optionsFooter, "UIPanelButtonTemplate")
	optionsBackButton:SetSize(120, 22)
	optionsBackButton:SetPoint("LEFT", optionsFooter, "LEFT", 0, 0)
	optionsBackButton:SetText(LT("gb_action_back_to_guides"))
	optionsBackButton:SetScript("OnClick", function()
		self:SelectGuideManagerSection("home")
	end)
	frame.optionsBackButton = optionsBackButton

	local optionsFullButton = CreateFrame("Button", nil, optionsFooter, "UIPanelButtonTemplate")
	optionsFullButton:SetSize(120, 22)
	optionsFullButton:SetPoint("RIGHT", optionsFooter, "RIGHT", 0, 0)
	optionsFullButton:SetText(LT("gb_action_open_full_options"))
	optionsFullButton:SetScript("OnClick", function()
		self:OpenOptions()
	end)
	frame.optionsFullButton = optionsFullButton

	local optionsFallback = optionsPane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	optionsFallback:SetPoint("TOPLEFT", optionsContent, "TOPLEFT", 8, -8)
	optionsFallback:SetPoint("TOPRIGHT", optionsContent, "TOPRIGHT", -8, -8)
	optionsFallback:SetJustifyH("LEFT")
	optionsFallback:SetJustifyV("TOP")
	optionsFallback:SetText("")
	optionsFallback:Hide()
	frame.optionsFallback = optionsFallback

	local centerHeader = CreateFrame("Frame", nil, center)
	centerHeader:SetPoint("TOPLEFT", center, "TOPLEFT", 4, -4)
	centerHeader:SetPoint("TOPRIGHT", center, "TOPRIGHT", -4, -4)
	centerHeader:SetHeight(24)
	frame.centerHeader = centerHeader

	local headerBack = CreateFrame("Button", nil, centerHeader)
	headerBack:SetPoint("LEFT", centerHeader, "LEFT", 2, 0)
	headerBack:SetSize(18, 18)
	headerBack:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	headerBack:SetPushedTexture("Interface\\Buttons\\WHITE8x8")
	headerBack:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
	headerBack:SetDisabledTexture("Interface\\Buttons\\WHITE8x8")
	if headerBack:GetNormalTexture() then headerBack:GetNormalTexture():SetVertexColor(1,1,1,0) end
	if headerBack:GetPushedTexture() then headerBack:GetPushedTexture():SetVertexColor(1,1,1,0) end
	if headerBack:GetHighlightTexture() then headerBack:GetHighlightTexture():SetVertexColor(1,1,1,0.05) end
	if headerBack:GetDisabledTexture() then headerBack:GetDisabledTexture():SetVertexColor(1,1,1,0) end
	headerBack.glyph = headerBack:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	headerBack.glyph:SetPoint("CENTER", headerBack, "CENTER", 0, 0)
	headerBack.glyph:SetText("\226\134\144") -- UTF-8 left arrow
	ApplyRetailFont(headerBack.glyph, 17, "", false)
	headerBack.glyph:SetTextColor(0.88,0.88,0.90,0.95)
	headerBack:SetScript("OnMouseDown", function(btn)
		if btn.glyph then btn.glyph:SetTextColor(0.72,0.72,0.75,0.95) end
	end)
	headerBack:SetScript("OnMouseUp", function(btn)
		if btn.glyph then btn.glyph:SetTextColor(0.88,0.88,0.90,0.95) end
	end)
	headerBack:SetScript("OnEnter", function(btn)
		if btn.glyph then btn.glyph:SetTextColor(1,1,1,0.98) end
	end)
	headerBack:SetScript("OnLeave", function(btn)
		if btn.glyph then btn.glyph:SetTextColor(0.88,0.88,0.90,0.95) end
	end)
	headerBack:Hide()
	frame.centerHeaderBack = headerBack

	local sectionTitle = centerHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	sectionTitle:SetPoint("LEFT", headerBack, "RIGHT", 4, 0)
	sectionTitle:SetPoint("RIGHT", centerHeader, "RIGHT", -20, 0)
	sectionTitle:SetJustifyH("LEFT")
	sectionTitle:SetText(LT("gb_select_guide"))
	ApplyRetailFont(sectionTitle, 15, "", true)
	frame.sectionTitle = sectionTitle

	local headerMenu = CreateFrame("Button", nil, centerHeader)
	headerMenu:SetPoint("RIGHT", centerHeader, "RIGHT", -2, 0)
	headerMenu:SetSize(14, 14)
	headerMenu:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	headerMenu:SetPushedTexture("Interface\\Buttons\\WHITE8x8")
	headerMenu:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	if headerMenu:GetNormalTexture() then
		headerMenu:GetNormalTexture():SetVertexColor(1, 1, 1, 0.0)
	end
	if headerMenu:GetPushedTexture() then
		headerMenu:GetPushedTexture():SetVertexColor(1, 1, 1, 0.08)
	end
	local function TintMenuDots(r, g, b, a)
		for i = 1, 3 do
			local dot = headerMenu["dot"..i]
			if dot then dot:SetVertexColor(r, g, b, a) end
		end
	end
	for i = 1, 3 do
		local dot = headerMenu:CreateTexture(nil, "ARTWORK")
		dot:SetTexture("Interface\\Buttons\\WHITE8x8")
		dot:SetSize(2, 2)
		dot:SetPoint("CENTER", headerMenu, "CENTER", 0, 4 - ((i - 1) * 4))
		headerMenu["dot"..i] = dot
	end
	TintMenuDots(0.88, 0.88, 0.90, 0.95)
	headerMenu:SetScript("OnMouseDown", function() TintMenuDots(0.72, 0.72, 0.75, 0.95) end)
	headerMenu:SetScript("OnMouseUp", function() TintMenuDots(0.88, 0.88, 0.90, 0.95) end)
	headerMenu:SetScript("OnEnter", function() TintMenuDots(1, 1, 1, 0.95) end)
	headerMenu:SetScript("OnLeave", function() TintMenuDots(0.88, 0.88, 0.90, 0.95) end)
	frame.centerHeaderMenu = headerMenu
	local headerMenuDrop = CreateFrame("Frame", "ZGVGuideManagerHeaderMenuDrop", frame, "UIDropDownMenuTemplate")
	headerBack:SetScript("OnClick", function()
		local panel = frame.treePanel
		if not panel then return end
		local parts = StringToPath(panel.browsePath or "")
		if #parts > 0 then
			tremove(parts)
			panel.browsePath = PathToString(parts)
			if self.db and self.db.profile then self.db.profile.guidebrowserpath = panel.browsePath end
			self:RefreshGuideManagerPanel(panel)
			if frame.UpdateCenterHeader then frame:UpdateCenterHeader() end
		end
	end)
	headerMenu:SetScript("OnClick", function(btn)
		local panel = frame.treePanel
		if not panel then return end
		local menu = {
			{ text = LT("gb_nav_navigation"), isTitle = true, notCheckable = true },
			{
				text = LT("gb_nav_back"),
				notCheckable = true,
				disabled = ((panel.browsePath or "") == ""),
				func = function()
					local parts = StringToPath(panel.browsePath or "")
					if #parts > 0 then
						tremove(parts)
						panel.browsePath = PathToString(parts)
						if self.db and self.db.profile then self.db.profile.guidebrowserpath = panel.browsePath end
						self:RefreshGuideManagerPanel(panel)
						if frame.UpdateCenterHeader then frame:UpdateCenterHeader() end
					end
				end,
			},
			{
				text = LT("gb_nav_reset_to_root"),
				notCheckable = true,
				func = function()
					panel.browsePath = ""
					if self.db and self.db.profile then self.db.profile.guidebrowserpath = "" end
					self:RefreshGuideManagerPanel(panel)
					if frame.UpdateCenterHeader then frame:UpdateCenterHeader() end
				end,
			},
			{
				text = LT("gb_action_go_current_folder"),
				notCheckable = true,
				disabled = not (self.CurrentGuide and self.CurrentGuide.title),
				func = function()
					local title = self.CurrentGuide and self.CurrentGuide.title
					if not title then return end
					local parts = SplitGuideTitle(title)
					if #parts > 1 then
						tremove(parts) -- strip guide leaf
						panel.browsePath = PathToString(parts)
					else
						panel.browsePath = ""
					end
					if self.db and self.db.profile then self.db.profile.guidebrowserpath = panel.browsePath end
					self:RefreshGuideManagerPanel(panel)
					if frame.UpdateCenterHeader then frame:UpdateCenterHeader() end
				end,
			},
		}
		EasyMenu(menu, headerMenuDrop, btn, 0, 0, "MENU")
	end)

	local headerLine = centerHeader:CreateTexture(nil, "BORDER")
	headerLine:SetTexture("Interface\\Buttons\\WHITE8x8")
	headerLine:SetVertexColor(0.30, 0.30, 0.30, 0.85)
	headerLine:SetPoint("TOPLEFT", centerHeader, "BOTTOMLEFT", 0, -2)
	headerLine:SetPoint("TOPRIGHT", centerHeader, "BOTTOMRIGHT", 0, -2)
	headerLine:SetHeight(1)
	frame.centerHeaderLine = headerLine

	local infoText = center:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	infoText:SetText("")
	infoText:Hide()
	frame.infoText = infoText

	local leftSearchLabel = left:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	leftSearchLabel:SetPoint("TOPLEFT", left, "TOPLEFT", 10, -12)
	leftSearchLabel:SetText(LT("gb_search"))
	ApplyRetailFont(leftSearchLabel, 13, "", true)

	local leftOptionsTitle = left:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	leftOptionsTitle:SetPoint("TOPLEFT", left, "TOPLEFT", 10, -12)
	leftOptionsTitle:SetText("|cffdfe3eb" .. LT("gb_tab_options") .. "|r")
	ApplyRetailFont(leftOptionsTitle, 14, "", true)
	leftOptionsTitle:Hide()

	local leftOptionsHint = left:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	leftOptionsHint:SetPoint("TOPLEFT", leftOptionsTitle, "BOTTOMLEFT", 0, -2)
	leftOptionsHint:SetPoint("TOPRIGHT", left, "TOPRIGHT", -10, -14)
	leftOptionsHint:SetJustifyH("LEFT")
	leftOptionsHint:SetText(LT("gb_select_settings_page"))
	ApplyRetailFont(leftOptionsHint, 12, "", false)
	leftOptionsHint:Hide()

	local leftOptionsPanel = CreateFrame("Frame", nil, left)
	leftOptionsPanel:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -54)
	leftOptionsPanel:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -8, 42)
	leftOptionsPanel:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	leftOptionsPanel:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
	leftOptionsPanel:SetBackdropBorderColor(0.26, 0.26, 0.26, 0.90)
	leftOptionsPanel:Hide()
	frame.leftOptionsPanel = leftOptionsPanel

	local optionsSearchLabel = leftOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	optionsSearchLabel:SetPoint("TOPLEFT", leftOptionsPanel, "TOPLEFT", 8, -8)
	optionsSearchLabel:SetText(LT("gb_search"))
	optionsSearchLabel:Hide()
	frame.optionsSearchLabel = optionsSearchLabel

	local optionsSearchBox = CreateFrame("Frame", nil, leftOptionsPanel)
	optionsSearchBox:SetPoint("TOPLEFT", optionsSearchLabel, "BOTTOMLEFT", -2, -2)
	optionsSearchBox:SetSize(224, 22)
	optionsSearchBox:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	optionsSearchBox:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
	optionsSearchBox:SetBackdropBorderColor(0.24, 0.24, 0.24, 0.90)
	optionsSearchBox:Hide()
	frame.optionsSearchBox = optionsSearchBox

	local optionsSearch = CreateFrame("EditBox", nil, optionsSearchBox)
	optionsSearch:SetAutoFocus(false)
	optionsSearch:SetFontObject(GameFontNormalSmall)
	optionsSearch:SetTextInsets(4,4,2,2)
	optionsSearch:SetWidth(196)
	optionsSearch:SetHeight(16)
	optionsSearch:SetPoint("LEFT", optionsSearchBox, "LEFT", 4, 0)
	optionsSearch:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
	optionsSearch:Hide()
	frame.optionsSearch = optionsSearch

	local optionsSearchIcon = optionsSearchBox:CreateTexture(nil, "ARTWORK")
	optionsSearchIcon:SetSize(12, 12)
	optionsSearchIcon:SetPoint("RIGHT", optionsSearchBox, "RIGHT", -6, 0)
	optionsSearchIcon:SetTexture(ZGV.DIR.."\\Skins\\search")
	optionsSearchIcon:SetVertexColor(0.72, 0.72, 0.72, 0.95)

	local leftSearchBox = CreateFrame("Frame", nil, left)
	leftSearchBox:SetPoint("TOPLEFT", leftSearchLabel, "BOTTOMLEFT", -2, -2)
	leftSearchBox:SetSize(226, 24)
	leftSearchBox:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	leftSearchBox:SetBackdropColor(0.04, 0.04, 0.04, 0.98)
	leftSearchBox:SetBackdropBorderColor(0.28, 0.28, 0.28, 0.95)

	local leftSearch = CreateFrame("EditBox", nil, leftSearchBox)
	leftSearch:SetAutoFocus(false)
	leftSearch:SetFontObject(GameFontNormal)
	leftSearch:SetTextInsets(4,4,2,2)
	leftSearch:SetWidth(200)
	leftSearch:SetHeight(18)
	leftSearch:SetPoint("LEFT", leftSearchBox, "LEFT", 4, 0)
	leftSearch:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
	frame.leftSearch = leftSearch

	local searchIcon = leftSearchBox:CreateTexture(nil, "ARTWORK")
	searchIcon:SetSize(12, 12)
	searchIcon:SetPoint("RIGHT", leftSearchBox, "RIGHT", -6, 0)
	searchIcon:SetTexture(ZGV.DIR.."\\Skins\\search")
	searchIcon:SetVertexColor(0.75, 0.75, 0.75, 0.95)

	local currentCard = CreateFrame("Frame", nil, center)
	currentCard:SetPoint("TOPLEFT", centerHeader, "BOTTOMLEFT", 0, -8)
	currentCard:SetPoint("TOPRIGHT", center, "TOPRIGHT", -2, -8)
	currentCard:SetHeight(58)
	currentCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	currentCard:SetBackdropColor(0.14, 0.14, 0.14, 0.94)
	currentCard:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.95)
	currentCard:Hide()
	frame.currentGuideCard = currentCard

	local currentCardTitle = currentCard:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	currentCardTitle:SetPoint("TOPLEFT", currentCard, "TOPLEFT", 8, -8)
	currentCardTitle:SetPoint("TOPRIGHT", currentCard, "TOPRIGHT", -210, -8)
	currentCardTitle:SetJustifyH("LEFT")
	currentCardTitle:SetText(LT("gb_current_guide"))
	frame.currentGuideCardTitle = currentCardTitle

	local currentCardMeta = currentCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	currentCardMeta:SetPoint("TOPLEFT", currentCardTitle, "BOTTOMLEFT", 0, -4)
	currentCardMeta:SetPoint("TOPRIGHT", currentCard, "TOPRIGHT", -210, -28)
	currentCardMeta:SetJustifyH("LEFT")
	currentCardMeta:SetText("")
	frame.currentGuideCardMeta = currentCardMeta

	local currentResume = CreateFrame("Button", nil, currentCard, "UIPanelButtonTemplate")
	currentResume:SetSize(64, 20)
	currentResume:SetPoint("TOPRIGHT", currentCard, "TOPRIGHT", -8, -8)
	currentResume:SetText(LT("gb_action_resume"))
	frame.currentGuideResume = currentResume

	local currentRestart = CreateFrame("Button", nil, currentCard, "UIPanelButtonTemplate")
	currentRestart:SetSize(64, 20)
	currentRestart:SetPoint("TOPRIGHT", currentResume, "BOTTOMRIGHT", 0, -4)
	currentRestart:SetText(LT("gb_action_restart"))
	frame.currentGuideRestart = currentRestart

	local currentOpen = CreateFrame("Button", nil, currentCard, "UIPanelButtonTemplate")
	currentOpen:SetSize(64, 20)
	currentOpen:SetPoint("RIGHT", currentRestart, "LEFT", -4, 0)
	currentOpen:SetText(LT("gb_tab_current"))
	frame.currentGuideOpen = currentOpen

	local list = CreateFrame("Frame", nil, center)
	list:SetPoint("TOPLEFT", headerLine, "BOTTOMLEFT", 0, -2)
	list:SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", -2, 2)
	list:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	list:SetBackdropColor(0, 0, 0, 0)

	local scroll = CreateFrame("ScrollFrame", "ZGVGuideManagerStandaloneScroll", list, "FauxScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -20, 0)

	local featuredPane = CreateFrame("Frame", nil, center)
	featuredPane:SetPoint("TOPLEFT", headerLine, "BOTTOMLEFT", 0, -2)
	featuredPane:SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", -2, 2)
	featuredPane:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
	featuredPane:SetBackdropColor(0, 0, 0, 0)
	featuredPane:Hide()
	frame.featuredPane = featuredPane

	local featuredCards = CreateFrame("Frame", nil, featuredPane)
	featuredCards:SetPoint("TOPLEFT", featuredPane, "TOPLEFT", 2, -2)
	featuredCards:SetPoint("TOPRIGHT", featuredPane, "TOPRIGHT", -2, -2)
	featuredCards:SetHeight(172)
	frame.featuredCards = featuredCards

	frame.featuredCardButtons = {}
	for i = 1, 4 do
		local b = CreateFrame("Button", nil, featuredCards)
		if i == 1 then
			b:SetPoint("TOPLEFT", featuredCards, "TOPLEFT", 2, -2)
		elseif i == 2 then
			b:SetPoint("TOPLEFT", frame.featuredCardButtons[1], "TOPRIGHT", 6, 0)
		elseif i == 3 then
			b:SetPoint("TOPLEFT", frame.featuredCardButtons[1], "BOTTOMLEFT", 0, -6)
		else
			b:SetPoint("TOPLEFT", frame.featuredCardButtons[3], "TOPRIGHT", 6, 0)
		end
		b:SetWidth(272)
		b:SetHeight(78)
		b:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		b:SetBackdropColor(0.10, 0.11, 0.13, 0.94)
		b:SetBackdropBorderColor(0.26, 0.28, 0.33, 0.95)
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetAllPoints()
		b.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.bg:SetVertexColor(0.72, 0.76, 0.86, 0.02)
		b.title = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		b.title:SetPoint("TOPLEFT", b, "TOPLEFT", 8, -8)
		b.title:SetPoint("TOPRIGHT", b, "TOPRIGHT", -8, -8)
		b.title:SetJustifyH("LEFT")
		b.count = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		b.count:SetPoint("TOPLEFT", b.title, "BOTTOMLEFT", 0, -2)
		b.count:SetPoint("TOPRIGHT", b, "TOPRIGHT", -8, -22)
		b.count:SetJustifyH("LEFT")
		b.preview = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		b.preview:SetPoint("TOPLEFT", b.count, "BOTTOMLEFT", 0, -4)
		b.preview:SetPoint("TOPRIGHT", b, "TOPRIGHT", -8, -38)
		b.preview:SetJustifyH("LEFT")
		b.preview:SetTextColor(0.72, 0.78, 0.88, 1)
		b.preview:SetWordWrap(false)
		b.preview:SetText("")
		frame.featuredCardButtons[i] = b
	end

	local featuredRoadmapHeader = featuredPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	featuredRoadmapHeader:SetPoint("TOPLEFT", featuredCards, "BOTTOMLEFT", 2, -8)
	featuredRoadmapHeader:SetPoint("TOPRIGHT", featuredPane, "TOPRIGHT", -24, -8)
	featuredRoadmapHeader:SetJustifyH("LEFT")
	featuredRoadmapHeader:SetText(LT("gb_roadmap"))
	frame.featuredRoadmapHeader = featuredRoadmapHeader

	local featuredHelp = CreateFrame("Button", nil, featuredPane)
	featuredHelp:SetSize(16, 16)
	featuredHelp:SetPoint("TOPRIGHT", featuredPane, "TOPRIGHT", -2, -8)
	featuredHelp.text = featuredHelp:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	featuredHelp.text:SetAllPoints()
	featuredHelp.text:SetText("?")
	featuredHelp.text:SetTextColor(0.78, 0.88, 1.0, 1.0)
	featuredHelp:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	featuredHelp:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(LT("gb_tooltip_featured_controls"), 1, 1, 1)
		GameTooltip:AddLine(LT("gb_tooltip_featured_click"), 0.78, 0.88, 1.0)
		GameTooltip:AddLine(LT("gb_tooltip_featured_shift_click"), 0.78, 0.88, 1.0)
		GameTooltip:AddLine(LT("gb_tooltip_featured_restore"), 0.78, 0.88, 1.0)
		GameTooltip:Show()
	end)
	featuredHelp:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame.featuredHelp = featuredHelp

	local featuredRoadmap = CreateFrame("Frame", nil, featuredPane)
	featuredRoadmap:SetPoint("TOPLEFT", featuredRoadmapHeader, "BOTTOMLEFT", 0, -4)
	featuredRoadmap:SetPoint("BOTTOMRIGHT", featuredPane, "BOTTOMRIGHT", -2, 2)
	featuredRoadmap:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	featuredRoadmap:SetBackdropColor(0.08, 0.09, 0.11, 0.92)
	featuredRoadmap:SetBackdropBorderColor(0.24, 0.26, 0.30, 0.94)
	frame.featuredRoadmap = featuredRoadmap

	frame.featuredRoadmapRows = {}
	for i = 1, 7 do
		local rb = CreateFrame("Button", nil, featuredRoadmap)
		rb:SetHeight(44)
		rb:SetPoint("TOPLEFT", featuredRoadmap, "TOPLEFT", 8, -8 - ((i - 1) * 45))
		rb:SetPoint("RIGHT", featuredRoadmap, "RIGHT", -8, 0)
		rb:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		rb:SetBackdropColor(0, 0, 0, 0)
		rb:SetBackdropBorderColor(0.24, 0.26, 0.30, 0.94)
		rb.bg = rb:CreateTexture(nil, "BACKGROUND")
		rb.bg:SetAllPoints()
		rb.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		rb.bg:SetVertexColor(0.80, 0.83, 0.92, 0.04)
		rb.seq = rb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		rb.seq:SetPoint("TOPLEFT", rb, "TOPLEFT", 4, -5)
		rb.seq:SetWidth(22)
		rb.seq:SetJustifyH("CENTER")
		rb.seq:Hide()
		rb.gainIcon = rb:CreateTexture(nil, "ARTWORK")
		rb.gainIcon:SetSize(12, 12)
		rb.gainIcon:SetPoint("LEFT", rb, "LEFT", 28, 0)
		rb.gainIcon:Hide()
		rb.confDot = rb:CreateTexture(nil, "ARTWORK")
		rb.confDot:SetSize(10, 10)
		rb.confDot:SetTexture(RETAIL_GUIDE_ICONS_BIG)
		rb.confDot:SetTexCoord(GetTabsIconTexCoord("misc"))
		rb.confDot:SetVertexColor(0.72, 0.74, 0.80, 0.95)
		rb.confDot:Hide()
		rb.title = rb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		rb.title:SetPoint("TOPLEFT", rb, "TOPLEFT", 54, -6)
		rb.title:SetJustifyH("LEFT")
		rb.meta = rb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		rb.meta:SetPoint("TOPRIGHT", rb, "TOPRIGHT", -18, -5)
		rb.meta:SetJustifyH("RIGHT")
		rb.meta:SetTextColor(0.80, 0.80, 0.83, 1)
		rb.title:SetPoint("TOPRIGHT", rb.meta, "TOPLEFT", -10, 0)
		rb.confDot:SetPoint("RIGHT", rb.gainIcon, "LEFT", -4, 0)
		rb.subtitle = rb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		rb.subtitle:SetPoint("TOPLEFT", rb.title, "BOTTOMLEFT", 0, -2)
		rb.subtitle:SetPoint("TOPRIGHT", rb.meta, "BOTTOMLEFT", -10, -16)
		rb.subtitle:SetJustifyH("LEFT")
		rb.subtitle:SetTextColor(0.72, 0.78, 0.88, 1)
		rb.subtitle:SetWordWrap(false)
		rb.dismiss = CreateFrame("Button", nil, rb)
		rb.dismiss:SetSize(14, 14)
		rb.dismiss:SetPoint("TOPRIGHT", rb, "TOPRIGHT", -4, -20)
		rb.dismiss.text = rb.dismiss:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		rb.dismiss.text:SetAllPoints()
		rb.dismiss.text:SetText("x")
		rb.dismiss.text:SetTextColor(0.72, 0.72, 0.74, 0.85)
		rb.dismiss:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		rb.dismiss:Hide()
		rb:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		frame.featuredRoadmapRows[i] = rb
	end

	local guideImage = details:CreateTexture(nil, "ARTWORK")
	guideImage:SetPoint("TOPLEFT", details, "TOPLEFT", 1, -1)
	guideImage:SetPoint("TOPRIGHT", details, "TOPRIGHT", -1, -1)
	guideImage:SetHeight(178)
	guideImage:SetTexture(GUIDE_HERO_GLOBAL_DEFAULT)
	guideImage:SetTexCoord(0, 1, 0, 1)
	frame.detailImage = guideImage

	local detailTitle = details:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	detailTitle:SetPoint("TOPLEFT", guideImage, "BOTTOMLEFT", 8, -10)
	detailTitle:SetPoint("TOPRIGHT", details, "TOPRIGHT", -10, -10)
	detailTitle:SetJustifyH("LEFT")
	detailTitle:SetText(LT("gb_no_guide_selected"))
	frame.detailTitle = detailTitle

	local detailMeta = details:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	detailMeta:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -6)
	detailMeta:SetPoint("TOPRIGHT", details, "TOPRIGHT", -10, -24)
	detailMeta:SetJustifyH("LEFT")
	detailMeta:SetJustifyV("TOP")
	detailMeta:SetText("")
	frame.detailMeta = detailMeta

	local detailProgressLabel = details:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	detailProgressLabel:SetPoint("TOPLEFT", detailMeta, "BOTTOMLEFT", 0, -12)
	detailProgressLabel:SetPoint("TOPRIGHT", details, "TOPRIGHT", -10, -12)
	detailProgressLabel:SetJustifyH("LEFT")
	detailProgressLabel:SetText(LT("gb_progress_format", 0))
	frame.detailProgressLabel = detailProgressLabel

	local detailProgressBg = details:CreateTexture(nil, "BORDER")
	detailProgressBg:SetPoint("TOPLEFT", detailProgressLabel, "BOTTOMLEFT", 0, -6)
	detailProgressBg:SetSize(206, 8)
	detailProgressBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	detailProgressBg:SetVertexColor(0.20, 0.20, 0.20, 1)
	local detailProgressFill = details:CreateTexture(nil, "ARTWORK")
	detailProgressFill:SetPoint("TOPLEFT", detailProgressBg, "TOPLEFT", 1, -1)
	detailProgressFill:SetPoint("BOTTOMLEFT", detailProgressBg, "BOTTOMLEFT", 1, 1)
	detailProgressFill:SetWidth(0)
	detailProgressFill:SetTexture("Interface\\Buttons\\WHITE8x8")
	detailProgressFill:SetVertexColor(0.88, 0.73, 0.25, 1)
	frame.detailProgressFill = detailProgressFill

	frame.bottomBar = nil

	local treePanel = {
		search = leftSearch,
		list = list,
		scroll = scroll,
		rows = {},
		visibleRows = 20,
		ownerFrame = frame,
		loadOnClick = false,
		selectedGuideTitle = nil,
		rowHeight = 22,
		fontSize = 14,
		firstBlankRow = false,
		useDrilldown = true,
		browsePath = (self.db and self.db.profile and self.db.profile.guidebrowserpath) or "",
	}
	frame.treePanel = treePanel
	local UpdateLeftCategoryCounts
	local ApplyOptionsSearchFilter
	local UpdateOptionsContext
	local RenderFeaturedPane
	local MoveFeaturedSelection
	local SwitchFeaturedBucket
	local DismissFeaturedSelection
	local ResetHiddenFeatured
	local FEATURED_GAIN_CATEGORY_BY_TYPE = {
		xp = "leveling",
		dungeon = "dungeons",
		daily = "daily",
		reputation = "reputations",
		profession = "professions",
		unlock = "misc",
		achievement = "achievements",
	}

	RenderFeaturedPane = function()
		if not (frame and frame.featuredPane) then return end
		if self.db and self.db.profile then
			self.db.profile.guidebrowser_featured_hidden = self.db.profile.guidebrowser_featured_hidden or {}
		end
		if self.db and self.db.char then
			self.db.char.guidebrowser_featured_snooze = self.db.char.guidebrowser_featured_snooze or {}
		end
		self._featuredSessionHide = self._featuredSessionHide or {}
		local hiddenFeatured = (self.db and self.db.profile and self.db.profile.guidebrowser_featured_hidden) or {}
		local featuredSnooze = (self.db and self.db.char and self.db.char.guidebrowser_featured_snooze) or {}
		local featuredSessionHide = self._featuredSessionHide or {}
		local function HasAnySnooze()
			if next(featuredSessionHide) or next(featuredSnooze) or next(hiddenFeatured) then return true end
			return false
		end
		local rows = BuildSpecialSectionRows(self, "featured", leftSearch:GetText() or "")
		local grouped = {}
		local metaByTitle = {}
		for _,bucket in ipairs(FEATURED_BUCKET_ORDER) do grouped[bucket] = {} end
		for _,r in ipairs(rows or {}) do
			if r and r.kind == "guide" and r.title and r.featuredbucket then
				if grouped[r.featuredbucket] then
					tinsert(grouped[r.featuredbucket], r)
					metaByTitle[r.title] = {
						context = r.context or "",
						bucket = r.featuredbucket,
						confidence = r.confidence,
						meta = r.meta or "",
					}
				end
			end
		end
		frame.featuredRowsByBucket = grouped
		frame.featuredMetaByTitle = metaByTitle
		local firstAvailable
		for _,bucket in ipairs(FEATURED_BUCKET_ORDER) do
			if grouped[bucket] and #grouped[bucket] > 0 then
				firstAvailable = bucket
				break
			end
		end
		local lastBucket = self._featuredLastBucket
		if not firstAvailable then
			frame.featuredActiveBucket = nil
		elseif lastBucket and grouped[lastBucket] and #grouped[lastBucket] > 0 and (not frame.featuredActiveBucket or not grouped[frame.featuredActiveBucket] or #grouped[frame.featuredActiveBucket] == 0) then
			frame.featuredActiveBucket = lastBucket
		elseif not frame.featuredActiveBucket or not grouped[frame.featuredActiveBucket] or #grouped[frame.featuredActiveBucket] == 0 then
			frame.featuredActiveBucket = firstAvailable
		end
		if frame.featuredActiveBucket then
			self._featuredLastBucket = frame.featuredActiveBucket
		end

		local searchText = (leftSearch and leftSearch.GetText and leftSearch:GetText()) or ""
		local hasSearch = searchText and searchText ~= ""
		local hasSnoozed = HasAnySnooze()
		local cardIndex = 1
		local function GetBucketPreview(bucket, data)
			local first = data and data[1]
			local title = first and (first.label or first.title) or ""
			if bucket == "next" then
				return (title ~= "" and LT("gb_bucket_preview_next_with_title", title)) or LT("gb_bucket_preview_next")
			elseif bucket == "progress" then
				return (title ~= "" and LT("gb_bucket_preview_progress_with_title", title)) or LT("gb_bucket_preview_progress")
			elseif bucket == "level" then
				return (title ~= "" and LT("gb_bucket_preview_level_with_title", title)) or LT("gb_bucket_preview_level")
			end
			return (title ~= "" and LT("gb_bucket_preview_featured_with_title", title)) or LT("gb_bucket_preview_featured")
		end
		for _,bucket in ipairs(FEATURED_BUCKET_ORDER) do
			local data = grouped[bucket]
			local card = frame.featuredCardButtons and frame.featuredCardButtons[cardIndex]
			if card then
				if data and #data > 0 then
					card.bucket = bucket
					card.title:SetText(FEATURED_BUCKET_LABELS[bucket] or bucket)
					card.count:SetText(LT("gb_guides_count_format", #data))
					card.preview:SetText(GetBucketPreview(bucket, data))
					if frame.featuredActiveBucket == bucket then
						card.bg:SetVertexColor(0.90, 0.93, 1.00, 0.11)
						card:SetBackdropBorderColor(0.90, 0.76, 0.32, 0.96)
					else
						card.bg:SetVertexColor(0.72, 0.76, 0.86, 0.02)
						card:SetBackdropBorderColor(0.26, 0.28, 0.33, 0.95)
					end
					card:SetScript("OnClick", function(btn)
						frame.featuredActiveBucket = btn.bucket
						self._featuredLastBucket = btn.bucket
						RenderFeaturedPane()
					end)
					card:Show()
					cardIndex = cardIndex + 1
				end
			end
		end
		for i = cardIndex, 4 do
			if frame.featuredCardButtons and frame.featuredCardButtons[i] then
				frame.featuredCardButtons[i]:Hide()
			end
		end
		if cardIndex == 1 and frame.featuredCardButtons and frame.featuredCardButtons[1] then
			local emptyCard = frame.featuredCardButtons[1]
			emptyCard.bucket = nil
			emptyCard.title:SetText(LT("gb_empty_no_featured_suggestions"))
			emptyCard.count:SetText(LT("gb_guides_count_format", 0))
			if hasSearch then
				emptyCard.preview:SetText(LT("gb_action_clear_search_restore"))
			elseif hasSnoozed then
				emptyCard.preview:SetText(LT("gb_action_reset_snoozed_restore"))
			else
				emptyCard.preview:SetText(LT("gb_action_try_home"))
			end
			emptyCard.bg:SetVertexColor(0.72, 0.76, 0.86, 0.02)
			emptyCard:SetBackdropBorderColor(0.26, 0.28, 0.33, 0.95)
			emptyCard:SetScript("OnClick", function()
				if hasSearch and leftSearch and leftSearch.SetText then
					leftSearch:SetText("")
					RenderFeaturedPane()
				elseif hasSnoozed then
					ResetHiddenFeatured()
				elseif frame.SetSection then
					frame:SetSection("home")
				end
			end)
			emptyCard:Show()
		end
		local activeBucket = frame.featuredActiveBucket
		local activeRows = (activeBucket and grouped[activeBucket]) or {}
		if #activeRows == 0 then
			if hasSnoozed then
				activeRows = {
					{
						title = "__reset_hidden__",
						label = LT("gb_action_reset_snoozed"),
						meta = LT("gb_meta_action"),
						context = LT("gb_meta_why_prefix") .. LT("gb_meta_suggestions_snoozed") .. " | " .. LT("gb_meta_gain_prefix") .. LT("gb_meta_restore_recommendations"),
						gaintype = "unlock",
						confidence = "fallback",
					}
				}
			elseif hasSearch then
				activeRows = {
					{
						title = "__clear_search__",
						label = LT("gb_action_clear_search_restore"),
						meta = LT("gb_meta_action"),
						context = LT("gb_meta_why_prefix") .. LT("gb_meta_filter_no_matches") .. " | " .. LT("gb_meta_gain_prefix") .. LT("gb_meta_see_full_recommendations"),
						gaintype = "xp",
						confidence = "fallback",
					}
				}
			else
				activeRows = {
					{
						title = "__go_home__",
						label = LT("gb_action_browse_all_from_home"),
						meta = LT("gb_meta_action"),
						context = LT("gb_meta_why_prefix") .. LT("gb_meta_no_bucket_suggestions") .. " | " .. LT("gb_meta_gain_prefix") .. LT("gb_meta_full_category_access"),
						gaintype = "unlock",
						confidence = "fallback",
					}
				}
			end
		end
		local hasSelectedInActive = false
		for _,rr in ipairs(activeRows) do
			if treePanel.selectedGuideTitle and rr.title == treePanel.selectedGuideTitle then
				hasSelectedInActive = true
				break
			end
		end
		if not hasSelectedInActive then
			treePanel.selectedGuideTitle = nil
		end
		frame.featuredRoadmapHeader:SetText(LT("gb_roadmap_bucket_format", FEATURED_BUCKET_LABELS[activeBucket] or LT("gb_roadmap")))
		if #activeRows == 0 then
			frame.featuredRoadmapHeader:SetText(LT("gb_roadmap"))
		end

		local firstTitle = nil
		local function Trunc(text, maxlen)
			local t = text or ""
			if #t <= maxlen then return t end
			return t:sub(1, maxlen - 3) .. "..."
		end
		local function TruncToWidth(fs, text, maxwidth)
			local t = text or ""
			if t == "" then return "" end
			if not fs or not maxwidth or maxwidth <= 0 then return t end
			fs:SetText(t)
			if fs:GetStringWidth() <= maxwidth then return t end
			local lo,hi = 1,#t
			while lo < hi do
				local mid = math.floor((lo + hi + 1) / 2)
				local cand = t:sub(1, mid) .. "..."
				fs:SetText(cand)
				if fs:GetStringWidth() <= maxwidth then
					lo = mid
				else
					hi = mid - 1
				end
			end
			return t:sub(1, lo) .. "..."
		end
		local function ComputeTextMaxWidth(fs, metaFs, row, pad)
			local padding = tonumber(pad or 10) or 10
			if fs and metaFs and fs.GetLeft and metaFs.GetLeft then
				local l = fs:GetLeft()
				local r = metaFs:GetLeft()
				if l and r and r > l then
					return math.max(180, math.floor((r - l) - padding))
				end
			end
			local rw = (row and row.GetWidth and row:GetWidth()) or 0
			if (not rw or rw <= 10) and frame and frame.featuredRoadmap and frame.featuredRoadmap.GetWidth then
				rw = (frame.featuredRoadmap:GetWidth() or 0) - 16
			end
			if not rw or rw <= 10 then rw = 640 end
			return math.max(220, math.floor(rw - 120))
		end
		for i,rb in ipairs(frame.featuredRoadmapRows or {}) do
			local rr = activeRows[i]
			if rr then
				if not firstTitle and rr.title and not strfind(rr.title, "__", 1, true) then firstTitle = rr.title end
				rb.row = rr
				rb.seq:Hide()
				local iconCategory = FEATURED_GAIN_CATEGORY_BY_TYPE[rr.gaintype or "xp"] or "leveling"
				rb.gainIcon:SetTexture(RETAIL_GUIDE_ICONS_BIG)
				rb.gainIcon:SetTexCoord(GetTabsIconTexCoord(iconCategory))
				rb.gainIcon:Show()
				local confColor = FEATURED_CONFIDENCE_COLORS[rr.confidence or "fallback"] or FEATURED_CONFIDENCE_COLORS.fallback
				rb.confDot:SetVertexColor(confColor[1], confColor[2], confColor[3], confColor[4])
				rb.confDot:Show()
				rb.meta:SetText(rr.meta or "")
				local titleText = rr.label or rr.title or ""
				local titleMax = ComputeTextMaxWidth(rb.title, rb.meta, rb, 10)
				rb.title:SetText(TruncToWidth(rb.title, titleText, titleMax))
				local subtitleText = FormatReasonLines(rr.context or "")
				local subtitleMax = ComputeTextMaxWidth(rb.subtitle, rb.meta, rb, 10)
				rb.subtitle:SetText(TruncToWidth(rb.subtitle, subtitleText, subtitleMax))
				local selected = treePanel.selectedGuideTitle and treePanel.selectedGuideTitle == rr.title
				if selected then
					rb.bg:SetVertexColor(0.90, 0.93, 1.00, 0.12)
					rb:SetBackdropBorderColor(0.90, 0.76, 0.32, 0.90)
					rb.title:SetTextColor(1.0, 1.0, 1.0, 1.0)
					rb.subtitle:SetTextColor(0.86, 0.90, 0.98, 1.0)
				elseif rr.currentselected then
					rb.bg:SetVertexColor(0.76, 0.90, 1.00, 0.13)
					rb:SetBackdropBorderColor(0.54, 0.76, 0.98, 0.92)
					rb.title:SetTextColor(0.92, 0.97, 1.0, 1.0)
					rb.subtitle:SetTextColor(0.78, 0.88, 0.98, 1.0)
				else
					rb.bg:SetVertexColor(0.80, 0.83, 0.92, 0.04)
					rb:SetBackdropBorderColor(0.24, 0.26, 0.30, 0.94)
					rb.title:SetTextColor(0.90, 0.90, 0.92, 1.0)
					rb.subtitle:SetTextColor(0.72, 0.78, 0.88, 1.0)
				end
				if (rr.title and strfind(rr.title, "__", 1, true)) or rr.currentselected then
					rb.dismiss:Hide()
				else
					rb.dismiss:Show()
					rb.dismiss:SetScript("OnClick", function(btn)
						local row = btn:GetParent() and btn:GetParent().row
						if not row or not row.title then return end
						if IsShiftKeyDown() then
							featuredSessionHide[row.title] = true
						else
							featuredSnooze[row.title] = time() + (24 * 60 * 60)
						end
						if hiddenFeatured then hiddenFeatured[row.title] = nil end
						if treePanel.selectedGuideTitle == row.title then
							treePanel.selectedGuideTitle = nil
							if frame.SetSelectedGuide then frame:SetSelectedGuide(nil) end
						end
						RenderFeaturedPane()
					end)
					rb.dismiss:SetScript("OnEnter", function(btn)
						GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
						GameTooltip:ClearLines()
						GameTooltip:AddLine(LT("gb_tooltip_snooze"), 1, 1, 1)
						GameTooltip:AddLine(LT("gb_tooltip_snooze_click"), 0.78, 0.88, 1.0)
						GameTooltip:AddLine(LT("gb_tooltip_snooze_shift_click"), 0.78, 0.88, 1.0)
						GameTooltip:Show()
					end)
					rb.dismiss:SetScript("OnLeave", function()
						GameTooltip:Hide()
					end)
				end
				rb:SetScript("OnEnter", function(btn)
					local row = btn.row
					if not row then return end
					GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
					GameTooltip:ClearLines()
					GameTooltip:AddLine(row.label or row.title or LT("gb_meta_suggestion"), 1, 1, 1)
					if row.meta and row.meta ~= "" then
						GameTooltip:AddLine(row.meta, 0.85, 0.85, 0.90)
					end
					local why,gain = ParseWhyGainFromContext(row.context or "")
					if why ~= "" then
						GameTooltip:AddLine(LT("gb_tooltip_why_prefix") .. why, 0.72, 0.82, 0.95, true)
					end
					if gain ~= "" then
						GameTooltip:AddLine(LT("gb_tooltip_gain_prefix") .. gain, 0.78, 0.90, 0.76, true)
					end
					if row.confidence then
						GameTooltip:AddLine(LT("gb_tooltip_confidence_prefix") .. (FEATURED_CONFIDENCE_LABELS[row.confidence] or row.confidence), 0.78, 0.92, 1.0, true)
					end
					if row.chainStep and row.chainStep > 0 then
						GameTooltip:AddLine(LT("gb_tooltip_chain_prefix") .. "+" .. tostring(row.chainStep), 0.88, 0.88, 0.92, true)
					end
					if row.fallback then
						GameTooltip:AddLine(LT("gb_tooltip_fallback_recommendation"), 0.92, 0.80, 0.52)
					end
					GameTooltip:Show()
				end)
				rb:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
				rb:SetScript("OnClick", function(btn)
					local row = btn.row
					if not row or not row.title then return end
					if row.title == "__reset_hidden__" then
						if self.db and self.db.profile then
							self.db.profile.guidebrowser_featured_hidden = {}
						end
						if self.db and self.db.char then
							self.db.char.guidebrowser_featured_snooze = {}
						end
						self._featuredSessionHide = {}
						RenderFeaturedPane()
						return
					elseif row.title == "__clear_search__" then
						if leftSearch and leftSearch.SetText then
							leftSearch:SetText("")
						end
						RenderFeaturedPane()
						return
					elseif row.title == "__go_home__" then
						if frame.SetSection then frame:SetSection("home") end
						return
					end
					local wasSelected = (treePanel.selectedGuideTitle == row.title)
					treePanel.selectedFolderPath = nil
					treePanel.selectedGuideTitle = row.title
					if frame.SetSelectedGuide then frame:SetSelectedGuide(row.title) end
					if wasSelected then
						self:SetGuide(row.title)
						self:FocusStep(1)
					end
					RenderFeaturedPane()
				end)
				rb:Show()
			else
				rb.row = nil
				rb.seq:Hide()
				rb.gainIcon:Hide()
				rb.confDot:Hide()
				rb.dismiss:Hide()
				rb:Hide()
			end
		end

		if firstTitle and (not treePanel.selectedGuideTitle) then
			treePanel.selectedGuideTitle = firstTitle
			if frame.SetSelectedGuide then frame:SetSelectedGuide(firstTitle) end
		end
	end
	frame.RenderFeaturedPane = function()
		RenderFeaturedPane()
	end

	MoveFeaturedSelection = function(delta)
		if frame.currentSection ~= "featured" then return end
		local bucket = frame.featuredActiveBucket
		if not bucket then return end
		local rows = {}
		for _,r in ipairs((frame.featuredRowsByBucket and frame.featuredRowsByBucket[bucket]) or {}) do
			if r and r.title and r.title ~= "__reset_hidden__" then
				tinsert(rows, r)
			end
		end
		if #rows == 0 then return end
		local idx = 1
		for i,r in ipairs(rows) do
			if treePanel.selectedGuideTitle and r.title == treePanel.selectedGuideTitle then idx = i break end
		end
		idx = idx + (delta or 0)
		if idx < 1 then idx = 1 end
		if idx > #rows then idx = #rows end
		local pick = rows[idx]
		if pick then
			treePanel.selectedGuideTitle = pick.title
			if frame.SetSelectedGuide then frame:SetSelectedGuide(pick.title) end
			RenderFeaturedPane()
		end
	end
	SwitchFeaturedBucket = function(delta)
		if frame.currentSection ~= "featured" then return end
		local cur = frame.featuredActiveBucket
		local idx = 1
		for i,b in ipairs(FEATURED_BUCKET_ORDER) do if b == cur then idx = i break end end
		idx = idx + (delta or 0)
		if idx < 1 then idx = #FEATURED_BUCKET_ORDER end
		if idx > #FEATURED_BUCKET_ORDER then idx = 1 end
		frame.featuredActiveBucket = FEATURED_BUCKET_ORDER[idx]
		self._featuredLastBucket = frame.featuredActiveBucket
		RenderFeaturedPane()
	end
	ResetHiddenFeatured = function()
		if self.db and self.db.profile then
			self.db.profile.guidebrowser_featured_hidden = {}
		end
		if self.db and self.db.char then
			self.db.char.guidebrowser_featured_snooze = {}
		end
		self._featuredSessionHide = {}
		RenderFeaturedPane()
	end
	DismissFeaturedSelection = function()
		if frame.currentSection ~= "featured" then return end
		local sel = treePanel.selectedGuideTitle
		if not sel or sel == "__reset_hidden__" then return end
		if self.CurrentGuide and self.CurrentGuide.title and sel == self.CurrentGuide.title then return end
		if IsShiftKeyDown() then
			self._featuredSessionHide = self._featuredSessionHide or {}
			self._featuredSessionHide[sel] = true
		elseif self.db and self.db.char then
			self.db.char.guidebrowser_featured_snooze = self.db.char.guidebrowser_featured_snooze or {}
			self.db.char.guidebrowser_featured_snooze[sel] = time() + (24 * 60 * 60)
		end
		treePanel.selectedGuideTitle = nil
		if frame.SetSelectedGuide then frame:SetSelectedGuide(nil) end
		RenderFeaturedPane()
	end

	scroll:SetScript("OnVerticalScroll", function(sf, offset)
		FauxScrollFrame_OnVerticalScroll(sf, offset, treePanel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT, function() self:RefreshGuideManagerPanel(treePanel) end)
	end)

	local function ScrollTreeBy(deltaLines)
		local rows = treePanel.rowsBuilder and treePanel.rowsBuilder() or BuildGuideManagerRows(self, leftSearch:GetText() or "", treePanel.filterFn)
		local shown = treePanel.visibleRows or #treePanel.rows
		local total = #rows
		local maxoff = math.max(0, total - shown)
		local off = FauxScrollFrame_GetOffset(scroll) or 0
		off = off - deltaLines
		if off < 0 then off = 0 end
		if off > maxoff then off = maxoff end
		FauxScrollFrame_SetOffset(scroll, off)
		scroll:SetVerticalScroll(off * (treePanel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT))
		local sbar = _G[scroll:GetName() .. "ScrollBar"]
		if sbar and sbar.SetValue then sbar:SetValue(off * (treePanel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT)) end
		self:RefreshGuideManagerPanel(treePanel)
	end

	local function OnWheel(_, delta)
		ScrollTreeBy((delta or 0) * 3)
	end
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", OnWheel)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", OnWheel)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", OnWheel)
	local sbar = _G[scroll:GetName() .. "ScrollBar"]
	if sbar then
		sbar:EnableMouseWheel(true)
		sbar:SetScript("OnMouseWheel", OnWheel)
	end

	leftSearch:SetScript("OnTextChanged", function()
		self.db.profile.guidebrowsersearch = leftSearch:GetText() or ""
		FauxScrollFrame_SetOffset(scroll, 0)
		if frame.currentSection == "featured" and frame.RenderFeaturedPane then
			frame:RenderFeaturedPane()
		else
			self:RefreshGuideManagerPanel(treePanel)
		end
		UpdateLeftCategoryCounts()
	end)
	optionsSearch:SetScript("OnTextChanged", function()
		local visibleApp = ApplyOptionsSearchFilter()
		if frame.currentSection == "options" and visibleApp and frame.currentOptionsApp ~= visibleApp and (not frame.leftOptionButtons[frame.currentOptionsApp] or not frame.leftOptionButtons[frame.currentOptionsApp]:IsShown()) then
			frame.currentOptionsApp = visibleApp
			if self and self.db and self.db.profile then
				self.db.profile.guidebrowseroptionsapp = frame.currentOptionsApp
			end
			if frame.RenderOptionsApp then frame:RenderOptionsApp(frame.currentOptionsApp) end
		end
	end)

	local function GetGuideRows()
		local out = {}
		for i,row in ipairs(treePanel.rowsData or {}) do
			if row and row.kind == "guide" and row.title and row.title ~= "" then
				tinsert(out, { index = i, row = row })
			end
		end
		return out
	end

	local function EnsureSelectionVisible()
		local selTitle = treePanel.selectedGuideTitle
		if not selTitle then return end
		local rows = treePanel.rowsData or {}
		local selIndex
		for i,row in ipairs(rows) do
			if row.kind == "guide" and row.title == selTitle then selIndex = i break end
		end
		if not selIndex then return end
		local shown = treePanel.visibleRows or 10
		local off = FauxScrollFrame_GetOffset(treePanel.scroll) or 0
		local top = off + 1
		local bot = off + shown
		if selIndex < top then
			off = selIndex - 1
		elseif selIndex > bot then
			off = selIndex - shown
		end
		if off < 0 then off = 0 end
		FauxScrollFrame_SetOffset(treePanel.scroll, off)
	end

	local function MoveGuideSelection(delta)
		local guides = GetGuideRows()
		if #guides == 0 then return end
		local current = 1
		if treePanel.selectedGuideTitle then
			for i,g in ipairs(guides) do
				if g.row.title == treePanel.selectedGuideTitle then current = i break end
			end
		end
		local target = current + delta
		if target < 1 then target = 1 end
		if target > #guides then target = #guides end
		local picked = guides[target]
		if not picked then return end
		treePanel.selectedGuideTitle = picked.row.title
		if treePanel.ownerFrame and treePanel.ownerFrame.SetSelectedGuide then
			treePanel.ownerFrame:SetSelectedGuide(picked.row.title)
		end
		EnsureSelectionVisible()
		self:RefreshGuideManagerPanel(treePanel)
	end

	local function ExpandCollapseBySelection(direction)
		local title = treePanel.selectedGuideTitle
		if not title or title == "" then return end
		local parts = SplitGuideTitle(title)
		if #parts < 2 then return end
		self.db.profile.guidebrowsertreeexpanded = self.db.profile.guidebrowsertreeexpanded or {}
		local expanded = self.db.profile.guidebrowsertreeexpanded
		if direction == "expand" then
			local path = ""
			for i = 1, #parts - 1 do
				path = (path ~= "" and (path .. "\\" .. parts[i])) or parts[i]
				if not expanded[path] then
					expanded[path] = true
					break
				end
			end
		else
			local path = ""
			local paths = {}
			for i = 1, #parts - 1 do
				path = (path ~= "" and (path .. "\\" .. parts[i])) or parts[i]
				tinsert(paths, path)
			end
			for i = #paths, 1, -1 do
				if expanded[paths[i]] then
					expanded[paths[i]] = false
					break
				end
			end
		end
		self:RefreshGuideManagerPanel(treePanel)
	end

	frame.topTabButtons = {}
	for i,tab in ipairs(GUIDE_MANAGER_TOP_TABS) do
		local b = CreateFrame("Button", nil, tabBar)
		b:SetHeight(24)
		b:SetWidth(120)
		if i == 1 then
			b:SetPoint("LEFT", tabBar, "LEFT", 4, 0)
		else
			b:SetPoint("LEFT", frame.topTabButtons[GUIDE_MANAGER_TOP_TABS[i-1].id], "RIGHT", 14, 0)
		end
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.bg:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 2)
		b.bg:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -1)
		b.bg:SetVertexColor(1, 1, 1, 0.00)
		b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		b.text:SetAllPoints()
		b.text:SetJustifyH("LEFT")
		b.text:SetText(tab.label)
		ApplyRetailFont(b.text, 14, "", false)
		b.underline = b:CreateTexture(nil, "ARTWORK")
		b.underline:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.underline:SetVertexColor(0.82, 0.84, 0.88, 0.0)
		b.underline:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, -2)
		b.underline:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, -2)
		b.underline:SetHeight(2)
		b.tabId = tab.id
		b:SetScript("OnClick", function(btn)
			if btn.tabId == "home" then
				frame.homeShowAll = true
				if self.db and self.db.profile then
					self.db.profile.guidebrowserhomeall = true
				end
			end
			self:SelectGuideManagerSection(btn.tabId)
		end)
		b:SetScript("OnEnter", function(btn)
			if frame.currentSection ~= btn.tabId and btn.bg then btn.bg:SetVertexColor(1, 1, 1, 0.06) end
		end)
		b:SetScript("OnLeave", function(btn)
			if frame.currentSection ~= btn.tabId and btn.bg then btn.bg:SetVertexColor(1, 1, 1, 0.00) end
		end)
		frame.topTabButtons[tab.id] = b
	end

	frame.leftMenuButtons = {}
	for i,entry in ipairs(GUIDE_MANAGER_LEFT_MENU) do
		local b = CreateFrame("Button", nil, left)
		b:SetHeight(32)
		b:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -52 - ((i - 1) * 34))
		b:SetPoint("RIGHT", left, "RIGHT", -8, 0)
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.bg:SetPoint("TOPLEFT", b, "TOPLEFT", -6, 0)
		b.bg:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
		b.bg:SetVertexColor(1, 1, 1, 0.00)
		b.sel = b:CreateTexture(nil, "ARTWORK")
		b.sel:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.sel:SetWidth(2)
		b.sel:SetPoint("TOPLEFT", b, "TOPLEFT", -6, -1)
		b.sel:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", -6, 1)
		b.sel:SetVertexColor(0.82, 0.84, 0.88, 0.0)
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetSize(16, 16)
		b.icon:SetPoint("LEFT", b, "LEFT", 2, 0)
		b.icon:SetTexture(RETAIL_GUIDE_ICONS_BIG)
		b.icon:SetTexCoord(GetTabsIconTexCoord(entry.id))
		b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
		b.text:SetPoint("RIGHT", b, "RIGHT", -2, 0)
		b.text:SetJustifyH("LEFT")
		b.text:SetText(entry.label)
		ApplyRetailFont(b.text, 16, "", false)
		b.baseLabel = entry.label
		b.categoryId = entry.id
		b:SetScript("OnClick", function(btn)
			-- Category picks always route to Home + selected category.
			frame.homeShowAll = false
			if self.db and self.db.profile then
				self.db.profile.guidebrowserhomeall = false
			end
			if frame.SetSection then frame:SetSection("home") end
			if frame.SetCategory then frame:SetCategory(btn.categoryId) end
		end)
		b:SetScript("OnEnter", function(btn)
			if frame.currentCategory ~= btn.categoryId and btn.bg then
				btn.bg:SetVertexColor(1, 1, 1, 0.06)
			end
		end)
		b:SetScript("OnLeave", function(btn)
			if frame.currentCategory ~= btn.categoryId and btn.bg then
				btn.bg:SetVertexColor(1, 1, 1, 0.00)
			end
		end)
		frame.leftMenuButtons[entry.id] = b
	end

	local optionsDivider = left:CreateTexture(nil, "BORDER")
	optionsDivider:SetTexture("Interface\\Buttons\\WHITE8x8")
	optionsDivider:SetVertexColor(0.28, 0.28, 0.28, 0.90)
	optionsDivider:SetPoint("BOTTOMLEFT", left, "BOTTOMLEFT", 8, 40)
	optionsDivider:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -8, 40)
	optionsDivider:SetHeight(1)
	frame.leftOptionsDivider = optionsDivider

	local optionsLeftButton = CreateFrame("Button", nil, left)
	optionsLeftButton:SetHeight(30)
	optionsLeftButton:SetPoint("BOTTOMLEFT", left, "BOTTOMLEFT", 8, 6)
	optionsLeftButton:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -8, 6)
	optionsLeftButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	optionsLeftButton.bg = optionsLeftButton:CreateTexture(nil, "BACKGROUND")
	optionsLeftButton.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
	optionsLeftButton.bg:SetPoint("TOPLEFT", optionsLeftButton, "TOPLEFT", -6, 0)
	optionsLeftButton.bg:SetPoint("BOTTOMRIGHT", optionsLeftButton, "BOTTOMRIGHT", 0, 0)
	optionsLeftButton.bg:SetVertexColor(1, 1, 1, 0.00)
	optionsLeftButton.sel = optionsLeftButton:CreateTexture(nil, "ARTWORK")
	optionsLeftButton.sel:SetTexture("Interface\\Buttons\\WHITE8x8")
	optionsLeftButton.sel:SetWidth(2)
	optionsLeftButton.sel:SetPoint("TOPLEFT", optionsLeftButton, "TOPLEFT", -6, -1)
	optionsLeftButton.sel:SetPoint("BOTTOMLEFT", optionsLeftButton, "BOTTOMLEFT", -6, 1)
	optionsLeftButton.sel:SetVertexColor(0.82, 0.84, 0.88, 0.0)
	optionsLeftButton.icon = optionsLeftButton:CreateTexture(nil, "ARTWORK")
	optionsLeftButton.icon:SetSize(16, 16)
	optionsLeftButton.icon:SetPoint("LEFT", optionsLeftButton, "LEFT", 2, 0)
	optionsLeftButton.icon:SetTexture(RETAIL_TITLEBUTTONS_TEXTURE)
	do
		-- Stealth titlebuttons index 21 = settings gear.
		local l,r,t,b = GetStealthTopHalfIconTexCoord(21)
		optionsLeftButton.icon:SetTexCoord(l,r,t,b)
	end
	optionsLeftButton.text = optionsLeftButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsLeftButton.text:SetPoint("LEFT", optionsLeftButton.icon, "RIGHT", 6, 0)
	optionsLeftButton.text:SetPoint("RIGHT", optionsLeftButton, "RIGHT", -2, 0)
	optionsLeftButton.text:SetJustifyH("LEFT")
	optionsLeftButton.text:SetText(LT("gb_tab_options"))
	ApplyRetailFont(optionsLeftButton.text, 15, "", false)
	optionsLeftButton:SetScript("OnClick", function() self:SelectGuideManagerSection("options") end)
	optionsLeftButton:SetScript("OnEnter", function(btn)
		if frame.currentSection ~= "options" and btn.bg then
			btn.bg:SetVertexColor(1, 1, 1, 0.06)
		end
	end)
	optionsLeftButton:SetScript("OnLeave", function(btn)
		if frame.currentSection ~= "options" and btn.bg then
			btn.bg:SetVertexColor(1, 1, 1, 0.00)
		end
	end)
	frame.leftOptionsButton = optionsLeftButton

	frame.leftOptionButtons = {}
	frame.leftOptionOrder = BuildGuideManagerOptionsApps(self)
	for i,opt in ipairs(frame.leftOptionOrder) do
		local b = CreateFrame("Button", nil, leftOptionsPanel)
		b:SetHeight(32)
		b:SetPoint("TOPLEFT", leftOptionsPanel, "TOPLEFT", 6, -42 - ((i - 1) * 34))
		b:SetPoint("RIGHT", leftOptionsPanel, "RIGHT", -6, 0)
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.bg:SetAllPoints()
		b.bg:SetVertexColor(1, 1, 1, 0.00)
		b.sel = b:CreateTexture(nil, "ARTWORK")
		b.sel:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.sel:SetWidth(2)
		b.sel:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -1)
		b.sel:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 1)
		b.sel:SetVertexColor(0.82, 0.84, 0.88, 0.0)
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetSize(16, 16)
		b.icon:SetPoint("LEFT", b, "LEFT", 6, 0)
		b.icon:SetTexture(ZGV.DIR.."\\Skins\\options-menu-icons")
		b.icon:SetTexCoord(GetOptionsIconTexCoord(GUIDE_MANAGER_OPTIONS_APP_ICON[opt.app] or "general"))
		b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
		b.text:SetPoint("RIGHT", b, "RIGHT", -2, 0)
		b.text:SetJustifyH("LEFT")
		b.text:SetText(opt.label)
		ApplyRetailFont(b.text, 14, "", false)
		b.label = opt.label
		b.app = opt.app
		b.order = i
		b:SetScript("OnClick", function(btn)
			frame.currentOptionsApp = btn.app
			if self and self.db and self.db.profile then
				self.db.profile.guidebrowseroptionsapp = btn.app
			end
			if frame.optionsTitle then
				frame.optionsTitle:SetText(btn.label or LT("gb_tab_options"))
			end
			for app,but in pairs(frame.leftOptionButtons or {}) do
				if app == btn.app then
					but.text:SetText("|cffdfe3eb" .. (but.label or StripColorCodes(but.text:GetText())) .. "|r")
					if but.bg then but.bg:SetVertexColor(0.82, 0.84, 0.88, 0.12) end
					if but.sel then but.sel:SetAlpha(1.0) end
				else
					but.text:SetText(but.label or StripColorCodes(but.text:GetText()))
					if but.bg then but.bg:SetVertexColor(1, 1, 1, 0.00) end
					if but.sel then but.sel:SetAlpha(0.0) end
				end
			end
			UpdateOptionsContext(btn.app)
			if frame.RenderOptionsApp then frame:RenderOptionsApp(btn.app) end
		end)
		b:SetScript("OnEnter", function(btn)
			if frame.currentOptionsApp ~= btn.app and btn.bg then
				btn.bg:SetVertexColor(1, 1, 1, 0.06)
			end
		end)
		b:SetScript("OnLeave", function(btn)
			if frame.currentOptionsApp ~= btn.app and btn.bg then
				btn.bg:SetVertexColor(1, 1, 1, 0.00)
			end
		end)
		b.sep = b:CreateTexture(nil, "BORDER")
		b.sep:SetTexture("Interface\\Buttons\\WHITE8x8")
		b.sep:SetVertexColor(0.22, 0.22, 0.22, 0.60)
		b.sep:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 6, 0)
		b.sep:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -6, 0)
		b.sep:SetHeight(1)
		b:Hide()
		frame.leftOptionButtons[opt.app] = b
	end

	frame.RenderOptionsApp = function(_, appName)
		local ACD = LibStub and LibStub("AceConfigDialog-3.0", true)
		local AceGUI = (LibStub and LibStub("AceGUI-3.0-Z", true)) or (LibStub and LibStub("AceGUI-3.0", true))
		local targetApp = appName or "ZygorGuidesViewer"
		if ACD and frame.lastRenderedOptionsApp then
			pcall(function() ACD:Close(frame.lastRenderedOptionsApp) end)
		end
		if frame.optionsAceWidgetRoot and frame.optionsAceWidgetRoot.Release then
			frame.optionsAceWidgetRoot:Release()
			frame.optionsAceWidgetRoot = nil
			frame.optionsAceWidget = nil
		end
		frame.optionsFallback:Hide()

		if not (ACD and AceGUI) then
			frame.optionsFallback:SetText(LT("gb_options_fallback_embed_unavailable"))
			frame.optionsFallback:Show()
			return
		end

		-- Keep all option apps on equal footing; without this, non-root apps can render cramped.
		if ACD.SetDefaultSize then
			pcall(function() ACD:SetDefaultSize(targetApp, 600, 400) end)
		end

		local function CreateFirstSupported(...)
			for i = 1, select("#", ...) do
				local widgetType = select(i, ...)
				local ok, widget = pcall(function() return AceGUI:Create(widgetType) end)
				if ok and widget then return widget end
			end
		end

		local root = CreateFirstSupported("SimpleGroup-Z", "SimpleGroup")
		local scroll = CreateFirstSupported("ScrollFrame-Z", "ScrollFrame")
		local host = CreateFirstSupported("SimpleGroup-Z", "SimpleGroup")
		if not (root and scroll and host) then
			frame.optionsFallback:SetText(LT("gb_options_fallback_missing_widgets"))
			frame.optionsFallback:Show()
			return
		end

		host:SetLayout("Fill")
		host.frame:SetParent(frame.optionsContent)
		host.frame:ClearAllPoints()
		-- Give embedded Ace options a small inner gutter so checkbox/text widgets
		-- don't bleed over the middle-column frame border.
		host.frame:SetPoint("TOPLEFT", frame.optionsContent, "TOPLEFT", 8, -6)
		host.frame:SetPoint("BOTTOMRIGHT", frame.optionsContent, "BOTTOMRIGHT", -8, 6)
		host.frame:SetFrameStrata(frame.optionsContent:GetFrameStrata() or "MEDIUM")
		host.frame:SetFrameLevel((frame.optionsContent:GetFrameLevel() or 1) + 2)
		host.frame:Show()

		scroll:SetLayout("Fill")
		host:AddChild(scroll)

		root:SetLayout("Flow")
		scroll:AddChild(root)
		if scroll and scroll.content and scroll.content.SetHeight then
			-- Reset baseline per page so previous long page height doesn't leak.
			scroll.content:SetHeight(1)
		end

		frame.optionsAceWidgetRoot = host
		frame.optionsAceWidget = root

		local ok, err = pcall(function()
			ACD:Open(targetApp, root)
		end)
		if not ok then
			if frame.optionsAceWidgetRoot and frame.optionsAceWidgetRoot.Release then
				frame.optionsAceWidgetRoot:Release()
				frame.optionsAceWidgetRoot = nil
				frame.optionsAceWidget = nil
			end
			frame.optionsFallback:SetText(LT("gb_options_fallback_render_error", tostring(err)))
			frame.optionsFallback:Show()
		else
			local function RefreshOptionsScroll()
				if not (scroll and scroll.content and frame.optionsContent) then return end
				local rootH = (root and root.frame and root.frame.GetHeight and root.frame:GetHeight()) or 0
				local targetH = math.max(1, rootH)
				if scroll.content.SetHeight and targetH > 0 then
					scroll.content:SetHeight(targetH)
				end
				if scroll.DoLayout then pcall(function() scroll:DoLayout() end) end
				if scroll.FixScroll then pcall(function() scroll:FixScroll() end) end
			end
			RefreshOptionsScroll()
			if host and host.frame then
				host.frame._zgv_opts_scroll_ticks = 0
				host.frame:SetScript("OnUpdate", function(f)
					f._zgv_opts_scroll_ticks = (f._zgv_opts_scroll_ticks or 0) + 1
					RefreshOptionsScroll()
					if f._zgv_opts_scroll_ticks >= 4 then
						f._zgv_opts_scroll_ticks = nil
						f:SetScript("OnUpdate", nil)
					end
				end)
			end
			frame.lastRenderedOptionsApp = targetApp
		end
	end

	local function UpdateCurrentGuideCard()
		local section = frame.currentSection or "home"
		local category = frame.currentCategory or "leveling"
		local g = self.CurrentGuide
		local show = (section == "home" and category ~= "favorites" and g and g.title)
		if show then
			local step = self.CurrentStepNum or 1
			currentCardTitle:SetText(g.title_short or g.title or LT("gb_current_guide"))
			currentCardMeta:SetText(LT("gb_current_meta_format", step, (g.steps and #g.steps) or 0, GetGuideLastUsedText(self, g.title)))
			currentCard:Show()
			currentResume:SetEnabled(true)
			currentRestart:SetEnabled(true)
			currentOpen:SetEnabled(true)
			currentResume:SetScript("OnClick", function()
				if not (self.CurrentGuide and self.CurrentGuide.title) then return end
				self:SetGuide(self.CurrentGuide.title)
				self:FocusStep(self.CurrentStepNum or 1)
			end)
			currentRestart:SetScript("OnClick", function()
				if not (self.CurrentGuide and self.CurrentGuide.title) then return end
				self:SetGuide(self.CurrentGuide.title)
				self:FocusStep(1)
			end)
			currentOpen:SetScript("OnClick", function()
				frame:SetSection("current")
			end)
			list:ClearAllPoints()
			list:SetPoint("TOPLEFT", currentCard, "BOTTOMLEFT", 0, -8)
			list:SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", -2, 2)
		else
			currentCard:Hide()
			list:ClearAllPoints()
			list:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -8)
			list:SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", -2, 2)
		end
		local vis = math.floor((list:GetHeight() - 8) / (treePanel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT))
		if vis < 8 then vis = 8 end
		if treePanel.visibleRows ~= vis then
			treePanel.visibleRows = vis
			EnsureGuideManagerRows(self, treePanel, treePanel.visibleRows)
		end
	end

	local function UpdateDetails()
		local sel = treePanel.selectedGuideTitle
		local guide = sel and self:GetGuideByTitle(sel) or nil
		if not sel or not guide then
			local folderPath = treePanel.selectedFolderPath or treePanel.browsePath or ""
			local image = ResolveGuideHeroImageFromText(folderPath, frame.currentCategory, frame.currentSection)
			if folderPath ~= "" then
				local parts = SplitGuideTitle(folderPath)
				local label = parts[#parts] or folderPath
				frame.detailTitle:SetText(label)
				frame.detailMeta:SetText(LT("gb_folder_format", folderPath))
				frame.detailImage:SetTexture(image)
			else
				frame.detailTitle:SetText(LT("gb_no_guide_selected"))
				frame.detailMeta:SetText(LT("gb_select_guide_from_list"))
				frame.detailImage:SetTexture(ResolveGuideHeroImageFromText("", frame.currentCategory, frame.currentSection))
			end
			frame.detailProgressLabel:SetText(LT("gb_progress_format", 0))
			frame.detailProgressFill:SetWidth(0)
			return
		end
		local steps = (guide.steps and #guide.steps) or 0
		local author = guide.author or LT("gb_unknown")
		local nextg = guide.next or LT("gb_none")
		local complete = 0
		if guide.GetCompletion then
			local ok, _, cur, total = pcall(function() return guide:GetCompletion() end)
			if ok and total and total > 0 and cur then
				complete = math.floor((cur / total) * 100 + 0.5)
			end
		end
		-- 3.3.5a fallback: live progress for the active guide based on current step index.
		if complete <= 0 and steps > 0 and self.CurrentGuide and self.CurrentGuide.title == guide.title then
			local stepnum = self.CurrentStepNum or 1
			if stepnum < 1 then stepnum = 1 end
			if stepnum > (steps + 1) then stepnum = steps + 1 end
			complete = math.floor(((stepnum - 1) / steps) * 100 + 0.5)
		end
		-- Retail-like continuity: use remembered step progress for non-active selected guides too.
		if complete <= 0 and steps > 0 then
			local remembered
			if self.GetRememberedGuideStep then
				remembered = self:GetRememberedGuideStep(guide.title)
			elseif self.db and self.db.char then
				local gp = self.db.char.guide_progress or {}
				local rec = gp[guide.title]
				if rec and rec.step then remembered = rec.step end
			end
			if remembered and remembered > 0 then
				local stepnum = remembered
				if stepnum < 1 then stepnum = 1 end
				if stepnum > (steps + 1) then stepnum = steps + 1 end
				if self.CurrentGuide and self.CurrentGuide.title == guide.title then
					complete = math.floor(((stepnum - 1) / steps) * 100 + 0.5)
				else
					-- For non-active guides, treat reaching the last step as complete (100%).
					complete = math.floor((stepnum / steps) * 100 + 0.5)
				end
			end
		end
		frame.detailTitle:SetText(guide.title_short or guide.title or sel)
		local detailMeta = LT("gb_detail_meta_format", steps, author, nextg)
		if frame.currentSection == "featured" then
			local featuredMeta = frame.featuredMetaByTitle and frame.featuredMetaByTitle[guide.title]
			if featuredMeta then
				local context = type(featuredMeta) == "table" and (featuredMeta.context or "") or tostring(featuredMeta or "")
				context = FormatReasonLines(context)
				local bucket = type(featuredMeta) == "table" and featuredMeta.bucket or nil
				local confidence = type(featuredMeta) == "table" and featuredMeta.confidence or nil
				local extra = {}
				if bucket and bucket ~= "" then
					tinsert(extra, LT("gb_meta_suggested_from", FEATURED_BUCKET_LABELS[bucket] or bucket))
				end
				if confidence and confidence ~= "" then
					tinsert(extra, LT("gb_meta_confidence", FEATURED_CONFIDENCE_LABELS[confidence] or confidence))
				end
				local extraLine = (#extra > 0) and (table.concat(extra, "\n") .. "\n") or ""
				if context ~= "" then
					detailMeta = (context .. "\n" .. extraLine .. detailMeta)
				else
					detailMeta = (extraLine .. detailMeta)
				end
			elseif treePanel and treePanel.rowsData then
				for _,row in ipairs(treePanel.rowsData) do
					if row and row.kind == "guide" and row.title == guide.title and row.meta and row.meta ~= "" then
						detailMeta = (row.meta .. "\n" .. detailMeta)
						break
					end
				end
			end
		end
		frame.detailMeta:SetText(detailMeta)
		frame.detailImage:SetTexture(ResolveGuideHeroImage(guide, frame.currentCategory, frame.currentSection))
		frame.detailProgressLabel:SetText(LT("gb_progress_format", complete))
		local fillW = math.max(0, math.min(204, math.floor(204 * (complete / 100))))
		frame.detailProgressFill:SetWidth(fillW)
	end

	local function PaintTopTabState(activeTab)
		for id,but in pairs(frame.topTabButtons) do
			local txt = StripColorCodes(but.text:GetText())
			if id == activeTab then
				but.text:SetText("|cffdfe3eb" .. txt .. "|r")
				if but.underline then but.underline:SetAlpha(1.0) end
				if but.bg then but.bg:SetVertexColor(0.82, 0.84, 0.88, 0.11) end
			else
				but.text:SetText(txt)
				if but.underline then but.underline:SetAlpha(0.0) end
				if but.bg then but.bg:SetVertexColor(1, 1, 1, 0.00) end
			end
		end
	end

	local function PaintCategoryState(activeCategory)
		for id,but in pairs(frame.leftMenuButtons) do
			local txt = StripColorCodes(but.text:GetText())
			if id == activeCategory then
				but.text:SetText("|cffdfe3eb" .. txt .. "|r")
				if but.bg then but.bg:SetVertexColor(0.82, 0.84, 0.88, 0.12) end
				if but.sel then but.sel:SetAlpha(1.0) end
			else
				but.text:SetText(txt)
				if but.bg then but.bg:SetVertexColor(1, 1, 1, 0.00) end
				if but.sel then but.sel:SetAlpha(0.0) end
			end
		end
	end

	UpdateLeftCategoryCounts = function()
		for id,but in pairs(frame.leftMenuButtons or {}) do
			local base = but.baseLabel or StripColorCodes(but.text:GetText())
			but.text:SetText(base)
		end
		if frame.currentSection == "home" and frame.homeShowAll then
			PaintCategoryState(nil)
		else
			PaintCategoryState(frame.currentCategory or "leveling")
		end
	end

	local function PaintOptionsCategoryState(activeApp)
		for app,but in pairs(frame.leftOptionButtons or {}) do
			if app == activeApp then
				but.text:SetText("|cffdfe3eb" .. (but.label or StripColorCodes(but.text:GetText())) .. "|r")
				if but.bg then but.bg:SetVertexColor(0.82, 0.84, 0.88, 0.12) end
				if but.sel then but.sel:SetAlpha(1.0) end
			else
				but.text:SetText(but.label or StripColorCodes(but.text:GetText()))
				if but.bg then but.bg:SetVertexColor(1, 1, 1, 0.00) end
				if but.sel then but.sel:SetAlpha(0.0) end
			end
		end
	end

	UpdateOptionsContext = function(appName)
		local meta = GetOptionsAppMeta(appName)
		if frame.optionsDetailTitle then frame.optionsDetailTitle:SetText(meta.label or LT("gb_opt_general")) end
		if frame.optionsDetailBody then frame.optionsDetailBody:SetText(meta.desc or LT("gb_opt_desc_general")) end
		if frame.optionsDetailHint then
			frame.optionsDetailHint:SetText(LT("gb_hint_options_filter"))
		end
	end

	local function GetCategoryLabel(categoryId)
		for _,c in ipairs(GUIDE_MANAGER_LEFT_MENU or {}) do
			if c.id == categoryId then return c.label end
		end
		return LT("gb_opt_guides")
	end

	frame.UpdateCenterHeader = function()
		if not frame.centerHeader then return end
		local section = frame.currentSection or "home"
		local category = frame.currentCategory or "leveling"
		local path = treePanel.browsePath or ""
		local parts = StringToPath(path)
		local title = LT("gb_select_guide")
		if section == "home" then
			if frame.homeShowAll then
				title = (#parts > 0 and parts[#parts]) or LT("gb_all_guides")
			else
				title = (#parts > 0 and parts[#parts]) or GetCategoryLabel(category)
			end
		elseif section == "current" then
			title = (#parts > 0 and parts[#parts]) or LT("gb_tab_current")
		elseif section == "recent" then
			title = LT("gb_tab_recent")
		elseif section == "featured" then
			title = LT("gb_tab_featured")
		elseif section == "options" then
			title = LT("gb_tab_options")
		end
		frame.sectionTitle:SetText(title)

		local canBack = ((section == "home" or section == "current") and #parts > 0)
		if frame.centerHeaderBack then
			if canBack then frame.centerHeaderBack:Show() else frame.centerHeaderBack:Hide() end
		end
		if frame.centerHeaderMenu then
			if section ~= "options" then frame.centerHeaderMenu:Show() else frame.centerHeaderMenu:Hide() end
		end
	end

	ApplyOptionsSearchFilter = function()
		local needle = strlower(((frame.optionsSearch and frame.optionsSearch:GetText()) or ""):gsub("^%s+", ""):gsub("%s+$", ""))
		local shownIndex = 0
		local firstVisibleApp = nil
		for _,opt in ipairs(frame.leftOptionOrder or {}) do
			local but = frame.leftOptionButtons and frame.leftOptionButtons[opt.app]
			if but then
				local hay = strlower((but.label or "") .. " " .. (opt.app or "") .. " " .. (opt.desc or ""))
				hay = hay .. " " .. (GetOptionsAppSearchHay(self, opt.app) or "")
				local show = (needle == "" or strfind(hay, needle, 1, true) ~= nil)
				if show then
					shownIndex = shownIndex + 1
					but:ClearAllPoints()
					but:SetPoint("TOPLEFT", leftOptionsPanel, "TOPLEFT", 6, -42 - ((shownIndex - 1) * 34))
					but:SetPoint("RIGHT", leftOptionsPanel, "RIGHT", -6, 0)
					but:Show()
					if not firstVisibleApp then firstVisibleApp = opt.app end
				else
					but:Hide()
				end
			end
		end
		if frame.currentOptionsApp and frame.leftOptionButtons and frame.leftOptionButtons[frame.currentOptionsApp] and not frame.leftOptionButtons[frame.currentOptionsApp]:IsShown() then
			frame.currentOptionsApp = firstVisibleApp
		end
		if frame.currentOptionsApp then
			PaintOptionsCategoryState(frame.currentOptionsApp)
			UpdateOptionsContext(frame.currentOptionsApp)
		end
		return firstVisibleApp
	end

	local function SetSectionMode(section)
		local isOptions = (section == "options")
		local isFeatured = (section == "featured")
		if isOptions then
			center:Hide()
			details:Hide()
			list:Show()
			if frame.featuredPane then frame.featuredPane:Hide() end
			optionsPane:Show()
			leftSearchLabel:Hide()
			leftSearchBox:Hide()
			leftOptionsTitle:Show()
			leftOptionsHint:Show()
			leftOptionsPanel:Show()
			optionsSearchLabel:Show()
			optionsSearchBox:Show()
			optionsSearch:Show()
			for _,but in pairs(frame.leftMenuButtons or {}) do but:Hide() end
			ApplyOptionsSearchFilter()
			frame.leftOptionsDivider:Show()
			frame.leftOptionsButton:Show()
			if frame.leftOptionsButton and frame.leftOptionsButton.bg then
				frame.leftOptionsButton.bg:SetVertexColor(0.82, 0.84, 0.88, 0.12)
			end
			if frame.leftOptionsButton and frame.leftOptionsButton.sel then
				frame.leftOptionsButton.sel:SetAlpha(1.0)
			end
			if frame.leftOptionsButton and frame.leftOptionsButton.text then
				frame.leftOptionsButton.text:SetText("|cffdfe3eb" .. LT("gb_tab_options") .. "|r")
			end
		else
			local ACD = LibStub and LibStub("AceConfigDialog-3.0", true)
			if ACD and frame.currentOptionsApp then
				pcall(function() ACD:Close(frame.currentOptionsApp) end)
			end
			if ACD and frame.lastRenderedOptionsApp then
				pcall(function() ACD:Close(frame.lastRenderedOptionsApp) end)
			end
			if frame.optionsAceWidgetRoot and frame.optionsAceWidgetRoot.Release then
				frame.optionsAceWidgetRoot:Release()
				frame.optionsAceWidgetRoot = nil
				frame.optionsAceWidget = nil
			end
			center:Show()
			details:Show()
			optionsPane:Hide()
			if isFeatured then
				list:Hide()
				if frame.featuredPane then frame.featuredPane:Show() end
			else
				list:Show()
				if frame.featuredPane then frame.featuredPane:Hide() end
			end
			leftSearchLabel:Show()
			leftSearchBox:Show()
			leftOptionsTitle:Hide()
			leftOptionsHint:Hide()
			leftOptionsPanel:Hide()
			optionsSearchLabel:Hide()
			optionsSearchBox:Hide()
			optionsSearch:Hide()
			for _,but in pairs(frame.leftMenuButtons or {}) do but:Show() end
			for _,but in pairs(frame.leftOptionButtons or {}) do but:Hide() end
			frame.leftOptionsDivider:Show()
			frame.leftOptionsButton:Show()
			if frame.leftOptionsButton and frame.leftOptionsButton.bg then
				frame.leftOptionsButton.bg:SetVertexColor(1, 1, 1, 0.00)
			end
			if frame.leftOptionsButton and frame.leftOptionsButton.sel then
				frame.leftOptionsButton.sel:SetAlpha(0.0)
			end
			if frame.leftOptionsButton and frame.leftOptionsButton.text then
				frame.leftOptionsButton.text:SetText(LT("gb_tab_options"))
			end
		end
	end

	local function UpdatePanelRowsForContext()
		local section = frame.currentSection or "home"
		local category = frame.currentCategory or "leveling"
		treePanel.filterFn = CategoryFilterFor(category)
		if section == "home" and frame.homeShowAll then
			treePanel.filterFn = nil
		end
		treePanel.rowsBuilder = nil
		treePanel.useDrilldown = (section == "home" or section == "current")
		if section == "options" then
			treePanel.filterFn = nil
			treePanel.rowsBuilder = function() return {} end
			treePanel.useDrilldown = false
			return
		end
		if category == "favorites" and section == "home" then
			treePanel.useDrilldown = false
			treePanel.rowsBuilder = function()
				local rows = {}
				local fav = self.db and self.db.profile and self.db.profile.guidefavorites or {}
				local needle = strlower((leftSearch:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""))
				for title,_ in pairs(fav or {}) do
					local g = self:GetGuideByTitle(title)
					local label = (g and g.title_short) or title
					local hay = strlower((label or "") .. " " .. title)
					if needle == "" or strfind(hay, needle, 1, true) then
						tinsert(rows, { kind = "guide", depth = 0, label = label, title = title })
					end
				end
				if #rows == 0 then
					tinsert(rows, { kind = "header", depth = 0, label = LT("gb_empty_no_favorites") })
					tinsert(rows, { kind = "action", depth = 0, label = LT("gb_action_go_home"), action = "go_home_leveling" })
				end
				return rows
			end
			return
		end
		if section == "current" then
			treePanel.filterFn = nil
			treePanel.useDrilldown = true
			do
				local title = self.CurrentGuide and self.CurrentGuide.title
				if title and title ~= "" then
					local parts = SplitGuideTitle(title)
					if #parts > 1 then
						tremove(parts)
						treePanel.browsePath = PathToString(parts)
					else
						treePanel.browsePath = ""
					end
				end
			end
			treePanel.rowsBuilder = function()
				return BuildCurrentSectionRows(self, leftSearch:GetText() or "")
			end
			treePanel.selectedGuideTitle = self.CurrentGuide and self.CurrentGuide.title or treePanel.selectedGuideTitle
		elseif section == "recent" or section == "featured" then
			treePanel.useDrilldown = false
			treePanel.rowsBuilder = function()
				return BuildSpecialSectionRows(self, section, leftSearch:GetText() or "")
			end
		else
			treePanel.useDrilldown = true
			if section == "home" and (treePanel.browsePath == nil) then
				treePanel.browsePath = (self.db and self.db.profile and self.db.profile.guidebrowserpath) or ""
			end
		end
		if self.db and self.db.profile and treePanel.useDrilldown then
			self.db.profile.guidebrowserpath = treePanel.browsePath or ""
		end
	end

	frame.SetSection = function(_, section)
		section = section or "home"
		if section == "home" then
			if frame.homeShowAll == nil then frame.homeShowAll = true end
			if frame.homeShowAll then
				treePanel.browsePath = ""
				if self.db and self.db.profile then self.db.profile.guidebrowserpath = "" end
			end
		end
		frame.currentSection = section
		self.db.profile.guidebrowsersection = section
		PaintTopTabState(section)
		SetSectionMode(section)
		UpdatePanelRowsForContext()
		UpdateLeftCategoryCounts()

		if section == "home" then
			-- header is handled by UpdateCenterHeader
		elseif section == "featured" then
			-- header is handled by UpdateCenterHeader
		elseif section == "current" then
			-- header is handled by UpdateCenterHeader
		elseif section == "recent" then
			-- header is handled by UpdateCenterHeader
		elseif section == "options" then
			frame.currentOptionsApp = frame.currentOptionsApp
				or (self.db and self.db.profile and self.db.profile.guidebrowseroptionsapp)
				or "ZygorGuidesViewer"
			local appLabel = LT("gb_opt_general")
			local activeButton = frame.leftOptionButtons and frame.leftOptionButtons[frame.currentOptionsApp]
			if activeButton and activeButton.label then appLabel = activeButton.label end
			frame.optionsTitle:SetText(appLabel)
			UpdateOptionsContext(frame.currentOptionsApp)
			PaintOptionsCategoryState(frame.currentOptionsApp)
			if frame.RenderOptionsApp then frame:RenderOptionsApp(frame.currentOptionsApp) end
		end
		if frame.UpdateCenterHeader then frame:UpdateCenterHeader() end
		if section ~= "options" then
			if section == "home" or section == "current" then
				treePanel.selectedFolderPath = treePanel.browsePath or ""
			end
			if section == "featured" and frame.RenderFeaturedPane then
				frame:RenderFeaturedPane()
			else
				self:RefreshGuideManagerPanel(treePanel)
			end
		end
		UpdateDetails()
	end

	frame.SetCategory = function(_, category)
		category = category or "leveling"
		frame.homeShowAll = false
		if self.db and self.db.profile then
			self.db.profile.guidebrowserhomeall = false
		end
		frame.currentCategory = category
		self.db.profile.guidebrowsercategory = category
		UpdateLeftCategoryCounts()
		if frame.currentSection == "home" then
			treePanel.browsePath = ""
			if self.db and self.db.profile then self.db.profile.guidebrowserpath = "" end
		end
		treePanel.selectedFolderPath = treePanel.browsePath or ""
		UpdatePanelRowsForContext()
		FauxScrollFrame_SetOffset(treePanel.scroll, 0)
		treePanel.selectedGuideTitle = nil
		if frame.UpdateCenterHeader then frame:UpdateCenterHeader() end
		if frame.currentSection == "featured" and frame.RenderFeaturedPane then
			frame:RenderFeaturedPane()
		else
			self:RefreshGuideManagerPanel(treePanel)
		end
		UpdateDetails()
	end

	frame.SetSelectedGuide = function(_, title)
		treePanel.selectedGuideTitle = title
		if title then treePanel.selectedFolderPath = nil end
		UpdateDetails()
	end

	frame.SetSelectedFolder = function(_, path)
		treePanel.selectedGuideTitle = nil
		treePanel.selectedFolderPath = path or treePanel.browsePath or ""
		UpdateDetails()
	end

	frame:SetScript("OnShow", function()
		local vis = math.floor((list:GetHeight() - 8) / (treePanel.rowHeight or GUIDE_MANAGER_ROW_HEIGHT))
		if vis < 8 then vis = 8 end
		treePanel.visibleRows = vis
		EnsureGuideManagerRows(self, treePanel, treePanel.visibleRows)
		leftSearch:SetText((self.db.profile.guidebrowsersearch or ""))
		if optionsSearch then optionsSearch:SetText("") end
		frame.currentCategory = self.db.profile.guidebrowsercategory or frame.currentCategory or "leveling"
		frame.currentSection = self.db.profile.guidebrowsersection or frame.currentSection or "home"
		frame.homeShowAll = (self.db and self.db.profile and self.db.profile.guidebrowserhomeall) and true or false
		treePanel.browsePath = (self.db and self.db.profile and self.db.profile.guidebrowserpath) or ""
		treePanel.selectedFolderPath = treePanel.browsePath
		frame:SetSection(frame.currentSection or "home")
		if not frame.homeShowAll then
			frame:SetCategory(frame.currentCategory or "leveling")
		else
			UpdateLeftCategoryCounts()
		end
	end)

	local function IsGuideManagerTextInputFocused()
		local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() or nil
		return focus and (
			focus == leftSearch
			or focus == optionsSearch
		) and focus or nil
	end

	local function LoadSelectedGuideFromManager(allowResetHidden)
		local title = treePanel.selectedGuideTitle
		if not title or title == "" then return false end
		if not allowResetHidden and title == "__reset_hidden__" then return false end
		self:SetGuide(title)
		self:FocusStep(1)
		return true
	end

	local function HandleGuideManagerGlobalKey(key)
		if key == "PRINTSCREEN" or key == "SYSRQ" then
			if Screenshot then Screenshot() end
			return true
		end

		local focusedInput = IsGuideManagerTextInputFocused()
		if key == "ESCAPE" then
			if focusedInput and focusedInput.ClearFocus then
				focusedInput:ClearFocus()
			else
				frame:Hide()
			end
			return true
		end

		if focusedInput then
			return true
		end

		return false
	end

	local function HandleGuideManagerFeaturedKey(key)
		if key == "LEFT" then
			SwitchFeaturedBucket(-1)
			return true
		elseif key == "RIGHT" then
			SwitchFeaturedBucket(1)
			return true
		elseif key == "UP" then
			MoveFeaturedSelection(-1)
			return true
		elseif key == "DOWN" then
			MoveFeaturedSelection(1)
			return true
		elseif key == "DELETE" then
			DismissFeaturedSelection()
			return true
		elseif key == "R" or key == "r" then
			ResetHiddenFeatured()
			return true
		elseif key == "ENTER" then
			return LoadSelectedGuideFromManager(false)
		end

		return false
	end

	local function HandleGuideManagerTreeKey(key)
		if key == "UP" then
			MoveGuideSelection(-1)
			return true
		elseif key == "DOWN" then
			MoveGuideSelection(1)
			return true
		elseif key == "ENTER" then
			return LoadSelectedGuideFromManager(true)
		elseif key == "RIGHT" then
			ExpandCollapseBySelection("expand")
			return true
		elseif key == "LEFT" then
			ExpandCollapseBySelection("collapse")
			return true
		elseif key == "BACKSPACE" then
			local expanded = self.db.profile.guidebrowsertreeexpanded or {}
			local longestPath
			for path,isOpen in pairs(expanded) do
				if isOpen and (not longestPath or #path > #longestPath) then
					longestPath = path
				end
			end
			if longestPath then
				expanded[longestPath] = false
				self:RefreshGuideManagerPanel(treePanel)
			end
			return true
		end

		return false
	end

	frame:EnableKeyboard(true)
	frame:SetScript("OnKeyDown", function(_, key)
		if HandleGuideManagerGlobalKey(key) then return end

		if frame.currentSection == "featured" then
			if HandleGuideManagerFeaturedKey(key) then return end
		end

		if frame.currentSection == "options" then return end
		HandleGuideManagerTreeKey(key)
	end)
	frame:SetScript("OnHide", function()
		local ACD = LibStub and LibStub("AceConfigDialog-3.0", true)
		if ACD and frame.currentOptionsApp then
			pcall(function() ACD:Close(frame.currentOptionsApp) end)
		end
		if ACD and frame.lastRenderedOptionsApp then
			pcall(function() ACD:Close(frame.lastRenderedOptionsApp) end)
		end
		if frame.optionsAceWidgetRoot and frame.optionsAceWidgetRoot.Release then
			frame.optionsAceWidgetRoot:Release()
			frame.optionsAceWidgetRoot = nil
			frame.optionsAceWidget = nil
		end
		self.db.profile.guidebrowsersearch = leftSearch:GetText() or self.db.profile.guidebrowsersearch
		self.db.profile.guidebrowseroptionsapp = frame.currentOptionsApp or self.db.profile.guidebrowseroptionsapp
		self.db.profile.guidebrowsersection = frame.currentSection or self.db.profile.guidebrowsersection
		self.db.profile.guidebrowsercategory = frame.currentCategory or self.db.profile.guidebrowsercategory
		self.db.profile.guidebrowserhomeall = frame.homeShowAll and true or false
	end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		frame._detailRefreshElapsed = (frame._detailRefreshElapsed or 0) + (elapsed or 0)
		if frame._detailRefreshElapsed < 0.4 then return end
		frame._detailRefreshElapsed = 0
		if frame:IsShown() then
			UpdateDetails()
		end
	end)

	EnsureGuideManagerRows(self, treePanel, treePanel.visibleRows)
	self.GuideManagerStandaloneFrame = frame
	return frame
end

function me:SelectGuideManagerSection(section)
	local frame = EnsureGuideManagerStandaloneFrame(self)
	if frame and frame.SetSection then
		if section == "home" then
			frame.homeShowAll = true
			if self.db and self.db.profile then
				self.db.profile.guidebrowserhomeall = true
			end
		end
		frame:SetSection(section)
	end
end

function me:SelectGuideManagerCategory(category)
	local frame = EnsureGuideManagerStandaloneFrame(self)
	if frame and frame.SetCategory then frame:SetCategory(category) end
end

function me:OpenGuideManagerStepDisplay()
	local frame = EnsureGuideManagerStandaloneFrame(self)
	if self.db and self.db.profile then
		self.db.profile.guidebrowseroptionsapp = "ZygorGuidesViewer-StepDisplay"
	end
	if frame then
		frame.currentOptionsApp = "ZygorGuidesViewer-StepDisplay"
	end
	if frame and not frame:IsShown() then
		frame:Show()
	end
	self:SelectGuideManagerSection("options")
	self:SelectGuideManagerCategory("stepdisplay")
end

function me:ToggleGuideManagerFrame(section)
	local frame = EnsureGuideManagerStandaloneFrame(self)
	if frame:IsShown() then
		frame:Hide()
	else
		if section then self:SelectGuideManagerSection(section) end
		frame:Show()
	end
end
