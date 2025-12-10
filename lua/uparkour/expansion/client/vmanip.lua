--[[
	作者:白狼
	2025 11 5
--]]

VMLegs.RegisterAnimCollection = function(self, collectionName, anim)
    if not isstring(anim) then
        print(string.format('RegisterAnimCollection: anim "%s" is not a string', anim))
        return
    end
    self.AnimCollection = self.AnimCollection or {}
    self.AnimCollection[collectionName] = self.AnimCollection[collectionName] or {}
    table.insert(self.AnimCollection[collectionName], anim)
end


VManip.RegisterAnimCollection = VMLegs.RegisterAnimCollection


VMLegs.PlayAnimFromCollection = function(self, collectionName)
    local collection = self.AnimCollection[collectionName]
    if not collection then
        print(string.format('PlayAnimFromCollection: collection "%s" not found', collectionName))
        return
    end
    
    self:PlayAnim(collection[math.random(#collection)])
end

VManip.PlayAnimFromCollection = VMLegs.PlayAnimFromCollection