--[[
	作者:白狼
	2025 11 1
]]--

-- ==================== 低爬 ===============
local UPar = UPar
---------------------- 菜单 ----------------------
local convars = {
	{
		name = 'dp_los_cos',
		default = '0.64',
		widget = 'NumSlider',
		min = 0,
		max = 1,
		decimals = 2,
		help = true,
	},

	{
		name = 'dp_falldamage',
		default = '1',
		widget = 'CheckBox'
	},

	{
		name = 'dp_lc_blen',
		default = '1.5',
		widget = 'NumSlider',
		min = 0,
		max = 2,
		decimals = 2,
		help = true,
	},

	{
		name = 'dp_lc_max',
		default = '0.85',
		widget = 'NumSlider',
		min = 0,
		max = 0.85,
		decimals = 2,
		help = true,
	},

	{
		name = 'dp_lc_min',
		default = '0.5',
		widget = 'NumSlider',
		min = 0,
		max = 0.85,
		decimals = 2,
	}
}

UPar.CreateConVars(convars)
local dp_los_cos = GetConVar('dp_los_cos')
local dp_falldamage = GetConVar('dp_falldamage')
local dp_lc_blen = GetConVar('dp_lc_blen')
local dp_lc_min = GetConVar('dp_lc_min')
local dp_lc_max = GetConVar('dp_lc_max')

local actionName = 'DParkour-LowClimb'
local action, _ = UPar.Register(actionName)
if CLIENT then
	action.icon = 'dparkour/icon.jpg'
	action.label = '#dp.menu.lowclimb'
	action.CreateOptionMenu = function(panel)
		UPar.CreateConVarMenu(panel, convars)
	end
else
	convars = nil
end


---------------------- 动作逻辑 ----------------------
function action:GetSpeed(ply, ref)
	-- 返回爬楼初始速度、结束速度
	return math.max(
			ply:GetJumpPower() + 0.25 * (ply:KeyDown(IN_SPEED) and ply:GetRunSpeed() or ply:GetWalkSpeed()), 
			(UPar.XYNormal(ply:EyeAngles():Forward()) + UPar.unitzvec):Dot(ref) * 0.707
        ),
        0
end

function action:Check(ply, posoverride)
	if ply:KeyDown(IN_BACK) or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:InVehicle() or !ply:Alive() then 
		return
	end

	local bmins, bmaxs = ply:GetCollisionBounds()
	local plyWidth = math.max(bmaxs[1] - bmins[1], bmaxs[2] - bmins[2])
	local plyHeight = bmaxs[3] - bmins[3]
	
	local blockHeightMax = dp_lc_max:GetFloat() * plyHeight
	local blockHeightMin = dp_lc_min:GetFloat() * plyHeight
    local blen = dp_lc_blen:GetFloat() * plyWidth

	bmaxs[3] = blockHeightMax
	bmins[3] = blockHeightMin

	local startpos, landpos, blockheight = UPar.GeneralClimbCheck(ply, 
		blen,
        bmins,
		bmaxs,
		0.5 * plyWidth,
		blockHeightMax - blockHeightMin,
		dp_los_cos:GetFloat(),
		posoverride
	)

    if not startpos then 
        return 
    end

    local plyvel = ply:GetVelocity()
	-- 检测摔落伤害
	if dp_falldamage:GetBool() then
        local damageinfo = UPar.GetFallDamageInfo(ply, plyvel[3], -600)
        if damageinfo then 
            ply:TakeDamageInfo(damageinfo)
            ply:EmitSound('Player.FallDamage', 100, 100)
        end
	end

	local dis = (landpos - startpos):Length()
	local dir = (landpos - startpos):GetNormal()
    local startspeed, endspeed = self:GetSpeed(ply, plyvel)
	local duration = dis * 2 / (startspeed + endspeed)

    return startpos,
        landpos,
        blockheight,
		plyvel,
        startspeed,
        endspeed, 
        duration,
        CurTime(),
		dir
end

function action:Start(ply, startpos, landpos, ...)
    if CLIENT then return end
    local needduck = UPar.GeneralLandSpaceCheck(ply, landpos)
    UPar.WriteMoveControl(ply, true, true, 
		needduck and IN_JUMP or bit.bor(IN_DUCK, IN_JUMP),
		needduck and IN_DUCK or 0)
	ply:SetMoveType(MOVETYPE_NOCLIP)
end

function action:Play(ply, mv, cmd, startpos, landpos, blockheight, plyvel, startspeed, endspeed, duration, starttime, dir)
	-- 保险一点
	local dt = CurTime() - starttime

    local acc = (endspeed - startspeed) / duration
	local endflag = dt > duration

	mv:SetOrigin(startpos + (0.5 * acc * dt * dt + startspeed * dt) * dir)

	if endflag then 
		return landpos
	else
		return nil
	end
end

function action:Clear(ply, mv, cmd, landpos)
    ply:SetMoveType(MOVETYPE_WALK)
	if SERVER then
		-- 开环控制必须加这个
	    if mv and UPar.GeneralLandSpaceCheck(ply, ply:GetPos()) then
			mv:SetOrigin(landpos)
		end
    end
end
