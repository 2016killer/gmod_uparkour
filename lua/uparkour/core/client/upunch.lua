--[[
	作者:白狼
	2025 11 1

--]]

local vecpunch_vel = Vector()
local vecpunch_offset = Vector()

local angpunch_vel = Vector()
local angpunch_offset = Vector()

local punch = false

hook.Add('CalcView', 'upar.punch', function(ply, pos, angles, fov)
	if not punch then return end

	local dt = FrameTime()
	local vecacc = -(vecpunch_offset * 50 + 10 * vecpunch_vel)
	vecpunch_offset = vecpunch_offset + vecpunch_vel * dt 
	vecpunch_vel = vecpunch_vel + vecacc * dt	

	local angacc = -(angpunch_offset * 50 + 10 * angpunch_vel)
	angpunch_offset = angpunch_offset + angpunch_vel * dt 
	angpunch_vel = angpunch_vel + angacc * dt	

	local view = GAMEMODE:CalcView(ply, pos, angles, fov) 
	local eyeAngles = view.angles - ply:GetViewPunchAngles()

	view.origin = view.origin + eyeAngles:Forward() * vecpunch_offset.x +
		eyeAngles:Right() * vecpunch_offset.y +
		eyeAngles:Up() * vecpunch_offset.z

	view.angles = view.angles + Angle(angpunch_offset.x, angpunch_offset.y, angpunch_offset.z)

	local vecoffsetLen = vecpunch_offset:LengthSqr()
	local angoffsetLen = angpunch_offset:LengthSqr()
	local vecvelLen = vecpunch_vel:LengthSqr()
	local angvelLen = angpunch_vel:LengthSqr()

	if vecoffsetLen < 0.1 and vecvelLen < 0.1 and angoffsetLen < 0.1 and angvelLen < 0.1 then
		vecpunch_offset = Vector()
		vecpunch_vel = Vector()

		angpunch_offset = Vector()
		angpunch_vel = Vector()

		punch = false
	end

	return view
end)

UPar.SetVecPunchOffset = function(vec)
	punch = true
	vecpunch_offset = vec
end

UPar.SetAngPunchOffset = function(vec)
	punch = true
	angpunch_offset = ang
end

UPar.SetVecPunchVel = function(vec)
	punch = true
	vecpunch_vel = vec
end

UPar.SetAngPunchVel = function(vec)
	punch = true
	angpunch_vel = vec
end

UPar.GetVecPunchOffset = function() return vecpunch_offset end
UPar.GetAngPunchOffset = function() return angpunch_offset end
UPar.GetVecPunchVel = function() return vecpunch_vel end
UPar.GetAngPunchVel = function() return angpunch_vel end