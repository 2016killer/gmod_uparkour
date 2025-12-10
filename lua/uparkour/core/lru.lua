--[[
	作者:豆包女士
	2025 12 09
    常用函数:
    - LRUInit(capacity): 初始化LRU缓存，重置数据并设置初始容量
    - LRUSetCapacity(capacity): 设置缓存容量，容量缩小自动淘汰最久未用key
    - LRUSet(key, value): 添加/更新缓存值
    - LRUGet(key): 获取缓存值（不存在返回nil），访问后标记为最近使用
    - LRUGetOrSet(key, default): 连拿带放，不存在则设默认值并返回
    - LRUDelete(key): 删除指定key的缓存，返回是否删除成功
    - LRUClear(): 清空所有缓存
    - LRUGetSize(): 获取当前缓存条目数
    - LRUGetCapacity(): 获取当前缓存最大容量
]]--
--[[
	Author: Ms. DouBao
	2025 12 09
    Common Functions:
    - LRUInit(capacity): Initialize LRU cache, reset data and set initial capacity
    - LRUSetCapacity(capacity): Set cache capacity, automatically evict least recently used keys when capacity is reduced
    - LRUSet(key, value): Add or update cache value
    - LRUGet(key): Get cache value (return nil if not exists), mark as recently used after access
    - LRUGetOrSet(key, default): Get value, set default value and return if key not exists
    - LRUDelete(key): Delete cache of specified key, return whether deletion is successful
    - LRUClear(): Clear all cache
    - LRUGetSize(): Get current number of cache entries
    - LRUGetCapacity(): Get maximum cache capacity
]]--

local LRUCache = {}
local LRUOrder = {}
local LRUCapacity = 30

local function _lruTouch(key)
    for i = #LRUOrder, 1, -1 do
        if LRUOrder[i] == key then
            table.remove(LRUOrder, i)
            break
        end
    end
    table.insert(LRUOrder, 1, key)
end

function UPar.LRUInit(capacity)
    LRUCache = {}
    LRUOrder = {}
    if capacity then
        LRUCapacity = math.max(tonumber(capacity) or 30, 1)
    end
end

function UPar.LRUSetCapacity(capacity)
    LRUCapacity = math.max(tonumber(capacity) or LRUCapacity, 1)
    local excess = #LRUOrder - LRUCapacity
    if excess > 0 then
        for i = 1, excess do
            LRUCache[table.remove(LRUOrder)] = nil
        end
    end
end

local function LRUSet(key, value)
    if not key then error("LRUSet: key cannot be nil") end
    if LRUCache[key] then
        LRUCache[key] = value
        _lruTouch(key)
        return
    end
    if #LRUOrder >= LRUCapacity then
        LRUCache[table.remove(LRUOrder)] = nil
    end
    LRUCache[key] = value
    table.insert(LRUOrder, 1, key)
end

local function LRUGet(key)
    local val = LRUCache[key]
    if val then _lruTouch(key) end
    return val
end

UPar.LRUSet = LRUSet
UPar.LRUGet = LRUGet

function UPar.LRUGetOrSet(key, default)
    if not key then error("LRUGetOrSet: key cannot be nil") end

    local val = LRUGet(key)
    if val ~= nil then
        return val
    end

    LRUSet(key, default)
    return default
end

function UPar.LRUDelete(key)
    if not LRUCache[key] then return false end
    LRUCache[key] = nil
    for i = #LRUOrder, 1, -1 do
        if LRUOrder[i] == key then
            table.remove(LRUOrder, i)
            break
        end
    end
    return true
end

function UPar.LRUClear()
    LRUCache = {}
    LRUOrder = {}
end

function UPar.LRUGetSize()
    return #LRUOrder
end

function UPar.LRUGetCapacity()
    return LRUCapacity
end