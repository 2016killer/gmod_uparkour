--[[
	作者:白狼
	2025 12 09

	我们不再使用UltiPar来管理所有的方法, 因为这会导致代码十分混乱、难以维护
    对于Action、 Effect, 我们使用UPAction、UPEffect类而不是直接使用表
	
	UPar表的功能将集中在最基础的一些方法, 例如翻译、打印数据、调试框、通用检测等

	/class/*.lua: 类(包括控件)的定义
	/core/*.lua: UPar核心方法
	/actions/*.lua: UPAction实例
	/effects/*.lua: UPEffect实例
	/effectseasy/*.lua: UPEffect实例的简单拓展
	/gui/*.lua: 控件的实现(q菜单等)
--]]

AddCSLuaFile()
UPar = UPar or {}
UPar.Version = '3 beta'

UPar.emptyfunc = function() end

UPar.SnakeTranslate = function(key, prefix, sep, joint)
	-- 在树编辑器中所有的键名使用此翻译, 分隔符采用 '_'
	-- 'vec_punch' --> '#upgui.vec' + '.' + '#upgui.punch'

	prefix = prefix or 'upgui'
	sep = sep or '_'
	joint = joint or '.'

	local split = string.Split(key, sep)
	
	for i, v in ipairs(split) do
		split[i] = language.GetPhrase(string.format('#%s.%s', prefix, v))
	end

	return table.concat(split, joint, 1, #split)
end

UPar.printdata = function(flag, ...)
    local total = select('#', ...)
	print('[UPar]: ---------------' .. flag .. '---------------')
	print('total:', total)
    for i = 1, total do
        local data = select(i, ...)
        if istable(data) then
			print('arg'..tostring(i)..':', data)
			PrintTable(data)
		else
			print('arg'..tostring(i)..':', data)
		end
    end
	print('\n\n')
end

UPar.debugwireframebox = function(pos, mins, maxs, lifetime, color, ignoreZ)
	lifetime = lifetime or 1
	color = color or Color(255,255,255)
	ignoreZ = ignoreZ or false

	local ref = mins + pos

	local temp = maxs - mins
	local axes = {Vector(0, 0, temp.z), Vector(0, temp.y, 0), Vector(temp.x, 0, 0)}

	for i = 1, 3 do
		for j = 0, 3 do
			local pos1 = ref
			if bit.band(j, 0x01) ~= 0 then pos1 = pos1 + axes[1] end
			if bit.band(j, 0x02) ~= 0 then pos1 = pos1 + axes[2] end

			debugoverlay.Line(pos1, pos1 + axes[3], lifetime, color, ignoreZ)
		end
		axes[i], axes[3] = axes[3], axes[i]
	end
end

UPar.LoadLuaFiles = function(path)
	local sharedDir = string.format('uparkour/%s/', path)
	local sharedFiles = file.Find(sharedDir .. '*.lua', 'LUA')

	for _, filename in pairs(sharedFiles) do
		local path = sharedDir .. filename
		include(path)
		AddCSLuaFile(path)
		print('[UPar]: LoadLua:' .. path)
	end

	if CLIENT then
		local clientDir = string.format('uparkour/%s/client/', path)
		local clientFiles = file.Find(clientDir .. '*.lua', 'LUA')

		for _, filename in pairs(clientFiles) do
			local path = clientDir .. filename
			include(path)
			print('[UPar]: LoadLua:' .. path)
		end
	elseif SERVER then
		local serverDir = string.format('uparkour/%s/server/', path)
		local serverFiles = file.Find(serverDir .. '*.lua', 'LUA')

		for _, filename in pairs(serverFiles) do
			local path = serverDir .. filename
			include(path)
			print('[UPar]: LoadLua:' .. path)
		end
	end
end

if CLIENT then
	UPar.LoadUserDataFromDisk = function(path)
		-- 从磁盘加载用户数据, 返回 表 或 nil
		local content = file.Read(path, 'DATA')
		local data = util.JSONToTable(content or '')
	
		return istable(data) and data or nil
	end


	UPar.SaveUserDataToDisk = function(data, path)
		-- 保存用户数据到磁盘, 返回 是否成功
		-- 此操作会自动添加元数据 AAAMetadata

		if not istable(data) then
			error(string.format('SaveUserDataToDisk: data must be a table, but got %s\n', type(data)))
			return
		end
		
		data.AAAMetadata = {
			version = UPar.Version,
			date = os.date('%Y-%m-%d %H:%M:%S'),
		}

		local content = util.TableToJSON(data, true) or '{}'
		local succ = file.Write(path, content)
		print(string.format('[UPar]: save user data to disk %s, result: %s', path, succ))

		return succ
	end
end

UPar.LoadLuaFiles('class')
UPar.LoadLuaFiles('core')
UPar.LoadLuaFiles('actions')
UPar.LoadLuaFiles('effects')
UPar.LoadLuaFiles('effectseasy')
UPar.LoadLuaFiles('expansion')
UPar.LoadLuaFiles('gui')

concommand.Add('up_debug_' .. (SERVER and 'sv' or 'cl'), function()
	PrintTable(UPar)
	PrintTable(UPAction.Instances)
end)