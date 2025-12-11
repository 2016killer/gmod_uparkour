--[[
	作者:白狼
	2025 12 09
--]]

-- ==================== 向量输入框 ===============
local VecEditor = {}
function VecEditor:Init()
	local inputX = vgui.Create('DNumberWang', self)
	local inputY = vgui.Create('DNumberWang', self)
	local inputZ = vgui.Create('DNumberWang', self)

	inputX.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[1] = newVal end
		self:OnChange(self:GetValue())
	end

	inputY.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[2] = newVal end
		self:OnChange(self:GetValue())
	end

	inputZ.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[3] = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputX = inputX
	self.inputY = inputY
	self.inputZ = inputZ

	self:OnSizeChanged(self:GetWide(), self:GetTall())

	self:SetInterval(0.5)
	self:SetDecimals(2)
	self:SetMinMax(-10000, 10000)
end

function VecEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 3

	self.inputX:SetPos(0, 0)
	self.inputY:SetPos(div, 0)
	self.inputZ:SetPos(div * 2, 0)

	self.inputX:SetWidth(div)
	self.inputY:SetWidth(div)
	self.inputZ:SetWidth(div)
end

function VecEditor:SetValue(vec)
	if not isvector(vec) then 
		error(string.format('vec "%s" is not a vector\n', vec))
		return 
	end

	self.inputX:SetValue(vec[1])
	self.inputY:SetValue(vec[2])
	self.inputZ:SetValue(vec[3])
	self.bindVec = vec
end

function VecEditor:GetValue()
	return isvector(self.bindVec) and self.bindVec or Vector(
		self.inputX:GetValue(), 
		self.inputY:GetValue(), 
		self.inputZ:GetValue()
	)
end

function VecEditor:SetMinMax(min, max)
	self.inputX:SetMinMax(min, max)
	self.inputY:SetMinMax(min, max)
	self.inputZ:SetMinMax(min, max)
end

function VecEditor:SetDecimals(decimals)
	self.inputX:SetDecimals(decimals)
	self.inputY:SetDecimals(decimals)
	self.inputZ:SetDecimals(decimals)
end

function VecEditor:SetInterval(interval)
	self.inputX:SetInterval(interval)
	self.inputY:SetInterval(interval)
	self.inputZ:SetInterval(interval)
end

function VecEditor:SetMin(min)
	self.inputX:SetMin(min)
	self.inputY:SetMin(min)
	self.inputZ:SetMin(min)
end

function VecEditor:SetMax(max)
	self.inputX:SetMax(max)
	self.inputY:SetMax(max)
	self.inputZ:SetMax(max)
end

function VecEditor:SetFraction(frac)
	self.inputX:SetFraction(frac)
	self.inputY:SetFraction(frac)
	self.inputZ:SetFraction(frac)
end

VecEditor.OnChange = UPar.emptyfunc

vgui.Register('UParVecEditor', VecEditor, 'DPanel')
VecEditor = nil