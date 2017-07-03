lfs               = require "lfs"
lru               = require "lru"
httpc             = require "moonship.httpclient"
ngin              = require "moonship.ngin"
sandbox           = require "moonship.sandbox"
util              = require "moonship.util"
plpath            = require "pl.path"
aws_auth          = require "moonship.awsauth"


local *
myUrlHandler = (opts) ->
  -- ngx.log(ngx.ERR, "mydebug: " .. secret_key)
  cleanPath, querystring  = string.match(opts.url, "([^?#]*)(.*)")
  full_path               = cleanPath
  authHeaders             = {}

  if opts.aws and opts.aws.aws_s3_code_path
    -- process s3 stuff
    aws = aws_auth.AwsAuth\new(opts.aws)
    full_path = "https://${aws.aws_host}/#{opts.aws.aws_s3_code_path}/#{full_path)"
    authHeaders = aws\get_auth_headers()

  -- cleanup path, remove double forward slash and double periods from path
  full_path = util.sanitizePath("#{fullpath}/index.moon")

  req = { url: full_path, method: "GET", capture_url: "/__code", headers: {} }

  if opts.last_modified
    req.headers["If-Modified-Since"] = opts.last_modified

  for k, v in pairs(authHeaders) do
    req.headers[k] = v

  res = httpc.request(req)

  if res.status == 200
    return res.body

  "{code: 0}"

--
-- the strategy of this cache is to:
--1. dynamically load remote file
--2. cache it locally
--3. use local file to trigger cache purge
--4. use ttl (in seconds) to determine how often to check remote file
-- when we have the file, it is recommended to check every hour
-- when we don't have the file, check every x seconds - limit by proxy
class CodeCacher

  new: (opts={}) =>
    defOpts = {appPath: "/app", ttl: 3600, codeHandler: myUrlHandler, code_cache_size: 10000}
    opts = utils.applyDefaults(opts, defOpts)

    -- should not be lower than 2 minutes
    -- user should use cache clearing mechanism
    if (opts.ttl < 120)
      opts.ttl = 120

    opts.localBasePath = plpath.abspath(opts.appPath)
    @options = opts
    @codeCache = lru.new(opts.code_cache_size)

    if (@defaultTtl < 120)
      @defaultTtl = 120

--
--if value holder is nil, initialize value holder
--if value is nil or ttl has expired
-- load File if it exists
  -- set cache for next guy
  -- set fileModification DateTime
-- doCheckRemoteFile()
  -- if remote return 200
    -- write file, load data
  -- on 404 - delete local file, set nil
  -- on other error - do nothing
-- remove from cache if not found
-- return result function

--NOTE: urlHandler should use capture to simulate debounce

  doCheckRemoteFile: (valHolder) =>
    opts = {
      url: valHolder.url
    }

    if (valHolder.fileMod ~= nil)
      opts["last_modified"] = os.date("%c", valHolder.fileMod)

    os.execute("mkdir -p \"" .. valHolder.localPath .. "\"")

    -- if remote return 200
    rsp, err = @urlHandler(opts)

    if (rsp.status == 200)
      -- ngx.say(valHolder.localPath)
      -- write file, load data

      with io.open(valHolder.localFullPath, "w")
        \write(rsp.body)
        \close()

      valHolder.fileMod = lfs.attributes valHolder.localFullPath, "modification"
      valHolder.value = sandbox.loadstring rsp.body, nil, ngin.getSandboxEnv()
    elseif (rsp.status == 404)
      -- on 404 - set nil and delete local file
      valHolder.value = nil
      os.remove(valHolder.localFullPath)

  get: (url) =>
    valHolder = @codeCache\get(url)

    -- initialize valHolder
    if (valHolder == nil)
      -- strip query string and http/https://
      domainAndPath, query = string.match(url, "([^?#]*)(.*)")
      domainAndPath = string.gsub(string.gsub(domainAndPath, "http://", ""), "https://", "")

      -- expect directory
      fileBasePath = utils.sanitizePath(@options.localBasePath .. "/" .. domainAndPath)

      -- must store locally as index.lua
      -- this way, a path can contain other paths
      localFullPath = fileBasePath .. "/index.lua"

      valHolder = {
        url: url,
        localPath: fileBasePath,
        localFullPath: localFullPath,
        lastCheck: os.time(),
        fileMod: lfs.attributes localFullPath, "modification"
      }

      -- use aws s3 if available
      if (@options.aws)
        valHolder["aws"] = @options.aws

    if (valHolder.value == nil or (valHolder.lastCheck < (os.time() - @options.ttl)))
      -- load file if it exists
      valHolder.fileMod = lfs.attributes valHolder.localFullPath, "modification"
      if (valHolder.fileMod ~= nil)

        valHolder.value = sandbox.loadfile valHolder.localFullPath, ngin.getSandboxEnv()

        -- set it back immediately for the next guy
        -- set next ttl
        valHolder.lastCheck = os.time()
        @codeCache\set url, valHolder
      else
        -- delete reference if file no longer exists/purged
        valHolder.value = nil

      @doCheckRemoteFile(valHolder)

    -- remove from cache if not found
    if valHolder.value == nil
      @codeCache\delete(url)

    valHolder.value

{
  :CodeCacher
}
