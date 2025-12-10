--[[
	作者:白狼
	2025 11 1

	常用函数:
		UPar.RegisterEffect 
			不推荐使用, 因为它不支持覆盖, 这对开发不利, 除非将代码写的很难看
			通常我们在开发默认特效时会使用它
			详细例子见 effects/dp_highclimb_effect.lua
		UPar.RegisterEffectEasy 
			是推荐使用的, 因为它支持覆盖
			但是它的行为是和自定义特效类似的, 只改变可序列化的数据
			通常在effectseasy中使用, 详细例子见 effectseasy/dp_easy.lua
--]]

--[[
	Author: 白狼
	2025-11-01

	Commonly used functions:
		UPar.RegisterEffect 
			Not recommended for use, as it does not support overriding – this is detrimental to development, unless the code is written in a cumbersome/messy way.
			We typically use it when developing default effects.
			For detailed examples, see effects/dp_highclimb_effect.lua
		UPar.RegisterEffectEasy 
			Recommended for use, as it supports overriding.
			However, its behavior is similar to that of custom effects, only modifying serializable data.
			It is typically used in the effectseasy directory; for detailed examples, see effectseasy/dp_easy.lua
--]]

local UPar = UPar

file.CreateDir('uparkour_effect')
file.CreateDir('uparkour_effect/custom')


UPar.GeneralEffectClear = function(self, ply, isInterrupt)
	if SERVER then
		ply:SetNWString('UP_WOS', '')
	elseif CLIENT then
		if isInterrupt then
			VManip:Remove()
		else
			local currentAnim = VManip:GetCurrentAnim()
			if currentAnim and currentAnim == self.VManipAnim then
				VManip:QuitHolding(currentAnim)
			end
		end
	end
end

UPar.RegisterEffect = function(actionName, effectName, effect)
	-- 注册动作特效, 返回特效和是否已存在
	-- 不支持覆盖

	local action = UPar.Register(actionName)

	local exist
	if istable(action.Effects[effectName]) then
		effect = action.Effects[effectName]
		exist = true
	elseif istable(effect) then
		action.Effects[effectName] = effect
		exist = false
	else
		effect = {}
		action.Effects[effectName] = effect
		exist = false
	end
	
	effect.Name = effectName
	effect.start = effect.start or function(self, ply, ...)
		-- 特效
		UPar.printdata(
			string.format('start Action "%s" Effect "%s"', actionName, effectName),
			ply, ...
		)
	end

	effect.clear = effect.clear or function(self, ply, ...)
		-- 当中断或强制退出时enddata为nil, 否则为表
		-- 强制中断时 breaker 为 true	
		-- 清除特效
		UPar.printdata(
			string.format('clear Action "%s" Effect "%s"', actionName, effectName),
			ply, ...
		)
	end

	return effect, exist
end

UPar.RegisterEffectEasy = function(actionName, effectName, effect)
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

UPar.GetEffect = function(action, effectName)
	-- 从全局特效中获取, 不存在返回nil
	return action.Effects[effectName]
end

UPar.GetPlayerEffect = function(ply, action, effectName)
	if effectName == 'Custom' then
		return ply.upar_effects_custom[action.Name]
	else
		return action.Effects[effectName]
	end
end

UPar.GetPlayerCurrentEffect = function(ply, action)
	-- 获取指定玩家动作的当前特效
	return UPar.GetPlayerEffect(ply, action, ply.upar_effect_config[action.Name] or 'default')
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

	local vecpunch_vel = Vector()
	local vecpunch_offset = Vector()

	local angpunch_vel = Vector()
	local angpunch_offset = Vector()

	local punch = false

	hook.Add('CalcView', 'upar.punch', function(ply, pos, angles, fov)
		if not punch then return end

		local dt = FrameTime()
		local vecacc = -(vecpunch_offset * 50 + 10 * vecpunch_vel)
		vecpunch_offset = vecpunch_offset + vecpunch_vel * dt 
		vecpunch_vel = vecpunch_vel + vecacc * dt	

		local angacc = -(angpunch_offset * 50 + 10 * angpunch_vel)
		angpunch_offset = angpunch_offset + angpunch_vel * dt 
		angpunch_vel = angpunch_vel + angacc * dt	

		local view = GAMEMODE:CalcView(ply, pos, angles, fov) 
		local eyeAngles = view.angles - ply:GetViewPunchAngles()

		view.origin = view.origin + eyeAngles:Forward() * vecpunch_offset.x +
			eyeAngles:Right() * vecpunch_offset.y +
			eyeAngles:Up() * vecpunch_offset.z

		view.angles = view.angles + Angle(angpunch_offset.x, angpunch_offset.y, angpunch_offset.z)

		local vecoffsetLen = vecpunch_offset:LengthSqr()
		local angoffsetLen = angpunch_offset:LengthSqr()
		local vecvelLen = vecpunch_vel:LengthSqr()
		local angvelLen = angpunch_vel:LengthSqr()

		if vecoffsetLen < 0.1 and vecvelLen < 0.1 and angoffsetLen < 0.1 and angvelLen < 0.1 then
			vecpunch_offset = Vector()
			vecpunch_vel = Vector()

			angpunch_offset = Vector()
			angpunch_vel = Vector()

			punch = false
		end

		return view
	end)

	UPar.SetVecPunchOffset = function(vec)
		punch = true
		vecpunch_offset = vec
	end

	UPar.SetAngPunchOffset = function(vec)
		punch = true
		angpunch_offset = ang
	end

	UPar.SetVecPunchVel = function(vec)
		punch = true
		vecpunch_vel = vec
	end

	UPar.SetAngPunchVel = function(vec)
		punch = true
		angpunch_vel = vec
	end

	UPar.GetVecPunchOffset = function() return vecpunch_offset end
	UPar.GetAngPunchOffset = function() return angpunch_offset end
	UPar.GetVecPunchVel = function() return vecpunch_vel end
	UPar.GetAngPunchVel = function() return angpunch_vel end
end
