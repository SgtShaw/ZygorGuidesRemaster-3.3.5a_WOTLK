local me = ZygorGuidesViewer
if not me then return end

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
	if PathIsRoot(p) then return "Root" end
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
		titleObj:SetText("Guide Browser")
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
	searchLabel:SetText("Search")

	local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	search:SetAutoFocus(false)
	search:SetWidth(220)
	search:SetHeight(20)
	search:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
	search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
	f.search = search

	local leftHeader = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	leftHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -84)
	leftHeader:SetText("Folders")

	local rightHeader = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	rightHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 300, -84)
	rightHeader:SetText("Guides")

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
	load:SetText("Load Guide")
	f.loadButton = load

	local legacy = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	legacy:SetWidth(180)
	legacy:SetHeight(22)
	legacy:SetPoint("RIGHT", load, "LEFT", -8, 0)
	legacy:SetText("Open Legacy Picker")
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

	local breadcrumb = (#path > 0) and table.concat(path, "  >  ") or "Root"
	f.breadcrumb:SetText("Path: " .. breadcrumb)

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
				row.text:SetText("|cffffff00" .. data.label .. "|r")
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
		InterfaceOptionsFrame_OpenToCategory(self.options and self.options.name or "Zygor Guides Viewer Remastered")
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

local function BuildGuideManagerRows(self, search)
	local rows = {}
	local root = self:BuildGuideBrowserTree()
	if not root then return rows end

	self.db.profile.guidebrowsertreeexpanded = self.db.profile.guidebrowsertreeexpanded or {}
	local expanded = self.db.profile.guidebrowsertreeexpanded
	local needle = strlower((search or ""):gsub("^%s+", ""):gsub("%s+$", ""))

	if needle ~= "" then
		local function addMatches(node, prefix)
			for _,name in ipairs(node.child_order or {}) do
				local child = node.children and node.children[name]
				local nextPrefix = (prefix ~= "" and (prefix .. "\\" .. name)) or name
				if child then addMatches(child, nextPrefix) end
			end
			for _,g in ipairs(node.guides or {}) do
				local leaf = g.leaf or g.title or ""
				local title = g.title or ""
				local hay = strlower(leaf .. " " .. title)
				if strfind(hay, needle, 1, true) then
					local label = (prefix ~= "" and (prefix .. "\\" .. leaf)) or leaf
					tinsert(rows, { kind = "guide", depth = 0, label = label, title = title })
				end
			end
		end
		addMatches(root, "")
		return rows
	end

	local function addNode(node, depth, basePath)
		for _,name in ipairs(node.child_order or {}) do
			local child = node.children and node.children[name]
			local path = (basePath ~= "" and (basePath .. "\\" .. name)) or name
			local open = expanded[path] and true or false
			tinsert(rows, { kind = "folder", depth = depth, label = name, path = path, open = open })
			if open and child then addNode(child, depth + 1, path) end
		end
		for _,g in ipairs(node.guides or {}) do
			tinsert(rows, { kind = "guide", depth = depth, label = g.leaf or g.title, title = g.title })
		end
	end
	addNode(root, 0, "")
	return rows
end

local GUIDE_MANAGER_ROW_HEIGHT = 10
local GUIDE_MANAGER_FONT_SIZE = 10
local GUIDE_MANAGER_VISIBLE_ROWS = 21

function me:RefreshGuideManagerPanel()
	local f = self.GuideManagerPanel
	if not f then return end

	local rows = BuildGuideManagerRows(self, f.search:GetText() or "")
	f.rowsData = rows

	local shown = f.visibleRows or #f.rows
	FauxScrollFrame_Update(f.scroll, #rows + 1, shown, GUIDE_MANAGER_ROW_HEIGHT)
	local off = FauxScrollFrame_GetOffset(f.scroll)

	for i = 1, shown do
		local row = f.rows[i]
		local dataIndex = (i + off) - 1
		local data = (dataIndex > 0) and rows[dataIndex] or nil
		if data then
			row.data = data
			local text
			if data.kind == "folder" then
				local indent = string.rep("  ", data.depth or 0)
				local mark = data.open and "[-] " or "[+] "
				text = indent .. mark .. data.label .. "\\"
			else
				local indent = string.rep("  ", data.depth or 0)
				text = indent .. "- " .. (data.label or "")
				if self.CurrentGuide and data.title == self.CurrentGuide.title then
					text = "|cffffff00" .. text .. "|r"
				end
			end
			row.text:SetText(text)
			row:Show()
		else
			row.data = nil
			row.text:SetText(" ")
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
		row:SetHeight(GUIDE_MANAGER_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", panel.list, "TOPLEFT", 6, -1 - ((i - 1) * GUIDE_MANAGER_ROW_HEIGHT))
		row:SetPoint("RIGHT", panel.list, "RIGHT", -26, 0)
		row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
		row.text:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetFont(STANDARD_TEXT_FONT, GUIDE_MANAGER_FONT_SIZE)
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
				self.db.profile.guidebrowsertreeexpanded = self.db.profile.guidebrowsertreeexpanded or {}
				self.db.profile.guidebrowsertreeexpanded[data.path] = not self.db.profile.guidebrowsertreeexpanded[data.path]
				self:RefreshGuideManagerPanel()
				return
			end
			if data.title and data.title ~= "" then
				self.db.profile.guidebrowserselectedguide = data.title
				self:SetGuide(data.title)
				self:FocusStep(1)
				self:RefreshGuideManagerPanel()
			end
		end)
		panel.rows[i] = row
	end
	-- Reflow all rows to current density, including rows created in older layouts.
	for i = 1, #panel.rows do
		local row = panel.rows[i]
		row:SetHeight(GUIDE_MANAGER_ROW_HEIGHT)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", panel.list, "TOPLEFT", 6, -1 - ((i - 1) * GUIDE_MANAGER_ROW_HEIGHT))
		row:SetPoint("RIGHT", panel.list, "RIGHT", -26, 0)
		if row.text and row.text.SetFont then
			row.text:SetFont(STANDARD_TEXT_FONT, GUIDE_MANAGER_FONT_SIZE)
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
	searchLabel:SetText("Search")

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
		local rows = BuildGuideManagerRows(self, search:GetText() or "")
		local shown = panel.visibleRows or #panel.rows
		local total = #rows + 1 -- include intentional blank first row
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
	InterfaceOptionsFrame_OpenToCategory((self.options and self.options.name) or "Zygor Guides Viewer Remastered")
end
