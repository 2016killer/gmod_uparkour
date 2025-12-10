--[[
	作者:白狼
	2025 11 5
	Trigger: Check -> Start -> StartEffect-> Play -> Clear -> ClearEffect
--]]

UPar.TRIGGERNW_FLAG_START = 'START'
UPar.TRIGGERNW_FLAG_END = 'END'
UPar.TRIGGERNW_FLAG_INTERRUPT = 'INTERRUPT'

local TRIGGERNW_FLAG_START = UPar.TRIGGERNW_FLAG_START
local TRIGGERNW_FLAG_END = UPar.TRIGGERNW_FLAG_END
local TRIGGERNW_FLAG_INTERRUPT = UPar.TRIGGERNW_FLAG_INTERRUPT

local function HandleResult(...)
	if select(1, ...) then
		return table.Pack(...)
	else
		return nil
	end
end


local function StartTriggerNet(ply)
	ply.upar_tnet = ply.upar_tnet or {}
end

local function WriteStart(ply, actionName, data)
	local target = ply.upar_tnet
	table.Add(target, {TRIGGERNW_FLAG_START, actionName, #data})
	table.Add(target, data)
end

local function WriteEnd(ply, actionName, data)
	local target = ply.upar_tnet
	table.Add(target, {TRIGGERNW_FLAG_END, actionName, #data})
	table.Add(target, data)
end

local function WriteInterrupt(ply, actionName, data, breakerName)
	local target = ply.upar_tnet
	table.Add(target, {TRIGGERNW_FLAG_INTERRUPT, actionName, #data + 1, breakerName})
	table.Add(target, data)
end

local function WriteMoveControl(ply, enable, ClearMovement, RemoveKeys, AddKeys)
	local target = ply.upar_tnet
	table.Add(target, {TRIGGERNW_FLAG_MOVE_CONTROL,
		'', 4, enable, ClearMovement, RemoveKeys, AddKeys
	})
end

local function SendTriggerNet(ply)
	if not ply.upar_tnet then 
		error('Failure to use StartTriggerNet or a transmission conflict has occurred\n')
		return 
	end
	net.Start('UParEvents')
		net.WriteTable(ply.upar_tnet, true)
	net.Send(ply)
	ply.upar_tnet = nil
end

if SERVER then
	UPar.StartTriggerNet = StartTriggerNet
	UPar.WriteStart = WriteStart
	UPar.WriteEnd = WriteEnd
	UPar.WriteInterrupt = WriteInterrupt
	UPar.WriteMoveControl = WriteMoveControl
else
	StartTriggerNet = nil
	WriteStart = nil
	WriteEnd = nil
	WriteInterrupt = nil
	WriteMoveControl = nil
end


local GetPlayerCurrentEffect = UPar.GetPlayerCurrentEffect
local GetAction = UPar.GetAction
UPar.Trigger = function(ply, action, checkResult, ...)
	-- 动作触发器
	-- checkResult 用于绕过Check, 直接执行
	
	local actionName = action.Name

	-- 检查中断
	local playing = ply.upar_playing
	local playingData = ply.upar_playing_data
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
	util.AddNetworkString('UParEvents')

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
	function HandleTriggerData(data, point)
		point = point or 1

		local flag = data[point]
		local actionName = data[point + 1]
		local len = data[point + 2]
		
		local result = {unpack(data, point + 3, point + 2 + len)}
	
		return flag, actionName, result, point + 3 + len
	end

	local MoveControl = {}
	net.Receive('UParEvents', function(len, ply)
		local data = net.ReadTable(true)
		ply = LocalPlayer()

		local depth = 0
		local point = 1
		while point <= #data and depth < 7 do
			local flag, actionName, result, nextPoint = HandleTriggerData(data, point)
			point = nextPoint

			local action = GetAction(actionName)
			if not action and flag ~= TRIGGERNW_FLAG_MOVE_CONTROL then 
				return 
			end

			if flag == TRIGGERNW_FLAG_START then
				action:Start(ply, unpack(result))
				local effect = GetPlayerCurrentEffect(ply, action)
				if effect then 
					effect:start(ply, unpack(result)) 
				end

				hook.Run('UParStart', ply, action, result)
			elseif flag == TRIGGERNW_FLAG_END then
				action:Clear(ply, nil, nil, unpack(result, 2))
				local effect = GetPlayerCurrentEffect(ply, action)
				if effect then 
					effect:clear(ply, unpack(result, 2)) 
				end

				hook.Run('UParEnd', ply, action, result)
			elseif flag == TRIGGERNW_FLAG_MOVE_CONTROL then
				MoveControl.enable = result[1]
				MoveControl.ClearMovement = result[2]
				MoveControl.RemoveKeys = result[3]
				MoveControl.AddKeys = result[4]
			elseif flag == TRIGGERNW_FLAG_INTERRUPT then
				local breakerName = result[1]

				local interruptFunc = action.InterruptsFunc[breakerName]
				if isfunction(interruptFunc) then
					interruptFunc(ply, action, unpack(result, 2))
				elseif istable(interruptFunc) then
					for i, func in ipairs(interruptFunc) do
						func(ply, action, unpack(result, 2))
					end
				end

				hook.Run('UParInterrupt', ply, action, result, 
					GetAction(breakerName), nil
				)
			end
			depth = depth + 1
		end
	end)

	
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