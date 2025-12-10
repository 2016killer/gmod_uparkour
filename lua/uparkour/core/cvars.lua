--[[
	作者:白狼
	2025 11 1
--]]

UPar.CreateConVars = function(convars)
	for _, v in ipairs(convars) do
		CreateConVar(v.name, v.default, v.flags or { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
	end
end

local function GetConVarPhrase(name)
	-- 替换第一个下划线为点号
	local start, ending, phrase = string.find(name, "_", 1)

	if start == nil then
		return name
	else
		return '#' .. name:sub(1, start - 1) .. '.' .. name:sub(ending + 1)
	end
end

UPar.CreateConVarMenu = function(panel, convars)
	for _, v in ipairs(convars) do
		local name = v.name
		local widget = v.widget or 'NumSlider'
		local default = v.default or '0'
		local label = v.label or GetConVarPhrase(name)

		if widget == 'NumSlider' then
			panel:NumSlider(
				label, 
				name, 
				v.min or 0, v.max or 1, 
				v.decimals or 2
			)
		elseif widget == 'CheckBox' then
			panel:CheckBox(label, name)
		elseif widget == 'ComboBox' then
			panel:ComboBox(
				label, 
				name, 
				v.choices or {}
			)
		elseif widget == 'TextEntry' then
			panel:TextEntry(label, name)
		elseif widget == 'KeyBinder' then
			panel:KeyBinder(label, name)
		end

		if v.help then
			if isstring(v.help) then
				panel:ControlHelp(v.help)
			else
				panel:ControlHelp(label .. '.' .. 'help')
			end
		end
	end
	
	local defaultButton = panel:Button('#default')
	defaultButton.DoClick = function()
		for _, v in ipairs(convars) do
			RunConsoleCommand(v.name, v.default or '0')
		end
	end

	panel:Help('')
end