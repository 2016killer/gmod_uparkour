--[[
	作者:白狼
	2025 12 10

	2.1.0 版本的数据兼容
--]]

if SERVER then return end

hook.Add('KeyPress', 'compat.2.1.0.effect_config', function(ply, key)	
	hook.Remove('KeyPress', 'compat.2.1.0.effect_config')
	
	local effectConfig = UPar.LoadUserDataFromDisk('ultipar/effect_config.json')
	local customEffects = UPar.LoadUserDataFromDisk('ultipar/effects_custom.json')
	

	local targetActions = {
		'DParkour-LowClimb',
		'DParkour-HighClimb',
		'DParkour-Vault',
	}

	local mapping = {
		['SP-VManip-白狼'] = 'default',
		['SinglePlayer-Punch-Compat-余智博'] = 'PunchCompat'
	}


	if effectConfig then
		print('检测到 effect_config.json 2.1.0 文件')
		
		for _, actionName in ipairs(targetActions) do
			local effectName = effectConfig[actionName]

			if not effectConfig[actionName] or not mapping[effectName] then
				continue
			end

			effectConfig[actionName] = mapping[effectName]
		end

	end

	if customEffects then
		print('检测到 effects_custom.json 2.1.0 文件')
	
		for _, actionName in ipairs(targetActions) do
			local customEffect = customEffects[actionName]

			if not istable(customEffect) or not mapping[customEffect.linkName] then
				continue
			end

			customEffect.linkName = mapping[customEffect.linkName]
		end
	end

	print('转换成功')
end)