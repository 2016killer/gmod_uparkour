--[[
	作者:白狼
	2025 11 5
]]--

-- ==================== 生命期测试 ===============
if not GetConVar('developer'):GetBool() then return end



local actionName = 'InterruptTest'
local action, _ = UPar.Register(actionName)

local function InterruptFunc(ply, action, ...)
	UPar.printdata('InterruptFunc', ply, ...)
	return true
end

UPar.EnableInterrupt('LifeCycleTest', actionName)
UPar.AddInterruptsFunc('LifeCycleTest', actionName, InterruptFunc)


action.Check = function() print('Check ' .. actionName); return true end
action.Start = function() print('Start ' .. actionName); return true end
action.Play = function() print('Play ' .. actionName); return true end
action.Clear = function() print('Clear ' .. actionName) end

