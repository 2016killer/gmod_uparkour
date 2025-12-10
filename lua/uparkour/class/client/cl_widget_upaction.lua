--[[
	作者:白狼
	2025 12 09
	
	大部分主要的控件在这里
	大部分控件都是一次性的, 不支持动态刷新
	可以拓展的部分:
		1. 控制特效界面键值对的可见性
		effect.upgui_prop_previewKeyFilter = {HideKeyExample = true, ...}
		effect.upgui_prop_editorKeyFilter(self, tree) = ...

		effect.upgui_prop_PreviewFilter = function(key, val) return key == 'HideKeyExample' end
		effect.upgui_prop_EditorFilter = ...

		2. 控制特效界面键值对的颜色
		effect.upgui_prop_previewKeyImportant = {RedKey = Color(255, 0, 0), ...}

		3. 拓展特殊类型数据的编辑器
		effect.upgui_prop_EditorExpandedWidget = function(key, val, originWidget)
			if IsColor(val) then
				if IsValid(originWidget) then originWidget:Remove() end
				return vgui.Create('ExampleColorInputWidget') 
			end 
		end

		4. 覆盖整个编辑器
		effect:upgui_prop_EditorOverride = function(self, scrollPanel, editor)
			return vgui.Create('ExampleEditorWidget')
		end

		4. 覆盖整个预览界面
		effect.upgui_prop_PreviewOverride = function(self, scrollPanel, editor)
			return vgui.Create('ExamplePreviewWidget')
		end
		
		5. 自定义动作参数界面
		-- 旧版 (不会删除)
		action.CreateOptionMenu = function(form)
			...
		end

		action.upgui_CreateMenus = {
			label = 'ExampleMenu',
			func = function(form)
				...
			end
		}
--]]
--[[
	Author: 白狼
	2025-12-09
	Most of the main widgets are located here
	Most widgets are one-time use and do not support dynamic refresh
	Extensible parts:

		1. Control the visibility of key-value pairs in the effect interface
		effect.upgui_prop_previewKeyFilter = {HideKeyExample = true, ...}
		effect.upgui_prop_editorKeyFilter(self, tree) = ...

		effect.upgui_prop_PreviewFilter = function(key, val) return key == 'HideKeyExample' end
		effect.upgui_prop_EditorFilter = ...

		2. Control the color of key-value pairs in the effect interface
		effect.upgui_prop_previewKeyImportant = {RedKey = Color(255, 0, 0), ...}

		3. Extend the editor for special type data
		effect.upgui_prop_EditorExpandedWidget = function(key, val, originWidget)
			if IsColor(val) then
				if IsValid(originWidget) then originWidget:Remove() end
				return vgui.Create('ExampleColorInputWidget') 
			end 
		end

		4. Override the entire editor
		effect:upgui_prop_EditorOverride = function(self, scrollPanel, editor)
			return vgui.Create('ExampleEditorWidget')
		end

		4. Override the entire preview interface
		effect.upgui_prop_PreviewOverride = function(self, scrollPanel, editor)
			return vgui.Create('ExamplePreviewWidget')
		end

		5. Customize the action parameter interface
		-- Legacy version (will not be removed)
		action.CreateOptionMenu = function(form)
			...
		end

		action.upgui_CreateMenus = {
			label = 'ExampleMenu',
			func = function(form)
				...
			end
		}
]]

UPar.SnakeTranslate = function(key, prefix, sep, joint)
	-- 在项目中, 这将作为默认情况下action名字的翻译行为 (label为非字符串)
	-- 同时, 在树编辑器中所有的键名也会使用此翻译, 分隔符采用 '-'
	-- 'DParkour-LowClimb' --> '#upgui.DParkour' + '.' + '#upgui.LowClimb'

	prefix = prefix or 'upgui'
	sep = sep or '_'
	joint = joint or '.'

	local split = string.Split(key, sep)
	
	for i, v in ipairs(split) do
		split[i] = language.GetPhrase(string.format('#%s.%s', prefix, v))
	end

	return table.concat(split, joint, 1, #split)
end

local black = Color(0, 0, 0)
local grey = Color(170, 170, 170)
local white = Color(255, 255, 255)

-- ==================== 向量输入框 ===============
local VecEditor = {}
function VecEditor:Init()
	local inputX = vgui.Create('DNumberWang', self)
	local inputY = vgui.Create('DNumberWang', self)
	local inputZ = vgui.Create('DNumberWang', self)

	inputX.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[1] = newVal end
		self:OnChange(self:GetValue())
	end

	inputY.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[2] = newVal end
		self:OnChange(self:GetValue())
	end

	inputZ.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[3] = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputX = inputX
	self.inputY = inputY
	self.inputZ = inputZ

	self:OnSizeChanged(self:GetWide(), self:GetTall())

	self:SetInterval(0.5)
	self:SetDecimals(2)
	self:SetMinMax(-10000, 10000)
end

function VecEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 3

	self.inputX:SetPos(0, 0)
	self.inputY:SetPos(div, 0)
	self.inputZ:SetPos(div * 2, 0)

	self.inputX:SetWidth(div)
	self.inputY:SetWidth(div)
	self.inputZ:SetWidth(div)
end

function VecEditor:SetValue(vec)
	if not isvector(vec) then 
		error(string.format('vec "%s" is not a vector\n', vec))
		return 
	end

	self.inputX:SetValue(vec[1])
	self.inputY:SetValue(vec[2])
	self.inputZ:SetValue(vec[3])
	self.bindVec = vec
end

function VecEditor:GetValue()
	return isvector(self.bindVec) and self.bindVec or Vector(
		self.inputX:GetValue(), 
		self.inputY:GetValue(), 
		self.inputZ:GetValue()
	)
end

function VecEditor:SetMinMax(min, max)
	self.inputX:SetMinMax(min, max)
	self.inputY:SetMinMax(min, max)
	self.inputZ:SetMinMax(min, max)
end

function VecEditor:SetDecimals(decimals)
	self.inputX:SetDecimals(decimals)
	self.inputY:SetDecimals(decimals)
	self.inputZ:SetDecimals(decimals)
end

function VecEditor:SetInterval(interval)
	self.inputX:SetInterval(interval)
	self.inputY:SetInterval(interval)
	self.inputZ:SetInterval(interval)
end

function VecEditor:SetMin(min)
	self.inputX:SetMin(min)
	self.inputY:SetMin(min)
	self.inputZ:SetMin(min)
end

function VecEditor:SetMax(max)
	self.inputX:SetMax(max)
	self.inputY:SetMax(max)
	self.inputZ:SetMax(max)
end

function VecEditor:SetFraction(frac)
	self.inputX:SetFraction(frac)
	self.inputY:SetFraction(frac)
	self.inputZ:SetFraction(frac)
end

VecEditor.OnChange = UPar.emptyfunc

vgui.Register('UParVecEditor', VecEditor, 'DPanel')
VecEditor = nil
-- ==================== 角度输入框 ===============
local AngEditor = {}
function AngEditor:Init()
	local inputPitch = vgui.Create('DNumberWang', self)
	local inputYaw = vgui.Create('DNumberWang', self)
	local inputRoll = vgui.Create('DNumberWang', self)

	inputPitch.OnValueChanged = function(_, newVal)
		if isangle(self.bindAng) then self.bindAng[1] = newVal end
		self:OnChange(self:GetValue())
	end

	inputYaw.OnValueChanged = function(_, newVal)
		if isangle(self.bindAng) then self.bindAng[2] = newVal end
		self:OnChange(self:GetValue())
	end

	inputRoll.OnValueChanged = function(_, newVal)
		if isangle(self.bindAng) then self.bindAng[3] = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputPitch = inputPitch
	self.inputYaw = inputYaw
	self.inputRoll = inputRoll

	self:OnSizeChanged(self:GetWide(), self:GetTall())

	self:SetInterval(0.5)
	self:SetDecimals(2)
	self:SetMinMax(-10000, 10000)
end

function AngEditor:SetValue(ang)
	if not isangle(ang) then 
		error(string.format('ang "%s" is not an angle\n', ang))
		return 
	end

	self.inputPitch:SetValue(ang[1])
	self.inputYaw:SetValue(ang[2])
	self.inputRoll:SetValue(ang[3])
	self.bindAng = ang
end

function AngEditor:GetValue()
	return isangle(self.bindAng) and self.bindAng or Angle(
		self.inputPitch:GetValue(), 
		self.inputYaw:GetValue(), 
		self.inputRoll:GetValue()
	)
end

function AngEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 3
	
	self.inputPitch:SetPos(0, 0)
	self.inputYaw:SetPos(div, 0)
	self.inputRoll:SetPos(div * 2, 0)

	self.inputPitch:SetWidth(div)
	self.inputYaw:SetWidth(div)
	self.inputRoll:SetWidth(div)
end

function AngEditor:SetMinMax(min, max)
	self.inputPitch:SetMinMax(min, max)
	self.inputYaw:SetMinMax(min, max)
	self.inputRoll:SetMinMax(min, max)
end

function AngEditor:SetDecimals(decimals)
	self.inputPitch:SetDecimals(decimals)
	self.inputYaw:SetDecimals(decimals)
	self.inputRoll:SetDecimals(decimals)
end

function AngEditor:SetInterval(interval)
	self.inputPitch:SetInterval(interval)
	self.inputYaw:SetInterval(interval)
	self.inputRoll:SetInterval(interval)
end

function AngEditor:SetMin(min)
	self.inputPitch:SetMin(min)
	self.inputYaw:SetMin(min)
	self.inputRoll:SetMin(min)
end

function AngEditor:SetMax(max)
	self.inputPitch:SetMax(max)
	self.inputYaw:SetMax(max)
	self.inputRoll:SetMax(max)
end

function AngEditor:SetFraction(frac)
	self.inputPitch:SetFraction(frac)
	self.inputYaw:SetFraction(frac)
	self.inputRoll:SetFraction(frac)
end

AngEditor.OnChange = UPar.emptyfunc

vgui.Register('UParAngEditor', AngEditor, 'DPanel')
AngEditor = nil
-- ==================== 表编辑器 ===============
-- 这里我们仅考虑字符键
-- 我们仅遍历表的第一层, 因为扁平的表更加方便、易于维护

local TableEditor = {}

function TableEditor:Init2(obj, keyFilter, funcFilter, funcExpandedWidget)
	-- keyFilter 表, 用于过滤不需要显示的键值对 例: {Example = true, ...}
	-- funcFilter 函数, 用于过滤不需要显示的键值对 例: function(key, val) return key == 'Example' end
	-- funcExpandedWidget 函数, 用于创建自定义的键值对控件 例: function(key, val, originWidget) return vgui.Create('DLabel') end

	self.obj = obj
	
	local keys = {}
	for k, _ in pairs(self.obj) do table.insert(keys, k) end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local val = self.obj[key]
		if (istable(keyFilter) and keyFilter[key]) or (isfunction(funcFilter) and funcFilter(key, val)) then
			continue
		end

		local origin = self:CreateKeyValueWidget(key, val)
		local expandedWidget = isfunction(funcExpandedWidget) and funcExpandedWidget(key, val, origin) or nil
		
		if IsValid(origin) and ispanel(origin) then
			self:AddItem(origin)
		end

		if IsValid(expandedWidget) and ispanel(expandedWidget) then
			self:AddItem(expandedWidget)
		end
	end
end

function TableEditor:CreateKeyValueWidget(key, val)
	self:Help(UPar.SnakeTranslate(key))
	if key == 'VManipAnim' or key == 'VMLegsAnim' then
		-- 针对特殊的键名进行特殊处理
		local target = key == 'VManipAnim' and VManip.Anims or VMLegs.Anims
		local anims = {}
		for a, _ in pairs(target) do table.insert(anims, a) end
		table.sort(anims)
		
		local comboBox = vgui.Create('DComboBox')
		for _, a in ipairs(anims) do comboBox:AddChoice(a, nil, a == val) end
		comboBox.OnSelect = function(_, _, newVal) self:Update(key, newVal) end

		return comboBox
	elseif isstring(val) then
		local textEntry = vgui.Create('DTextEntry')
		textEntry:SetText(val)
		textEntry.OnChange = function()
			local newVal = textEntry:GetText()
			self:Update(key, newVal)
		end

		return textEntry
	elseif isnumber(val) then
		local numberWang = vgui.Create('DNumberWang')
		numberWang:SetValue(val)
		numberWang.OnValueChanged = function(_, newVal)
			self:Update(key, newVal)
		end

		return numberWang
	elseif isbool(val) then
		local checkBox = vgui.Create('DCheckBoxLabel')
		checkBox:SetChecked(val)
		checkBox:SetText('')
		checkBox.OnChange = function(_, newVal)
			self:Update(key, newVal)
		end
		
		return checkBox
	elseif isvector(val) then
		local vecEditor = vgui.Create('UParVecEditor')
		vecEditor:SetValue(val)

		vecEditor.OnChange = function(_, newVal)
			self:Update(key, newVal)
		end

		return vecEditor
	elseif isangle(val) then
		local angEditor = vgui.Create('UParAngEditor')
		angEditor:SetValue(val)

		angEditor.OnChange = function(_, newVal)
			self:Update(key, newVal)
		end

		return angEditor
	else
		return self:ControlHelp('unknown type')
	end
end

function TableEditor:Update(key, newVal)
	self.obj[key] = newVal
end



vgui.Register('UParTableEditor', TableEditor, 'DForm')
TableEditor = nil
-- ==================== 表预览 ===============
local TablePreview = {}
function TablePreview:Init2(obj, keyFilter, funcFilter, keyImportant)
	-- keyFilter 表, 用于过滤不需要显示的键值对 例: {Example = true, ...}
	-- funcFilter 函数, 用于过滤不需要显示的键值对 例: function(key, val) return key == 'Example' end
	-- important 表, 用于指定哪些键值对需要高亮显示 例: {Example = Color(0, 255, 0), ...}

	self.obj = obj

	local keys = {}
	for k, v in pairs(self.obj) do table.insert(keys, k) end
	table.sort(keys)

	for _, k in ipairs(keys) do
		local v = self.obj[k]

		if (istable(keyFilter) and keyFilter[k]) or (isfunction(funcFilter) and funcFilter(k, v)) then
			continue
		end

		local val = v
		local key = UPar.SnakeTranslate(k)
		
		local label = self:Help(string.format('%s = %s', key, val))
		local importantCfg = istable(keyImportant) and keyImportant[k] or nil

		if not importantCfg or not IsValid(label) then
			continue
		end

		label:SetTextColor(IsColor(importantCfg) and importantCfg or Color(0, 255, 0))
	end
end

vgui.Register('UParTablePreview', TablePreview, 'DForm')
TablePreview = nil
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
-- ==================== 动作编辑器 ===============
local ActionEditor = {}

function ActionEditor:Init2(action)
	local actionName = action.Name

	self:SetSize(600, 400)
	self:SetPos(0, 0)
	self:MakePopup()
	self:SetSizable(true)
	self:SetDeleteOnClose(true)
	self:SetTitle(string.format(
		'%s   %s', 
		language.GetPhrase('#upgui.menu.actionmanager'), 
		language.GetPhrase(isstring(action.label) and action.label or actionName)
	))

	local Tabs = vgui.Create('DPropertySheet', self)
	Tabs:Dock(FILL)

	local effectManager = vgui.Create('UParEffectManager')
	effectManager:Init2(action)
	effectManager:SetLeftWidth(0.5 * self:GetWide())
	Tabs:AddSheet('#upgui.effect', effectManager, 'icon16/user.png', false, false, '')

	-- 旧版本代码
	if isfunction(action.CreateOptionMenu) then
		local scrollPanel = vgui.Create('DScrollPanel', Tabs)
		local optionPanel = vgui.Create('DForm', scrollPanel)
		optionPanel:SetLabel('#upgui.options')
		optionPanel:Dock(FILL)
		optionPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, white)
		end

		action.CreateOptionMenu(optionPanel)

		Tabs:AddSheet('#upgui.options', scrollPanel, 'icon16/wrench.png', false, false, '')
	end

	if istable(action.upgui_CreateMenus) then
		for k, v in pairs(action.upgui_CreateMenus) do
			if not istable(v) then
				print(string.format('[UPar]: action.upgui_CreateMenus - Error: v "%s" is not a table, action "%s"\n', v, actionName))
				continue
			end

			if not isfunction(v.func) then
				print(string.format('[UPar]: action.upgui_CreateMenus - Error: func "%s" is not a function, action "%s"\n', v.func, actionName))
				continue
			end

			local func = v.func
			local label = isstring(v.label) and v.label or k

			local DScrollPanel = vgui.Create('DScrollPanel', Tabs)
			local OptionPanel = vgui.Create('DForm', DScrollPanel)
			OptionPanel:SetLabel(label)
			OptionPanel:Dock(FILL)
			OptionPanel.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, white)
			end

			local success, err = pcall(func, OptionPanel)

			if not success then
				print(string.format('[UPar]: action.upgui_CreateMenus - Error: func "%s" call failed, action "%s"\n', func, actionName))
				continue
			end

			Tabs:AddSheet(label, DScrollPanel, 'icon16/wrench.png', false, false, '')
		end
	end

	self.div = effectManager.div
end


vgui.Register('UParActionEditor', ActionEditor, 'DFrame')
ActionEditor = nil


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

