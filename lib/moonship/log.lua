local logger = require("log")
local list_writer = require("log.writer.list")
local console_color = require("log.writer.console.color")
local util = require("moonship.util")
local to_json = util.to_json
local doformat
doformat = function(p)
  if type(p) == "table" then
    return to_json(p)
  end
  if p == nil then
    return "nil"
  end
  return tostring(p)
end
local sep = ' '
local formatter
formatter = function(...)
  local params
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local v = _list_0[_index_0]
      _accum_0[_len_0] = doformat(v)
      _len_0 = _len_0 + 1
    end
    params = _accum_0
  end
  return table.concat(params, sep)
end
local log
log = logger.new("info", list_writer.new(console_color.new()), formatter)
return log