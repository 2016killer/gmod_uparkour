--[[
	作者:白狼
	2025 12 11
--]]


UPEffect = {}
UPEffect.__index = UPEffect

local function isupeffect(obj)
    if not istable(obj) then 
        return false 
    end
    local mt = getmetatable(obj)
    while mt do
        if mt == UPEffect then return true end
        local nextMt = getmetatable(mt)
        if nextMt and nextMt.__index then
            mt = nextMt.__index
        else
            break
        end
    end
    return false
end

function UPEffect:new(name, initData)
    if string.find(name, '[\\/:*?\"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local self = setmetatable({}, UPEffect)

	self.Name = name
	self.Start = self.Start or function(self, ply, ...)
		UPar.printdata(string.format('Effect "%s" Start', effectName), ply, ...)
	end

	self.Clear = self.Clear or function(self, ply, ...)
		UPar.printdata(string.format('Effect "%s" Clear', effectName), ply, ...)
	end

	self.OnRhythmChange = self.OnRhythmChange or UPar.emptyfunc

    self:SetIcon(initData.icon)
    self:SetLabel(initData.label)

    return self
end

function UPEffect:SetIcon(icon)
    if SERVER or icon == nil then return end
    if not isstring(icon) then
        error(string.format('Invalid icon "%s" (not a string)', icon))
    end
    self.icon = icon
end

function UPEffect:SetLabel(label)
    if SERVER or label == nil then return end
    if not isstring(label) then
        error(string.format('Invalid label "%s" (not a string)', label))
    end
    self.label = label
end

function UPEffect:Register(actionName)
	local action = UPar.GetAction(actionName)
    if not action then
        error(string.format('Invalid action "%s"', actionName))
    end
	action.Effects[name] = self
    hook.Run('UParRegisterEffect', actionName, name, self)
end

function UPEffect:IsCustom()
	return !!self.linkName
end

function UPEffect:CreateCustom(name)
	return {
		Name = name,
		linkName = self.Name,
		icon = 'icon64/tool.png'
	}
end

function UPEffect:InitCustom(actionName, name)
	if not self.linkName then 
		return true
	end

	local action = UPar.GetAction(actionName)
	if not action then
		print(string.format('[UPar]: init custom effect failed, action "%s" not found', actionName))
		return false
	end

	local target = action:GetEffect(self.linkName)
	if not target then
		print(string.format('[UPar]: init custom effect failed, action "%s" effect "%s" not found', actionName, linkName))
		return false
	end

	for k, v in pairs(target) do
		if custom[k] == nil then custom[k] = v end
	end

	return true
end

UPar.isupeffect = isupeffect


