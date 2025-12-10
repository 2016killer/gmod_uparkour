--[[
	作者:白狼
	2025 11 1
--]]


UPEffect = {}
UPEffect.__index = UPEffect

local function isupeffect(obj)
    if not istable(obj) then 
        return false 
    end
    local mt = getmetatable(obj)
    while mt do
        if mt == UPEffect then return true end
        local nextMt = getmetatable(mt)
        if nextMt and nextMt.__index then
            mt = nextMt.__index
        else
            break
        end
    end
    return false
end

function UPEffect:new(name, initData)
    if string.find(name, '[\\/:*?\"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local self = setmetatable({}, UPEffect)

	self.Name = name
	self.Start = self.Start or function(self, ply, ...)
		UPar.printdata(string.format('Effect "%s" Start', effectName), ply, ...)
	end

	self.Clear = self.Clear or function(self, ply, ...)
		UPar.printdata(string.format('Effect "%s" Clear', effectName), ply, ...)
	end

	self.OnRhythmChange = self.OnRhythmChange or UPar.emptyfunc

    self:SetIcon(initData.icon)
    self:SetLabel(initData.label)

    return self
end

function UPEffect:SetIcon(icon)
    if SERVER or icon == nil then return end
    if not isstring(icon) then
        error(string.format('Invalid icon "%s" (not a string)', icon))
    end
    self.icon = icon
end

function UPEffect:SetLabel(label)
    if SERVER or label == nil then return end
    if not isstring(label) then
        error(string.format('Invalid label "%s" (not a string)', label))
    end
    self.label = label
end

function UPEffect:Register(actionName)
	local action = UPar.GetAction(actionName)
    if not action then
        error(string.format('Invalid action "%s"', actionName))
    end
	action.Effects[name] = self
    hook.Run('UParRegisterEffect', actionName, name, self)
end

function UPEffect:RegisterEasy(actionName)
	-- 注册动作特效, 返回特效和是否已存在
	-- 支持覆盖
	local action = UPar.GetAction(actionName)
	if not action then
		ErrorNoHalt(string.format('[UPar]: Action "%s" not found', actionName))
		return
	end

	local default = UPar.GetEffect(action, 'default')
	if not default then
		ErrorNoHalt(string.format('[UPar]: Action "%s" has no default effect', actionName))
		return
	end

	action.Effects[effectName] = table.Merge(table.Copy(default), effect)
	action.Effects[effectName].Name = effectName
	return action.Effects[effectName]
end


UPar.EffectTest = function(ply, actionName, effectName)
	local action = UPar.GetAction(actionName)
	if not action then
		print(string.format('[UPar]: effect test failed, action "%s" not found', actionName))
		return
	end

	local effect = UPar.GetPlayerEffect(ply, action, effectName)
	-- 特效不存在
	if not effect then
		print(string.format('[UPar]: effect test failed, action "%s" effect "%s" not found', actionName, effectName))
		return
	end

	effect:start(ply)
	timer.Simple(1, function()
		effect:clear(ply)
	end)
	if CLIENT then
		net.Start('UParEffectTest')
			net.WriteString(actionName)
			net.WriteString(effectName)
		net.SendToServer()
	end
end

UPar.isupeffect = isupeffect

UPar.GetPlayerCurrentEffect = function(ply, action)
	-- 获取指定玩家动作的当前特效
	return UPar.GetPlayerEffect(ply, action, ply.upar_effect_config[action.Name] or 'default')
end

UPar.GetPlayerEffect = function(ply, action, effectName)
	if effectName == 'Custom' then
		return ply.upar_effects_custom[action.Name]
	else
		return action.Effects[effectName]
	end
end


UPar.InitCustomEffect = function(actionName, custom)
	custom.Name = 'Custom'
	local linkName = custom.linkName
	if not isstring(linkName) then
		print(string.format('[UPar]: register custom effect failed, action "%s" linkName "%s" is not string', actionName, linkName))
		return false
	end

	local action = UPar.GetAction(actionName)
	if not action then
		print(string.format('[UPar]: register custom effect failed, action "%s" not found', actionName))
		return false
	end

	local linkEffect = UPar.GetEffect(action, linkName)
	if not linkEffect then
		print(string.format('[UPar]: register custom effect failed, action "%s" effect "%s" not found', actionName, linkName))
		return false
	end

	for k, v in pairs(linkEffect) do
		if custom[k] == nil then custom[k] = v end
	end

	return true
end

UPar.CreateCustomEffect = function(actionName, linkName)
	local action = UPar.GetAction(actionName)
	if not action then
		print(string.format('[UPar]: copy action "%s" link "%s" to custom failed, action not found', actionName, linkName))
		return nil
	end

	local linkEffect = UPar.GetEffect(action, linkName)
	if not linkEffect then
		print(string.format('[UPar]: copy action "%s" link "%s" to custom failed, link not found', actionName, linkName))
		return nil
	end

	local custom = {
		Name = 'Custom',
		linkName = linkName,
		icon = 'icon64/tool.png',
	}

	return custom
end


if SERVER then
	util.AddNetworkString('UParEffectCustom')
	util.AddNetworkString('UParEffectConfig')
	util.AddNetworkString('UParEffectTest')

	net.Receive('UParEffectTest', function(len, ply)
		local actionName = net.ReadString()
		local effectName = net.ReadString()
		
		UPar.EffectTest(ply, actionName, effectName)
	end)

	net.Receive('UParEffectConfig', function(len, ply)
		local content = net.ReadString()
		// content = util.Decompress(content)

		local effectConfig = util.JSONToTable(content or '')
		if not istable(effectConfig) then
			print('[UPar]: receive effect config is not table')
			return
		end

		table.Merge(ply.upar_effect_config, effectConfig)
	end)

	net.Receive('UParEffectCustom', function(len, ply)
		local content = net.ReadString()
		// content = util.Decompress(content)

		local customEffects = util.JSONToTable(content or '')
		if not istable(customEffects) then
			print('[UPar]: receive custom effects is not table')
			return
		end

		-- 初始化自定义特效
		for k, v in pairs(customEffects) do
			UPar.InitCustomEffect(k, v)
		end

		table.Merge(ply.upar_effects_custom, customEffects)
	end)


	hook.Add('PlayerInitialSpawn', 'upar.init.effect', function(ply)
		ply.upar_effect_config = ply.upar_effect_config or {}
		ply.upar_effects_custom = ply.upar_effects_custom or {}
	end)

elseif CLIENT then
	UPar.SendCustomEffectsToServer = function(effects)
		-- 为了过滤掉一些不能序列化的数据
		local content = util.TableToJSON(effects)
		if not content then
			print('[UPar]: send custom effects to server failed, content is not valid json')
			return
		end
		// content = util.Compress(content)

		net.Start('UParEffectCustom')
			net.WriteString(content)
		net.SendToServer()
	end

	UPar.SendEffectConfigToServer = function(effectConfig)
		local content = util.TableToJSON(effectConfig)
		if not content then
			print('[UPar]: send effect config to server failed, content is not valid json')
			return
		end
		// content = util.Compress(content)

		net.Start('UParEffectConfig')
			net.WriteString(content)
		net.SendToServer()
	end
end



