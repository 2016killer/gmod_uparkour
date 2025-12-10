--[[
	作者:白狼
	2025 12 10
--]]

local function CreateMenu(panel)

end

hook.Add('PopulateToolMenu', 'upar.menu.keybinder', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.keybinder', 
		'#upgui.menu.keybinder', '', '', 
		CreateMenu
	)
end)
