--[[
	作者:白狼
	2025 11 1
--]]

local function CreateActionEditor(actionName)
	local action = UPar.GetAction(actionName)
	local actionLabel = isstring(action.label) and action.label or actionName

	if not istable(action) then 
		return 
	end

	local guiCacheKey = 'actionEditor_' .. actionName
	local locationCacheKey = 'actionEditor_Location'

	local OldActionEditor = UPar.LRUGet(guiCacheKey)
	local location = UPar.LRUGet(locationCacheKey) or {}
	
	if IsValid(OldActionEditor) then 
		OldActionEditor:Remove() 
	end

	local w, h, divWidth = unpack(location)

	w = isnumber(w) and w or 600
	h = isnumber(h) and h or 400
	divWidth = isnumber(divWidth) and divWidth or 200

	local actionEditor = vgui.Create('UParActionEditor')
	actionEditor:Init2(action)
	actionEditor:SetSize(w, h)
	actionEditor:SetPos((ScrW() - w) / 2, (ScrH() - h) / 2)
	actionEditor:SetIcon(isstring(action.icon) and action.icon or 'icon32/tool.png')
	if IsValid(actionEditor.div) then
		actionEditor.div:SetLeftWidth(divWidth)
	end
		
	actionEditor.OnClose = function(self)
		local w, h = actionEditor:GetSize()
		local divWidth = IsValid(actionEditor.div) and actionEditor.div:GetLeftWidth() or 200
		
		UPar.LRUSet(locationCacheKey, {w, h, divWidth})
	end

	UPar.LRUSet(guiCacheKey, actionEditor)

	return actionEditor
end

local function CreateMenu(panel)
	panel:Clear()

	local actionManager = vgui.Create('DTree')
	actionManager:SetSize(200, 400)

	local selNodeLast = nil
	actionManager.OnNodeSelected = function(self, selNode)
		if selNodeLast == selNode then
			CreateActionEditor(selNode.actionName)

			selNodeLast = nil
		else
			selNodeLast = selNode
		end
	end

	actionManager.RefreshNode = function(self)
		actionManager:Clear()

		local keys = {}
		for k, v in pairs(UPar.ActionSet) do table.insert(keys, k) end
		table.sort(keys)

		for i, k in ipairs(keys) do
			local v = UPar.ActionSet[k]
			if v.Invisible then continue end
			local label = isstring(v.label) and v.label or k
			local icon = isstring(v.icon) and v.icon or 'icon32/tool.png'
			
			local node = self:AddNode(label, icon)
			node.actionName = v.Name


			local editButton = vgui.Create('DButton', node)
			editButton:SetSize(20, 18)
			editButton:Dock(RIGHT)
			
			editButton:SetText('')
			editButton:SetIcon('icon16/application_edit.png')
			
			editButton.DoClick = function()
				CreateActionEditor(node.actionName)
			end

			local disableButton = vgui.Create('DButton', node)
			disableButton:SetSize(20, 18)
			disableButton:Dock(RIGHT)
			
			disableButton:SetText('')
			disableButton:SetIcon(v.Disable and 'icon16/delete.png' or 'icon16/accept.png')
			
			disableButton.DoClick = function()
				
			end

		end
	end

	actionManager:RefreshNode()
	panel:AddItem(actionManager)

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)

	UPar.ActionManager = actionManager

	hook.Add('UParRegister', 'upar.update.actionmanager', function()
		actionManager:RefreshNode()
	end)
end

hook.Add('PopulateToolMenu', 'upar.menu.actionmanager', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.actionmanager', 
		'#upgui.menu.actionmanager', '', '', 
		CreateMenu
	)
end)
