--[[
	作者:白狼
	2025 11 5
]]--

-- ==================== 生命期测试 ===============
if not GetConVar('developer'):GetBool() then return end

local actionName = 'LifeCycleTest'
local action, _ = UPar.Register(actionName)

UPar.RegisterEffect(actionName, 'default')

function action:Check(ply, ...)
	UPar.printdata('Check', ply, ...)
	return CurTime(), 'that', 'is', 'shit', 'check'
end

function action:Start(ply, ...)
	UPar.printdata('Start', ply, ...)
end

function action:Play(ply, mv, cmd, ...)
	local starttime = select(1, ...)
	local curtime = CurTime()
	if curtime - starttime > 2 then
		UPar.printdata('Play', ply, ...)
		return curtime, 'oh', 'my', 'god', 'play', 'end'
	end
	return false
end

function action:Clear(ply, ...)
	UPar.printdata('Clear', ply, ...)
end

if CLIENT then
	action.CreateOptionMenu = function(panel)
		local testButton = panel:Button('Test', '')
		testButton.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, false, 'Shit', 'fuck')
		end

		local accidentBreakTestButton = panel:Button('Accident Break Test', '')
		accidentBreakTestButton.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, false, 'Shit', 'fuck')
			timer.Simple(1, function()
				RunConsoleCommand('kill')
			end)
		end

		local interruptTestButton = panel:Button('Interrupt Test', '')
		interruptTestButton.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, false, 'Shit', 'fuck')
			local interruptAction = UPar.GetAction('InterruptTest')
			timer.Simple(1, function()
				UPar.Trigger(LocalPlayer(), interruptAction)
			end)
		end

	end
end
