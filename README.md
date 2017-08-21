# resty.dump
A useful LUA scripts for openresty environment.

---dump
---@param obj table @object to dump
---@param name string
function dump(obj, name)

---dump_log dump into the log
---@param obj table
---@param name string
function dump_log(obj, name)

---log easy way to log multiple object, string, function
--- default with WARN level
function log(...)

---dump_lua
---@param obj ebitop @object to dump out
---@param name string @name for the description
---@param sb sbuffer @buffer writer
---@param indent_depth number @indention level
---@return string @ dumpped text
function dump_lua(obj, name, sb, indent_depth)

---dump_class dump LUA class with more readable way,and suits for IDE code intellisense
---@param obj ebitop @object to dump out
---@param name string @name for the description
---@param sb sbuffer @buffer writer
---@param indent_depth number @indention level
---@return string @ dumpped text
function dump_class(obj, name, sb, indent_depth)

---parse_func parse function and return function details
---@param func function @func to parse
---@param fname string @function name
---@param with_self boolean @ default :(arg1, arg2), with_self .(self, arg1, arg2)
---@return table
function parse_func(func, fname, with_self)

---parse_code
---usage:
--- call this function in any code. It will search for local object within current lua file context from to to bottom
--- When encounter the 'local end_list' variable, the parse process will stop.
--- it will return well formatted function stub with parameters arrays( the param name will be lost due to the lua vm)
--- ALSO THE CODE SOURCE FILE AND LINE NUMBER, IT'S VERY USEFUL TO DETECT THE CLASS INHERTS RELATIONS.
function parse_code()

#usage:
location /test.lua {
  content_by_lua_block {
    local cookie = require("resty.cookie")
    local cache = require('resty.lrucache')

    ----- code list end here
    local end_list
    local say = ngx.say
    require('dump')
    say('<pre>')
    local foo = {
      name = 'hello',
      say = function(word, bluh)
      end,
      is_bad = false,
      id = 123456
    }

    say(dump_lua(foo, 'foo'))
    say(dump_class(cache, 'lrucache'))
    dump(ngx, 'ngx')
    }
}

