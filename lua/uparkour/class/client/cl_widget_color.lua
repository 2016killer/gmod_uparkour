--[[
	作者:白狼
	2025 12 09
--]]

-- ==================== 向量输入框 ===============
local ColorEditor = {}
function ColorEditor:Init()
	local inputR = vgui.Create('DNumberWang', self)
	local inputG = vgui.Create('DNumberWang', self)
	local inputB = vgui.Create('DNumberWang', self)

	inputR.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[1] = newVal end
		self:OnChange(self:GetValue())
	end

	inputG.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[2] = newVal end
		self:OnChange(self:GetValue())
	end

	inputB.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[3] = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputR = inputR
	self.inputG = inputG
	self.inputB = inputB

	self:OnSizeChanged(self:GetWide(), self:GetTall())

	self:SetInterval(0.5)
	self:SetDecimals(2)
	self:SetMinMax(-10000, 10000)
end

function ColorEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 3

	self.inputR:SetPos(0, 0)
	self.inputG:SetPos(div, 0)
	self.inputB:SetPos(div * 2, 0)

	self.inputR:SetWidth(div)
	self.inputG:SetWidth(div)
	self.inputB:SetWidth(div)
end

function ColorEditor:SetValue(vec)
	if not isvector(vec) then 
		error(string.format('vec "%s" is not a vector\n', vec))
		return 
	end

	self.inputR:SetValue(vec[1])
	self.inputG:SetValue(vec[2])
	self.inputB:SetValue(vec[3])
	self.bindVec = vec
end

function ColorEditor:GetValue()
	return isvector(self.bindVec) and self.bindVec or Vector(
		self.inputR:GetValue(), 
		self.inputG:GetValue(), 
		self.inputB:GetValue()
	)
end

function ColorEditor:SetMinMax(min, max)
	self.inputR:SetMinMax(min, max)
	self.inputG:SetMinMax(min, max)
	self.inputB:SetMinMax(min, max)
end

function ColorEditor:SetDecimals(decimals)
	self.inputR:SetDecimals(decimals)
	self.inputG:SetDecimals(decimals)
	self.inputB:SetDecimals(decimals)
end

function ColorEditor:SetInterval(interval)
	self.inputR:SetInterval(interval)
	self.inputG:SetInterval(interval)
	self.inputB:SetInterval(interval)
end

function ColorEditor:SetMin(min)
	self.inputR:SetMin(min)
	self.inputG:SetMin(min)
	self.inputB:SetMin(min)
end

function ColorEditor:SetMax(max)
	self.inputR:SetMax(max)
	self.inputG:SetMax(max)
	self.inputB:SetMax(max)
end

function ColorEditor:SetFraction(frac)
	self.inputR:SetFraction(frac)
	self.inputG:SetFraction(frac)
	self.inputB:SetFraction(frac)
end

ColorEditor.OnChange = UPar.emptyfunc

vgui.Register('UParColorEditor', ColorEditor, 'DPanel')
ColorEditor = nil