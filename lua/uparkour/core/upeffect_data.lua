--[[
	作者:白狼
	2025 11 1
--]]

local UPar = UPar

file.CreateDir('uparkour_effect')
file.CreateDir('uparkour_effect/custom')

UPar.RegisterEasy = function(actionName, effectName, initData, )
	local action = UPar.GetAction(actionName)
	if not action then
		error(string.format('Invalid action "%s"', actionName))
	end

	local defaultEffect = action:GetEffect(effectName)
	if not defaultEffect then
		error(string.format('Invalid effect "%s" for action "%s"', effectName, actionName))
		return
	end

	action.Effects[self.Name] = table.Merge(table.Copy(defaultEffect), self)
	return action.Effects[self.Name]
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

	UPar.LoadEffectConfigFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour_effect/config.json')
	end

	UPar.LoadCustomEffectCacheFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour_effect/custom_cache.json')
	end

	UPar.GetCustomEffectNamesFromDisk = function()
		return file.Find('uparkour_effect/custom/*.json', 'DATA')
	end

	UPar.LoadCustomEffectFromDisk = function(filename)
		return UPar.LoadUserDataFromDisk('uparkour_effect/custom/' .. filename)
	end

	hook.Add('KeyPress', 'upar.init.effect', function(ply, key)
		hook.Remove('KeyPress', 'upar.init.effect')

		local customEffects = UPar.LoadUserDataFromDisk('upar/effects_custom.json')
		local effectConfig = UPar.LoadUserDataFromDisk('upar/effect_config.json')
		
		UPar.SendCustomEffectsToServer(customEffects)
		UPar.SendEffectConfigToServer(effectConfig)

		-- 初始化自定义特效
		for k, v in pairs(customEffects) do
			UPar.InitCustomEffect(k, v)
		end

		ply.upar_effect_config = effectConfig or {}
		ply.upar_effects_custom = customEffects or {}
	end)
end
