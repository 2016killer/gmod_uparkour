--[[
	作者:白狼
	2025 12 10
--]]

UPAction = {}
UPAction.__index = UPAction

local Instances = {}

local function sanitizeConVarName(name)
    return 'upaction_' .. string.gsub(name, '[\\/:*?\"<>|]', '_')
end

local function isupaction(obj)
    if not istable(obj) then 
        return false 
    end
    local mt = getmetatable(obj)
    while mt do
        if mt == UPAction then return true end
        local nextMt = getmetatable(mt)
        if nextMt and nextMt.__index then
            mt = nextMt.__index
        else
            break
        end
    end
    return false
end

function UPAction:new(name, initData)
    if string.find(name, '[\\/:*?\"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local self = setmetatable({}, UPAction)

    self.Name = name
    self.Effects = initData.Effects or {}


    local cvName = sanitizeConVarName(name)
    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}
    self.CV_Disabled = CreateConVar(cvName .. '_disabled', '0', cvFlags, 'Disable ' .. name .. ' action')
    self.CV_PredictionMode = CreateConVar(cvName .. '_pred_mode', '0', cvFlags, 'Prediction mode for ' .. name .. ' (server/client)')
    self.CV_Keybind = CreateConVar(cvName .. '_keybind', '0', cvFlags, 'Keybind vector for ' .. name .. ' (key1 key2 ...)')

    self.Check = initData.Check or function(self, ply, ...)
        UPar.printdata(string.format('Check Action "%s"', self.Name), ply, ...)
        return false
    end

    self.Start = initData.Start or function(self, ply, ...)
        UPar.printdata(string.format('Start Action "%s"', self.Name), ply, ...)
    end

    self.Play = initData.Play or function(self, ply, mv, cmd, ...)
        if CurTime() - (starttime or 0) > 2 then
            UPar.printdata(string.format('Play Action "%s"', self.Name), ply, mv, cmd, ...)
            return true
        end
    end

    self.Clear = initData.Clear or function(self, ply, ...)
        UPar.printdata(string.format('Clear Action "%s"', self.Name), ply, ...)
    end

    self:SetIcon(initData.icon)
    self:SetLabel(initData.label)

    return self
end

function UPAction:SetIcon(icon)
    if SERVER or icon == nil then return end
    if not isstring(icon) then
        error(string.format('Invalid icon "%s" (not a string)', icon))
    end
    self.icon = icon
end

function UPAction:SetLabel(label)
    if SERVER or label == nil then return end
    if not isstring(label) then
        error(string.format('Invalid label "%s" (not a string)', label))
    end
    self.label = label
end

function UPAction:Register()
    Instances[name] = self
    hook.Run('UParRegisterAction', name, self)
end


UPar.GetAllActions = function() return Instances end
UPar.isupaction = isupaction