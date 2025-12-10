--[[
	作者:白狼
	2025 12 09
--]]

local white = Color(255, 255, 255)
-- ==================== 特效管理器 ===============
local EffectManager = {}

EffectManager.EditorKeyFilter = {
	AAAContributor = true,
	AAADescription = true,
	Name = true,
	linkName = true,
	label = true,
	icon = true
}

EffectManager.EditorFilter = function(_, val) 
	return isfunction(val) or ismatrix(val) or isentity(val) or ispanel(val) or istable(val)
end

EffectManager.PreviewKeyFilter = {
	Name = true,
	linkName = true,
	label = true,
	icon = true
}

EffectManager.PreviewFilter = function(_, val) 
	return false
end

EffectManager.PreviewKeyImportant = {
	AAAContributor = Color(0, 170, 255),
	AAADescription = Color(0, 170, 255),
}

function EffectManager:CreateEffectPreview(effect)
	if not istable(effect) then
		return
	end

	local mainPanel = vgui.Create('DPanel')
	local customButton = vgui.Create('DButton', mainPanel)
	customButton:SetText('#upgui.custom')
	customButton:SetIcon('icon64/tool.png')
	customButton.DoClick = function()
		self:OnClickCustomButton(effect.Name)
	end
	customButton:Dock(TOP)
	customButton:DockMargin(0, 5, 0, 5)

	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	scrollPanel:Dock(FILL)

	if effect.upgui_prop_PreviewOverride then
		effect:upgui_prop_PreviewOverride(scrollPanel, self)
		return mainPanel
	end

	local keyFilter = effect.upgui_prop_previewKeyFilter or self.PreviewKeyFilter
	local funcFilter = effect.upgui_prop_PreviewFilter or self.PreviewFilter
	local keyImportant = effect.upgui_prop_previewKeyImportant or self.PreviewKeyImportant

	local preview = vgui.Create('UParTablePreview', scrollPanel)
	preview:Dock(FILL)
	preview:Init2(effect, keyFilter, funcFilter, keyImportant)
	preview:SetLabel(string.format('%s %s %s', 
		effect.Name, 
		language.GetPhrase('#upgui.property'),
		''
	))

	return mainPanel
end

function EffectManager:CreateEffectEditor(effect)
	if not istable(effect) then
		return
	end

	local mainPanel = vgui.Create('DPanel')

	local saveButton = vgui.Create('DButton', mainPanel)
	saveButton:Dock(TOP)
	saveButton:DockMargin(0, 5, 0, 5)
	saveButton:SetText('#upgui.save')
	saveButton:SetIcon('icon16/application_put.png')
	saveButton.DoClick = function()
		local actionName = self.actionName

		local effectConfig = LocalPlayer().upar_effect_config
		local customEffects = LocalPlayer().upar_effects_custom

		effectConfig[actionName] = 'Custom'
		customEffects[actionName] = effect

		UPar.InitCustomEffect(actionName, effect)

		UPar.SaveUserDataToDisk(effectConfig, 'upar/effect_config.json')
		UPar.SaveUserDataToDisk(customEffects, 'upar/effects_custom.json')
	
		UPar.SendEffectConfigToServer(effectConfig)
		UPar.SendCustomEffectsToServer(customEffects)
		PrintTable(effectConfig)
		PrintTable(customEffects)

		self:PlayEffect(selNode.effectName)
		self:ChangeEffectConfig(selNode.effectName)
		self:ChangeHitNode(selNode)


		self:OnClickSaveButton(effect.Name)
	end

	local playButton = vgui.Create('DButton', mainPanel)
	playButton:Dock(TOP)
	playButton:DockMargin(0, 5, 0, 5)
	playButton:SetText('#upgui.playeffect')
	playButton:SetIcon('icon16/cd_go.png')
	playButton.DoClick = function()
		self:PlayEffect(effect.Name)
		saveButton:DoClick()
		self:OnClickPlayButton(effect.Name)
	end

	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	scrollPanel:Dock(FILL)

	if effect.upgui_prop_EditorOverride then
		effect:upgui_prop_EditorOverride(scrollPanel, self)
		return mainPanel
	end

	local keyFilter = effect.upgui_prop_editorKeyFilter or self.EditorKeyFilter
	local funcFilter = effect.upgui_prop_EditorFilter or self.EditorFilter
	local funcExpandedWidget = effect.upgui_prop_EditorExpandedWidget or nil

	local editor = vgui.Create('UParTableEditor', scrollPanel)
	editor:Dock(FILL)
	editor:Init2(effect, keyFilter, funcFilter, funcExpandedWidget)

	editor:SetLabel(language.GetPhrase('#upgui.link') .. ':' .. effect.linkName)

	return mainPanel
end

function EffectManager:Init2(action)
	local actionName = action.Name
	// self.action = nil
	// self.actionName = nil
	// self.effectTree = nil
	// self.div = nil

	local effectTree = vgui.Create('DTree')
	
	local Effects = {}
	for k, v in pairs(action.Effects) do Effects[k] = v end

	local keys = {}
	for k, v in pairs(action.Effects) do table.insert(keys, k) end
	table.sort(keys)

	local customEffect = LocalPlayer().upar_effects_custom[actionName]
	if customEffect then 
		table.insert(keys, 1, 'Custom')
		Effects['Custom'] = customEffect
	end

	for _, effectName in pairs(keys) do
		local effect = Effects[effectName]

		local label = isstring(effect.label) and effect.label or effectName
		local icon = isstring(effect.icon) and effect.icon or 'icon16/attach.png'

		local node = effectTree:AddNode(label, icon)
		node.effectName = effectName
		node.icon = icon

		local playButton = vgui.Create('DButton', node)
		playButton:SetSize(60, 18)
		playButton:Dock(RIGHT)
		playButton:SetText('#upgui.playeffect')
		playButton:SetIcon('icon16/cd_go.png')
		playButton.DoClick = function()
			UPar.EffectTest(LocalPlayer(), actionName, effectName)

			self:PlayEffect(selNode.effectName)
			self:ChangeEffectConfig(selNode.effectName)
			self:ChangeHitNode(selNode)

			self:OnClickPlayButton(effectName)
		end

		if LocalPlayer().upar_effect_config[action.Name] == effectName then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end

	effectTree.OnNodeSelected = function(_, selNode)
		self:OnNodeSelected(selNode)
	end

	local div = vgui.Create('DHorizontalDivider', self)
	div:Dock(FILL)
	div:SetDividerWidth(10)
	div:SetLeft(effectTree)

	self.action = action
	self.actionName = actionName
	self.effectTree = effectTree
	self.div = div
end

function EffectManager:SetLeftWidth(w)
	if not IsValid(self.div) then return end
	self.div:SetLeftWidth(w)
end

function EffectManager:OnNodeSelected(selNode)
	local clicktime = CurTime()

	if self.selNodeLast ~= selNode then
		if IsValid(self.div:GetRight()) then 
			self.div:GetRight():Remove() 
		end
		
		local action, actionName, effectName = self.action, self.actionName, selNode.effectName
		
		local effect = UPar.GetPlayerEffect(LocalPlayer(), action, effectName)
		local iscustom = !!effect.linkName

		local rightPanel = nil
		
		if iscustom then
			rightPanel = self:CreateEffectEditor(effect)
		else
			rightPanel = self:CreateEffectPreview(effect)
		end
		rightPanel:SetParent(effectPanel)
		
		self.div:SetRight(rightPanel)

		self:OnSelectedChange(selNode.effectName, selNode)
	elseif clicktime - self.clickTimeLast < 0.2 then
		self:PlayEffect(selNode.effectName)
		self:ChangeEffectConfig(selNode.effectName)
		self:ChangeHitNode(selNode)
		self:OnDoubleSelect(selNode.effectName, selNode)

		return
	end

	self.selNodeLast = selNode
	self.clickTimeLast = clicktime
end

function EffectManager:ChangeHitNode(node)
	if self.hitNode == node then 
		return 
	end

	node:SetIcon('icon16/accept.png')
	if IsValid(self.hitNode) then 
		self.hitNode:SetIcon(self.hitNode.icon) 
	end

	self.hitNode = node
end

function EffectManager:ChangeEffectConfig(effectName)
	if not self.actionName then return end

	LocalPlayer().upar_effect_config[self.actionName] = effectName
	UPar.SaveUserDataToDisk(LocalPlayer().upar_effect_config, 'upar/effect_config.json')
	UPar.SendEffectConfigToServer(LocalPlayer().upar_effect_config)
end

function EffectManager:SaveCustomEffect(customEffect)
	if not self.actionName then return end

	LocalPlayer().upar_effects_custom[self.actionName] = customEffect

	UPar.InitCustomEffect(self.actionName, customEffect)

	UPar.SaveUserDataToDisk(LocalPlayer().upar_effects_custom, 'upar/effects_custom.json')
	UPar.SendCustomEffectsToServer(LocalPlayer().upar_effects_custom)
end

function EffectManager:PlayEffect(effectName)
	local actionName = self.actionName
	if not actionName or not effectName then return end
	UPar.EffectTest(LocalPlayer(), actionName, effectName)
end

EffectManager.OnClickPlayButton = UPar.emptyfunc
EffectManager.OnClickSaveButton = UPar.emptyfunc
EffectManager.OnSelectedChange = UPar.emptyfunc
EffectManager.OnDoubleSelect = UPar.emptyfunc
EffectManager.OnClickCustomButton = UPar.emptyfunc

// EffectManager.OnClickPlayButton = function(self, ...) print('OnClickPlayButton', ...) end
// EffectManager.OnClickSaveButton = function(self, ...) print('OnClickSaveButton', ...) end
// EffectManager.OnSelectedChange = function(self, ...) print('OnSelectedChange', ...) end
// EffectManager.OnDoubleSelect = function(self, ...) print('OnDoubleSelect', ...) end
// EffectManager.OnClickCustomButton = function(self, ...) print('OnClickCustomButton', ...) end

vgui.Register('UParEffectManager', EffectManager, 'DPanel')
EffectManager = nil

		// curSelNode = selNode

		// effectConfig[action.Name] = selNode.effectName
		
		// UPar.SendEffectConfigToServer(effectConfig)
		// UPar.SaveUserDataToDisk(effectConfig, 'upar/effect_config.json')
		// UPar.EffectTest(LocalPlayer(), action.Name, selNode.effectName)

	// saveButton.DoClick = function()

	// end
	// playButton.DoClick = function()
	// 	UPar.EffectTest(LocalPlayer(), actionName, 'Custom')
	// 	saveButton:DoClick()
	// end

