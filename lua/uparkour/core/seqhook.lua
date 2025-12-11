--[[
	作者:豆包女士
	2025 12 10
    常用函数:
    - SeqHookAdd: 注册带优先级的自定义事件回调（重复标识符自动覆盖，优先级智能默认）
    - SeqHookRun: 触发指定自定义事件（高频触发优化，无冗余判断）
    - SeqHookRemove: 注销指定标识符的事件回调（自动清理空事件表）
    - SeqHookGetTable: 获取执行表（事件名→优先级排序的函数数组）
    - SeqHookGetMeta: 获取元信息表（事件名→标识符→{func, prio}）
]]--

local SeqHookMeta = {}
local SeqHookTable = {}

-- 私有函数：获取指定事件下的最高优先级数值（最大数值=最低优先级）
local function getMaxPriority(eventName)
    local maxPrio = 0
    if not SeqHookMeta[eventName] then return maxPrio end
    for _, meta in pairs(SeqHookMeta[eventName]) do
        if meta.prio > maxPrio then
            maxPrio = meta.prio
        end
    end
    return maxPrio
end

local function insertSortedFunc(eventFuncList, func, prio)
    local insertPos = #eventFuncList + 1
    for i = #eventFuncList, 1, -1 do
        local curFunc = eventFuncList[i]
        local curPrio
        for _, eventMeta in pairs(SeqHookMeta) do
            for _, meta in pairs(eventMeta) do
                if meta.func == curFunc then
                    curPrio = meta.prio
                    break
                end
            end
            if curPrio then break end
        end
        if curPrio and curPrio <= prio then
            insertPos = i + 1
            break
        end
        insertPos = i
    end
    table.insert(eventFuncList, insertPos, func)
end

UPar.SeqHookAdd = function(eventName, identifier, func, priority)
    if not isstring(eventName) or eventName == "" then
        error("SeqHookAdd: Invalid eventName - must be a non-empty string")
    end
    if identifier == nil then
        error("SeqHookAdd: Invalid identifier - cannot be nil")
    end
    if not isfunction(func) then
        error("SeqHookAdd: Invalid func - must be a function type")
    end

    -- 初始化表
    if not SeqHookMeta[eventName] then
        SeqHookMeta[eventName] = {}
    end
    if not SeqHookTable[eventName] then
        SeqHookTable[eventName] = {}
    end

    -- 优先级智能处理逻辑
    local finalPrio
    if isnumber(priority) then
        -- 传了合法数字优先级，直接使用
        finalPrio = priority
    else
        -- 优先级为空/非数字：分两种情况
        if SeqHookMeta[eventName][identifier] then
            -- 情况1：标识符已注册 → 复用原有优先级
            finalPrio = SeqHookMeta[eventName][identifier].prio
        else
            -- 情况2：新标识符 → 设为当前最高优先级+1（排在最后）
            finalPrio = getMaxPriority(eventName) + 1
        end
    end

    -- 重复注册覆盖旧回调
    if SeqHookMeta[eventName][identifier] then
        local oldFunc = SeqHookMeta[eventName][identifier].func
        for i = #SeqHookTable[eventName], 1, -1 do
            if SeqHookTable[eventName][i] == oldFunc then
                table.remove(SeqHookTable[eventName], i)
                break
            end
        end
    end

    -- 存储元信息+插入执行表
    SeqHookMeta[eventName][identifier] = {func = func, prio = finalPrio}
    insertSortedFunc(SeqHookTable[eventName], func, finalPrio)
end

UPar.SeqHookRunAll = function(eventName, ...)
    local funcList = SeqHookTable[eventName]
    if not funcList then return end
    
    for i = 1, #funcList do
        funcList[i](...)
    end
end

UPar.SeqHookRun = function(eventName, ...)
    local funcList = SeqHookTable[eventName]
    if not funcList then return end
    
    for i = 1, #funcList do
		local result = funcList[i](...)
        if result ~= nil then return result end
    end
end

UPar.SeqHookRemove = function(eventName, identifier)
    if not isstring(eventName) or eventName == "" then
        error("SeqHookRemove: Invalid eventName - must be a non-empty string")
    end
    if identifier == nil then
        error("SeqHookRemove: Invalid identifier - cannot be nil")
    end

    if not SeqHookMeta[eventName] or not SeqHookMeta[eventName][identifier] then
        print(string.format("SeqHookRemove: Warning - Identifier '%s' for event '%s' does not exist, skipping", tostring(identifier), eventName))
        return
    end

    local targetFunc = SeqHookMeta[eventName][identifier].func
    SeqHookMeta[eventName][identifier] = nil
    if next(SeqHookMeta[eventName]) == nil then
        SeqHookMeta[eventName] = nil
    end

    local funcList = SeqHookTable[eventName]
    for i = #funcList, 1, -1 do
        if funcList[i] == targetFunc then
            table.remove(funcList, i)
            break
        end
    end
    if next(SeqHookTable[eventName]) == nil then
        SeqHookTable[eventName] = nil
    end
end

UPar.SeqHookGetTable = function() return SeqHookTable end
UPar.SeqHookGetMeta = function() return SeqHookMeta end
