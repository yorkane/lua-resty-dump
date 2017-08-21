local nmatch = ngx.re.match
local ins = table.insert

---dump
---@param obj table @object to dump
---@param name string
function dump(obj, name)
	name = name or ''
	ngx.print(dump_lua(obj, name))
end

---dump_log dump into the log
---@param obj table
---@param name string
function dump_log(obj, name)
	name = name or ''
	local info = nmatch(debug.traceback('debug', 2), [[traceback:\s+([\s\S]+>)]], 'jo')[1]
	obj = {
		traceback = info,
		[name] = obj
	}
	ngx.log(ngx.NOTICE, dump_lua(obj, ''))
end


---log easy way to log multiple object, string, function
--- default with WARN level
function log(...)
	local arr = { ... }
	local sb = string.buffer()
	local info = '\n' .. nmatch(debug.traceback('debug', 2), [[traceback:\s+([\s\S]+>)]], 'jo')[1]..'\n'
	for i = 1, #arr do
		local val = arr[i]
		local tp = type(val)
		if tp == 'table' then
			sb:add(dump_lua(val, i))
		elseif tp == 'function' then
			local fi = parse_func(val, '', false)
			sb:add('function(' .. fi.param .. [[) end'\t\t-- ]] .. fi.source .. '\n')
		else
			sb:add(val)
		end
	end
	ngx.log(ngx.WARN, info, sb:tos('\n')..'\n')
end


---dump_lua
---@param obj ebitop @object to dump out
---@param name string @name for the description
---@param sb sbuffer @buffer writer
---@param indent_depth number @indention level
---@return string @ dumpped text
function dump_lua(obj, name, sb, indent_depth)
	local is_root, indent = false, ''
	if not sb then
		sb = string.buffer('\n')
		is_root = true
		indent_depth = 0
	end
	name = name or ''
	if indent_depth > 0 then
		indent = string.rep( '\t', indent_depth)
	end
	-- name = name or debug.getinfo(2).namewhat
	if (name ~= '') then
		if type(name) == 'number' then
			--sb:add(indent,'[', name, '] = {\n')
			sb:add(indent, '{\n')
		else
			sb:add(indent, name, ' = {\n')
		end
	else
		sb:add(indent, '{\n')
	end
	if type(obj) ~= 'table' then
		return '\n\t' .. name .. ' = ' .. tostring(obj) .. '\n'
	end
	for key, var in pairs(obj) do
		if key then
			local tps = type(var)
			if tps == 'function' then
				local fi = parse_func(var, key)
				sb:add('\t', indent, key, ' = function(', fi.param, ') end,', indent, '\t\t\t-- ', fi.source, '\n')
			elseif tps == 'table' then
				if #var ~= 0 then
					if type(var[1]) == 'string' then
						sb:add('\t', indent, key, ' = {"', table.concat(var, '", "'), '"')
						sb:add('},\n')
					elseif type(var[1]) == 'number' then
						sb:add('\t', indent, key, ' = {', table.concat(var, ', '), '},\n')
					else
						sb:add('\t', indent, key, ' = {\n')
						for i = 1, #var do
							sb:add('', dump_lua(var[i], '', sb, indent_depth + 1))
							sb:add(',\n')
						end
						sb:add('\t', indent, '},\n')
					end
				else
					dump_lua(var, key, sb, indent_depth + 1)
					sb:add(',\n')
				end
			elseif tps == 'string' then
				sb:add('\t', indent, key, ' = "', var, '",\n')
			elseif tps == 'userdata' then
				sb:add('\t', indent, key, ' = "', var, '",\n')
			else
				sb:add('\t', indent, key, ' = ', tostring(var), ',\n')
			end
		end
	end
	sb:add(indent, '}')
	if is_root then
		local str = sb:tos();
		str = ngx.re.gsub(str, [[\},(\s+\},)]], '}$1') --remove it code still work
		str = ngx.re.gsub(str, [[,(\s+})]], '$1') --remove it code still work
		return str
	end
end

---dump_class dump LUA class with more readable way,and suits for IDE code intellisense
---@param obj ebitop @object to dump out
---@param name string @name for the description
---@param sb sbuffer @buffer writer
---@param indent_depth number @indention level
---@return string @ dumpped text
function dump_class(obj, name, sb, indent_depth)
	local is_root, indent = false, ''
	if not sb then
		sb = string.buffer('\n')
		is_root = true
		indent_depth = 0
	end
	name = name or 'LUAOBJ'
	if indent_depth > 0 then
		indent = string.rep( '\t', indent_depth)
	end
	if (name ~= '') then
		sb:add('\n---@class ', name, '\n', name, ' = {}\n')
	else
		--sb:add(indent, '{\n')
	end
	for key, var in pairs(obj) do
		if key then
			local tps = type(var)
			if tps == 'function' then
				local fi = parse_func(var, key)
				sb:add('\n---@param arg string\n---@return string @type\n')
				sb:add('function ', name, ':', key, '(', fi.param, ') end', '\t\t\t-- ', fi.source, '\n')
			elseif tps == 'table' then
				if #var ~= 0 then
					if type(var[1]) == 'string' then
						sb:add(name, '.', key, ' = {"', table.concat(var, '", "'), '"', '}\n')
					elseif type(var[1]) == 'number' then
						sb:add(name, '.', key, ' = {', table.concat(var, ', '), '},\n')
					else
						sb:add(name, '.', key, ' = {\n')
						for i = 1, #var do
							sb:add('', dump_lua(var[i], '', sb, indent_depth))
							sb:add(',\n')
						end
						sb:add('\t', indent, '}\n')
					end
				else
					sb:add(name, '.')
					dump_lua(var, key, sb, indent_depth)
					sb:add('\n')
				end
			elseif tps == 'number' then
				sb:add(name, '.', key, ' = ', tostring(var), '\n')
			else
				sb:add(name, '.', key, ' = "', tostring(var), '"\n')
			end
		end
	end
	sb:add('\n')
	if is_root then
		local str = sb:tos();
		str = ngx.re.gsub(str, [[\},(\s+\},)]], '}$1') --remove it code still work
		str = ngx.re.gsub(str, [[,(\s+})]], '$1') --remove it code still work
		return str
	end
end

--[[
local sb = string.buffer('fds','1',232,4343)
sb:add('11', 'ss', 123,4343, 4343):add('324324'):add('2',4356,6565,1111):add():add(nil):add(2223232):add(false):pop(1)
print(sb:tos(','))
]]

---@class sbuffer
local sbuffer = {}
---new @create new stringbuffer
---@return sbuffer
function sbuffer:new(...)
	local sbs = {
		buffer = { ... }
	}
	setmetatable(sbs, { __index = self })
	return sbs
end

---add @add multiple string args. :add(1,2,nil,'4',5) =1,2
---@return sbuffer
function sbuffer:add(...)
	local args = { ... }
	for i = 1, #args do
		local arg = args[i]
		ins(self.buffer, tostring(arg))
	end
	return self
end

---pop @remove buffer elements at tail poistion
---@param count number @element count to remove at tail position
---@return sbuffer
function sbuffer:pop(count)
	count = count or 2
	local len = #self.buffer
	for i = 1, count do
		table.remove(self.buffer, len)
		len = len - 1
	end
	return self
end

---tos  @convert stringbuffer to string
---@param splitor string @ string to join buffer together
---@return string
function sbuffer:tos(splitor)
	return table.concat(self.buffer, splitor)
end

---buffer attach to string class
function string.buffer(...)
	return sbuffer:new(...)
end

utils = {}


-- fi info as below:
---@class debug.function_info
local fi = {
	linedefined = 1,
	currentline = -1,
	func = 'function: 0x4086f228',
	isvararg = false,
	namewhat = 'func_name',
	lastlinedefined = 3,
	source = '@/root/lua/info.lua',
	nups = 0,
	what = 'Lua',
	nparams = 2,
	short_src = '/root/lua/info.lua',
	is_lua = true,
	name = 'name'
}
---parse_func parse function and return function details
---@param func function @func to parse
---@param fname string @function name
---@param with_self boolean @ default :(arg1, arg2), with_self .(self, arg1, arg2)
---@return table
function parse_func(func, fname, with_self)
	---@type debug.function_info
	local fi = debug.getinfo(func)
	fi.name = fname
	local sb = string.buffer()
	if fi.nparams > 1 then
		fi.nparams = with_self and fi.nparams or fi.nparams - 1
		for i = 1, fi.nparams do
			sb:add('arg', i, ', ')
		end
	else
		sb:add('arg', '')
	end
	fi.param = sb:pop(1):tos()
	fi.source = string.gsub(fi.source .. ' @line: ' .. fi.linedefined, [[%\]], '/')
	fi.is_lua = (fi.what ~= 'C')
	return fi
end

---parse_code
---usage:
--- call this function in any code. It will search for local object within current lua file context from to to bottom
--- When encounter the 'local end_list' variable, the parse process will stop.
--- it will return well formatted function stub with parameters arrays( the param name will be lost due to the lua vm)
--- ALSO THE CODE SOURCE FILE AND LINE NUMBER, IT'S VERY USEFUL TO DETECT THE CLASS INHERTS RELATIONS.
function parse_code()
	local a = 1
	local sb = string.buffer()
	while true
	do
		local name, value = debug.getlocal(2, a)
		if not name then
			break
		end
		if name == 'end_list' then
			break
		end
		-- var_tb[name]= value
		if type(value) == 'table' then
			sb:add(dump_class(value, name))
		end
	end
	return sb:tos()
end