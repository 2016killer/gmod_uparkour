--[[
	作者:白狼
	2025 11 1
]]--

-- ==================== 翻越 ===============
local UPar = UPar
---------------------- 菜单 ----------------------
local convars = {
	{
		name = 'dp_vault_hlen',
		default = '2',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'dp_vault_vlen',
		default = '0.5',
		widget = 'NumSlider',
		min = 0.25,
		max = 0.6,
		decimals = 2,
		help = true,
	}
}

UPar.CreateConVars(convars)
local dp_vault_hlen = GetConVar('dp_vault_hlen')
local dp_vault_vlen = GetConVar('dp_vault_vlen')

local actionName = 'DParkour-Vault'
local action, _ = UPar.Register(actionName)
if CLIENT then
	action.icon = 'dparkour/icon.jpg'
	action.label = '#dp.menu.vault'
	action.CreateOptionMenu = function(panel)
		UPar.CreateConVarMenu(panel, convars)
	end
else
	convars = nil
end
---------------------- 动作逻辑 ----------------------
function action:GetSpeed(ply, ref)
    local startspeed = UPar.XYNormal(ply:EyeAngles():Forward()):Dot(ref)
    return startspeed,
        math.max(
            ply:GetJumpPower() + (ply:KeyDown(IN_SPEED) and ply:GetRunSpeed() or ply:GetWalkSpeed()),
            startspeed
        )
end

function action:Check(ply, startpos, landpos, blockheight, plyvel, startspeed)
	if ply:KeyDown(IN_BACK) or not ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_DUCK) then 
		return
	end
  
	local bmins, bmaxs = ply:GetHull()
	local plyWidth = math.max(bmaxs[1] - bmins[1], bmaxs[2] - bmins[2])
	local plyHeight = bmaxs[3] - bmins[3]

    local hlen = dp_vault_hlen:GetFloat() * plyWidth
    local vlen = dp_vault_vlen:GetFloat() * plyHeight
	local vaultpos, vaultheight = UPar.GeneralVaultCheck(ply, startpos, landpos, hlen, vlen)

	if not vaultpos then
		return 
	end

	local startspeed, endspeed = self:GetSpeed(ply, plyvel)
	local dis = (vaultpos - startpos):Length()
	local dir = (vaultpos - startpos):GetNormal()
	local duration = dis * 2 / (startspeed + endspeed)

	return ply:GetPos(), 
		vaultpos, 
		startspeed, 
		endspeed, 
		duration, 
		dir,
		CurTime()
end

function action:Start(ply, ...)
	if CLIENT then return end
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
	UPar.WriteMoveControl(ply, true, true, bit.bor(IN_JUMP, IN_DUCK), 0)
end

function action:Play(ply, mv, cmd,
        startpos, 
        vaultpos, 
        startspeed, 
        endspeed, 
        duration, 
        dir,  
        starttime
    )

    -- what fuck?
	local dt = CurTime() - starttime
	local acc = (endspeed - startspeed) / duration
	local endflag = dt > duration

	mv:SetOrigin(startpos + (0.5 * acc * dt * dt + startspeed * dt) * dir +
		(-100 / duration * dt * dt + 100 * dt) * UPar.unitzvec
	)

	if endflag then 
		return vaultpos, endspeed * dir
	else
		return nil
	end
end

function action:Clear(ply, mv, cmd, vaultpos, endvel)
    ply:SetMoveType(MOVETYPE_WALK)
    if SERVER and mv then
        -- 开环控制必须加这个
        if UPar.GeneralLandSpaceCheck(ply, ply:GetPos()) then
            mv:SetOrigin(vaultpos)
        end
        mv:SetVelocity(endvel)
    end
end