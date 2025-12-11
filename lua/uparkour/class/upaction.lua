--[[
	作者:白狼
	2025 12 10
--]]

UPAction = {}
UPAction.__index = UPAction

local Instances = {}

local function sanitizeConVarName(name)
    return 'upact_' .. string.gsub(name, '[\\/:*?\"<>|]', '_')
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

local function CheckDefault(self, ply, ...)
    UPar.printdata(string.format('Check Action "%s" %s', self.Name, ply), ...)
    return false
end

local function StartDefault(self, ply, ...)
    UPar.printdata(string.format('Start Action "%s" %s', self.Name, ply), ...)
end

local function PlayDefault(self, ply, mv, cmd, ...)
    UPar.printdata(string.format('Play Action "%s" %s %s %s', self.Name, ply, mv, cmd), ...)
    return true
end

local function ClearDefault(self, ply, ...)
    UPar.printdata(string.format('Clear Action "%s" %s', self.Name, ply), ...)
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

    self:InitCVarDisabled(initData.disabled)

    self.Check = initData.Check or CheckDefault
    self.Start = initData.Start or StartDefault
    self.Play = initData.Play or PlayDefault
    self.Clear = initData.Clear or ClearDefault

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

function UPAction:GetEffect(effectName)
    return self.Effects[effectName]
end

function UPAction:GetPlayerEffect(ply, effectName)
    if effectName == 'CUSTOM' then
        return ply.upeffect_custom_cache[self.Name] or self.Effects.default
    else
        return self.Effects[effectName] or self.Effects.default
    end
end

function UPAction:GetPlayerUsingEffect(ply)
    local effectName = ply.upeffect_config[self.Name] or 'default'
    if effectName == 'CUSTOM' then
        return ply.upeffect_custom_cache[self.Name] or self.Effects.default
    else
        return self.Effects[effectName] or self.Effects.default
    end
end

function UPAction:InitCVarDisabled(default)
    local cvName = sanitizeConVarName(self.Name) .. '_disabled'
    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}

    local cvar = GetConVar(cvName)
    if not cvar then
        cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    end
    self.CV_Disabled = cvar
end

function UPAction:GetDisabled()
    return self.CV_Disabled:GetBool()
end

function UPAction:SetDisabled(disabled)
    self.CV_Disabled:SetBool(!!disabled)
end

function UPAction:InitCVarPredictionMode(default)
    local cvName = sanitizeConVarName(self.Name) .. '_pred_mode'
    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}

    local cvar = GetConVar(cvName)
    if not cvar then
        cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    end
    self.CV_PredictionMode = cvar
end

function UPAction:GetPredictionMode()
    return self.CV_PredictionMode:GetBool()
end

function UPAction:SetPredictionMode(predictionMode)
    self.CV_PredictionMode:SetBool(!!predictionMode)
end

function UPAction:InitCVarKeybind(default)
    if SERVER then return end

    local cvName = sanitizeConVarName(self.Name) .. '_keybind'
    local cvar = GetConVar(cvName)

    if not cvar then
        cvar = CreateClientConVar(cvName, tostring(default), true, false, '')
    end

    self.CV_Keybind = cvar
end

function UPAction:GetKeybind()
    if SERVER then return end

    local keys = string.Split(self.CV_Keybind:GetString(), ' ') 
    local result = {}
    for i, k in ipairs(keys) do
        if string.Trim(k) == '' then
            continue
        else
            result[i] = tonumber(k) or 0
        end
    end

    return result
end

function UPAction:SetKeybind(keynums) 
    if SERVER then return end

    -- Example: {0, 0, 0}
    if not istable(keynums) then
        error(string.format('Invalid keynums "%s" (not a table)', keynums))
    end

    local keys = {}
    for i, kn in ipairs(keynums) do
        if not isnumber(kn) then
            table.insert(keys, 0)
        else
            table.insert(keys, kn)
        end
    end

    self.CV_Keybind:SetString(table.concat(keys, ' '))
end

UPar.GetAllActions = function() return Instances end
UPar.GetAction = function(name) return Instances[name] end
UPar.isupaction = isupaction


-- ===================== 测试 ===================== 
local action = UPAction:new('testt', {
    Effects = {
        default = 'SP-VManip-白狼',
    },
})


action:SetIcon('icon16/star.png')
action:SetLabel('测试动作')

action:InitCVarPredictionMode(true)
print(action:GetPredictionMode())
if SERVER then
    print(action:GetDisabled())
    action:SetDisabled(false)
elseif CLIENT then
    action:InitCVarKeybind('0 0 0')
    action:SetKeybind({50, 0111, 20})

    print(action:GetKeybind())
    PrintTable(action:GetKeybind())

    print(action:GetPlayerEffect(LocalPlayer(), 'default'))
    action:Play(LocalPlayer(), nil, nil, 1, 2, 3, 4)
    action:Clear(LocalPlayer())
    action:Check(LocalPlayer())

    print(action:GetPredictionMode())
end



// PrintTable(action)

