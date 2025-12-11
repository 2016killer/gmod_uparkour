--[[
	作者:白狼
	2025 11 5

	为了解决nil导致的打包问题, 所有nil都被替换为空字符串
	-- NWBatch 较为脆弱, 需要精确传入数据大小
--]]


local UPNW_FLAG_START = 'START'
local UPNW_FLAG_END = 'END'
local UPNW_FLAG_INTERRUPT = 'INTERRUPT'
local UPNW_FLAG_RHYTHM_CHANGE = 'RHYTHM_CHANGE'

local function ParseNWBatch(batch)
	local result = {}
	local batchSize = #batch
	local fPoint = 1
	while fPoint <= batchSize do
		local flag = batch[fPoint]
		local actionName = batch[fPoint + 1]
		local dataSize = batch[fPoint + 2]
		dataSize = math.max(isnumber(dataSize) and dataSize or 1, 1)

		table.insert(result, {
			flag = flag,
			actionName = actionName,
			dataSize = dataSize,
			data = {unpack(batch, fPoint + 3, fPoint + 2 + dataSize)},
		})

		fPoint = fPoint + 3 + dataSize
	end

	return result
end

UPar.ParseNWBatch = ParseNWBatch

if SERVER then
	-- NWBatch 较为脆弱, 需要精确传入数据大小
	util.AddNetworkString('UParNWEventBatch')

	UPar.NWBatchInit = function(ply, channelId)
		if not IsValid(ply) or not ply:IsPlayer() then
			error('Invalid ply\n') 
		end

		local netkey = 'upnwbatch_' .. (channelId or '')
		local target = ply[netkey]

		if istable(target) then 
			print('[UPar]: Warning: NWBatchInit already initialized\n')
		end

		ply[netkey] = {}
	end

	UPar.NWWriteBatch = function(ply, channelId, flag, actionName, data, dataSize)
		if not IsValid(ply) or not ply:IsPlayer() then
			error('Invalid ply\n') 
		end

		local netkey = 'upnwbatch_' .. (channelId or '')
		local target = ply[netkey]

		table.Add(target, {flag, actionName, dataSize})
		table.Add(target, data)
	end

	UPar.NWSendBatch = function(ply, channelId)
		if not IsValid(ply) or not ply:IsPlayer() then
			error('Invalid ply\n') 
		end

		local netkey = 'upnwbatch_' .. (channelId or '')
		local target = ply[netkey]

		if not istable(target) then 
			error('Failure to use NWBatchInit or a transmission conflict has occurred\n') 
		end

		net.Start('UParNWEventBatch')
			net.WriteTable(target, true)
		net.Send(ply)
		ply[netkey] = nil
	end
elseif CLIENT then
	net.Receive('UParNWEventBatch', function(len, ply)
		local data = net.ReadTable(true)
		local result = ThreadNWParseBatch(data)

		local action = UPar.GetAction(actionName)
		if not action then 
			return 
		end
		for _, v in ipairs(result) do
			local flag = v.flag
			local actionName = v.actionName
			local dataSize = v.dataSize
			local data = v.data

			if flag == UPNW_FLAG_START then
				action:Start(ply, unpack(result))
			elseif flag == UPNW_FLAG_END then
				action:Clear(ply, nil, nil, unpack(result, 2))
			elseif flag == UPNW_FLAG_INTERRUPT then
				// action:Interrupt(ply, unpack(result, 2))
			elseif flag == UPNW_FLAG_RHYTHM_CHANGE then
				// action:RhythmChange(ply, unpack(result, 2))
			end
		end
	end)
end

if SERVER then
	function a1() return 1 end
	function a2() return 1, nil end
	function a3() return 1, nil, nil end

	local a1, a1size = PackResult(a1())
	local a2, a2size = PackResult(a2())
	local a3, a3size = PackResult(a3())

	local ply = Entity(1)
	UPar.NWBatchInit(ply, nil)
		UPar.NWWriteBatch(ply, nil, UPNW_FLAG_START, 'testAction', a1, a1size)
		UPar.NWWriteBatch(ply, nil, UPNW_FLAG_END, 'testAction', a2, a2size)
		UPar.NWWriteBatch(ply, nil, UPNW_FLAG_INTERRUPT, 'testAction', a3, a3size)
		UPar.NWWriteBatch(ply, nil, UPNW_FLAG_RHYTHM_CHANGE, 'testAction', a3, a3size)
		
		PrintTable(ply['upnwbatch_'])
	UPar.NWSendBatch(ply, nil)
end

UPar.Trigger = function(ply, action, checkResult, channelId, ...)
	-- checkResult 用于绕过Check, 直接执行

	local actionName = action.Name
	local actionChannelKey = 'uptri_act_' .. (channelId or '')
	local checkResultChannelKey = 'uptri_check_' .. (channelId or '')
	

	-- 检查中断
	local playing = ply[actionChannelKey]
	local playingData = ply[checkResultChannelKey]
	if SERVER and playing and not playing.Interrupts[actionName] then
		return
	end

	checkResult = istable(checkResult) and checkResult or HandleResult(action:Check(ply, ...))
	if not checkResult then
		return checkResult, false
	end

	if playing then
		-- 检查中断函数
		local interruptFunc = playing.InterruptsFunc[actionName]
		if isfunction(interruptFunc) then
			if not interruptFunc(ply, playing, unpack(playingData)) then
				return
			end
		elseif istable(interruptFunc) then
			local flag = true
			for i, func in ipairs(interruptFunc) do
				flag = flag and func(ply, playing, unpack(playingData))
			end

			if not flag then 
				return 
			end
		end

		ply.upar_playing = nil
		ply.upar_playing_data = nil
	end

	if SERVER then
		StartTriggerNet(ply)
			action:Start(ply, unpack(checkResult))

			-- 执行特效
			local effect = GetPlayerCurrentEffect(ply, action)
			if effect then 
				effect:start(ply, unpack(checkResult)) 
			end

			-- 启动播放
			ply.upar_playing = action
			ply.upar_playing_data = checkResult

			if playing then
				WriteInterrupt(ply, playing.Name, playingData, actionName)
			end
			WriteStart(ply, actionName, checkResult)
		SendTriggerNet(ply)

		if playing then
			hook.Run('UParInterrupt', ply, playing, playingData, action, checkResult)
		end
		hook.Run('UParStart', ply, action, checkResult)
	elseif CLIENT then
		net.Start('UParStart')
			net.WriteString(actionName)
			net.WriteTable(checkResult)
		net.SendToServer()
	end

	return checkResult, true
end


if SERVER then
	local function ForceEnd(ply)
		local playing = ply.upar_playing
		local playingData = ply.upar_playing_data

		ply.upar_playing = nil
		ply.upar_playing_data = nil

		if playing then	
			playing:Clear(ply)
			local effect = GetPlayerCurrentEffect(ply, playing)
			if effect then 
				effect:clear(ply) 
			end

			StartTriggerNet(ply)
				WriteEnd(ply, playing.Name, {})
				WriteMoveControl(ply, false, false, 0, 0)
			SendTriggerNet(ply)

			hook.Run('UParEnd', ply, action, {})
		else
			StartTriggerNet(ply)
				WriteMoveControl(ply, false, false, 0, 0)
			SendTriggerNet(ply)
		end
	end

	util.AddNetworkString('UParStart')
	

	net.Receive('UParStart', function(len, ply)
		local actionName = net.ReadString()
		local checkResult = net.ReadTable()

		local action = GetAction(actionName)
		if not action then 
			return 
		end

		UPar.Trigger(ply, action, checkResult)
	end)

	hook.Add('SetupMove', 'upar.play', function(ply, mv, cmd)
		local playing = ply.upar_playing
		if not playing then 
			return 
		end

		local playingData = ply.upar_playing_data

		local endResult = table.Pack(pcall(playing.Play, playing, ply, mv, cmd, unpack(playingData)))

		-- 异常处理
		local succ, err = endResult[1], endResult[2]
		if not succ then
			ForceEnd(ply)
			error(string.format('Action "%s" Play error: %s\n', playing.Name, err))
			return
		end

		if not endResult[2] then
			return
		end

		if endResult then
			ply.upar_playing = nil
			ply.upar_playing_data = nil
			StartTriggerNet(ply)
				playing:Clear(ply, mv, cmd, unpack(endResult, 2))

				local effect = GetPlayerCurrentEffect(ply, playing)
				if effect then 
					effect:clear(ply, unpack(endResult, 2)) 
				end

				-- 这里endResult第一位是pcall的返回值, 客户端需要去掉
				WriteEnd(ply, playing.Name, endResult)
				WriteMoveControl(ply, false, false, 0, 0)
			SendTriggerNet(ply)

			hook.Run('UParEnd', ply, playing, endResult)
		end
	end)

	hook.Add('PlayerSpawn', 'upar.clear', ForceEnd)

	hook.Add('PlayerDeath', 'upar.clear', ForceEnd)

	hook.Add('PlayerSilentDeath', 'upar.clear', ForceEnd)

	concommand.Add('up_forceend', ForceEnd)
elseif CLIENT then
	local MoveControl = {
		enable = false,
		ClearMovement = false,
		RemoveKeys = 0,
		AddKeys = 0,
	}
	
	hook.Add('CreateMove', 'upar.move.control', function(cmd)
		if not MoveControl.enable then return end
		if MoveControl.ClearMovement then
			cmd:ClearMovement()
		end

		local RemoveKeys = MoveControl.RemoveKeys
		if isnumber(RemoveKeys) and RemoveKeys ~= 0 then
			cmd:RemoveKey(RemoveKeys)
		end

		local AddKeys = MoveControl.AddKeys
		if isnumber(AddKeys) and AddKeys ~= 0 then
			cmd:AddKey(AddKeys)
		end
	end)

	UPar.MoveControl = MoveControl
	UPar.SetMoveControl = function(enable, clearMovement, removeKeys, addKeys)
		MoveControl.enable = enable
		MoveControl.ClearMovement = clearMovement
		MoveControl.RemoveKeys = removeKeys
		MoveControl.AddKeys = addKeys
	end
end

UPar.HandleResult = HandleResult

UPar.GetPlaying = function(ply)
	return ply.upar_playing
end

UPar.GetPlayingData = function(ply)
	return ply.upar_playing_data
end

UPar.SetPlayingData = function(ply, data)
	ply.upar_playing_data = data
end

UPar.GeneralInterruptFunc = function(ply, action, ...)
	local effect = GetPlayerCurrentEffect(ply, action)
	if effect then effect:clear(ply, ...) end
	// UPar.printdata('-----fuck you Interrupt-----', ply, ...)
	return true
end