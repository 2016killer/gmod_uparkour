--[[
	作者:白狼
	2025 12 09
--]]

-- ==================== 扁平表编辑器 ===============
local FlatTableEditor = {}

function FlatTableEditor:Init2(obj, keyFilter, funcFilter, funcExpandedWidget)
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

function FlatTableEditor:CreateKeyValueWidget(key, val)
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

function FlatTableEditor:Update(key, newVal)
	self.obj[key] = newVal
end

vgui.Register('UPFlatTableEditor', FlatTableEditor, 'DForm')
FlatTableEditor = nil
-- ==================== 扁平表预览 ===============
local FlatTablePreview = {}
function FlatTablePreview:Init2(obj, keyFilter, funcFilter, keyImportant)
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

vgui.Register('UPFlatTablePreview', FlatTablePreview, 'DForm')
FlatTablePreview = nil