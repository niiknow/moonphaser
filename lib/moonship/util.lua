local url = require("socket.url")
local cjson_safe = require("cjson.safe")
local tablex = require("pl.tablex")
local concat, insert, sort
do
  local _obj_0 = table
  concat, insert, sort = _obj_0.concat, _obj_0.insert, _obj_0.sort
end
local url_unescape, url_escape, url_parse, url_build, trim, path_sanitize, slugify, string_split, json_encodable, from_json, to_json, query_string_encode, resolveGithubRaw, applyDefaults
url_unescape = function(str)
  return url.unescape(str)
end
url_escape = function(str)
  return string.gsub(str, "([ /?:@~!$&'()*+,;=%[%]])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end
url_parse = function(str)
  return url.parse(str)
end
url_build = function(parts, includeQuery)
  if includeQuery == nil then
    includeQuery = true
  end
  local out = parts.path or ""
  if includeQuery then
    if parts.query then
      out = out .. ("?" .. parts.query)
    end
    if parts.fragment then
      out = out .. ("#" .. parts.fragment)
    end
  end
  do
    local host = parts.host
    if host then
      host = "//" .. host
      if parts.port then
        host = host .. (":" .. parts.port)
      end
      if parts.scheme and parts.scheme ~= "" then
        host = parts.scheme .. ":" .. host
      end
      if parts.path and out:sub(1, 1) ~= "/" then
        out = "/" .. out
      end
      out = host .. out
    end
  end
  return out
end
trim = function(str, regex)
  if regex == nil then
    regex = "%s*"
  end
  str = tostring(str)
  if #str > 200 then
    return str:gsub("^" .. tostring(regex), ""):reverse():gsub("^" .. tostring(regex), ""):reverse()
  else
    return str:match("^" .. tostring(regex) .. "(.-)" .. tostring(regex) .. "$")
  end
end
path_sanitize = function(str)
  str = tostring(str)
  return str:gsub("[^a-zA-Z0-9.-_/]", ""):gsub("%.%.+", ""):gsub("//+", "/")
end
slugify = function(str)
  str = tostring(str)
  return (str:gsub("[%s_]+", "-"):gsub("[^%w%-]+", ""):gsub("-+", "-")):lower()
end
string_split = function(str, sep, dest)
  if dest == nil then
    dest = { }
  end
  str = tostring(str)
  for str in string.gmatch(str, "([^" .. (sep or "%s") .. "]+)") do
    insert(dest, str)
  end
  return dest
end
json_encodable = function(obj, seen)
  if seen == nil then
    seen = { }
  end
  local _exp_0 = type(obj)
  if "table" == _exp_0 then
    if not (seen[obj]) then
      seen[obj] = true
      local _tbl_0 = { }
      for k, v in pairs(obj) do
        if type(k) == "string" or type(k) == "number" then
          _tbl_0[k] = json_encodable(v)
        end
      end
      return _tbl_0
    end
  elseif "function" == _exp_0 or "userdata" == _exp_0 or "thread" == _exp_0 then
    return nil
  else
    return obj
  end
end
from_json = function(obj)
  return cjson_safe.decode(obj)
end
to_json = function(obj)
  return cjson_safe.encode((json_encodable(obj)))
end
query_string_encode = function(t, sep, quote, seen)
  if sep == nil then
    sep = "&"
  end
  if quote == nil then
    quote = ""
  end
  if seen == nil then
    seen = { }
  end
  local query = { }
  local keys = { }
  for k in pairs(t) do
    keys[#keys + 1] = tostring(k)
  end
  sort(keys)
  for _, k in ipairs(keys) do
    local v = t[k]
    local _exp_0 = type(v)
    if "table" == _exp_0 then
      if not (seen[v]) then
        seen[v] = true
        local tv = query_string_encode(v, sep, quote, seen)
        v = tv
      end
    elseif "function" == _exp_0 or "userdata" == _exp_0 or "thread" == _exp_0 then
      _ = nil
    else
      v = url_escape(tostring(v))
    end
    k = url_escape(tostring(k))
    if v ~= "" then
      query[#query + 1] = string.format('%s=%s', k, quote .. v .. quote)
    else
      query[#query + 1] = name
    end
  end
  return concat(query, sep)
end
resolveGithubRaw = function(modname)
  local capturePath = "https://raw.githubusercontent.com/"
  if string.find(modname, "github.com/") then
    local user, repo, branch, pathx, query = string.match(modname, "github%.com/([^/]+)(/[^/]+)/tree(/[^/]+)(/[^?#]*)(.*)")
    local path, file = string.match(pathx, "^(.*/)([^/]*)$")
    local base = string.format("%s%s%s%s%s", capturePath, user, repo, branch, path)
    return base, string.gsub(string.gsub(file, "%.moon$", ""), '%.', "/") .. ".moon", query
  end
  return __ghrawbase, string.gsub(string.gsub(modname, "%.moon$", ""), '%.', "/") .. ".moon", ""
end
applyDefaults = function(opts, defOpts)
  for k, v in pairs(defOpts) do
    if not (opts[k]) then
      opts[k] = v
    end
  end
  return opts
end
return {
  url_escape = url_escape,
  url_unescape = url_unescape,
  url_parse = url_parse,
  url_build = url_build,
  trim = trim,
  path_sanitize = path_sanitize,
  slugify = slugify,
  string_split = string_split,
  table_sort_keys = table_sort_keys,
  json_encodable = json_encodable,
  from_json = from_json,
  to_json = to_json,
  query_string_encode = query_string_encode,
  resolveGithubRaw = resolveGithubRaw,
  applyDefaults = applyDefaults
}