--[[
	作者:白狼
	2025 12 10
--]]


local function CreateMenu(panel)
	panel:Clear()

	panel:CheckBox('#up.gmodlegs3_compat', 'up_gmodlegs3_compat')
	panel:ControlHelp('#up.gmodlegs3_compat.help')

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)
end

hook.Add('PopulateToolMenu', 'upar.menu.clsetting', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.clsetting', 
		'#upgui.menu.clsetting', '', '', 
		CreateMenu
	)
end)