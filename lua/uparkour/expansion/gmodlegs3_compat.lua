--[[
	作者:白狼
	2025 11 5
--]]

local up_gmodlegs3_compat = CreateClientConVar('up_gmodlegs3_compat', '1', true, false, '')
hook.Add('ShouldDisableLegs', 'upar.gmodlegs3', function()
	if not up_gmodlegs3_compat:GetBool() then 
		return nil 
	end
	
	return VMLegs and VMLegs:IsActive()
end)