config         = require "moonship.config"
codecacher     = require "moonship.codecacher"
util           = require "moonship.util"
log            = require "moonship.logger"
requestbuilder = require "moonship.requestbuilder"
sandbox        = require "moonship.sandbox"
-- response with
-- :body, :code, :headers, :status, :error
class Engine
  new: (opts) =>
    options = util.applyDefaults(opts, {:requestbuilder})
    if (options.useS3)
      options.aws = {
        aws_access_key_id: options.aws_access_key_id,
        aws_secret_access_key: options.aws_secret_access_key,
        aws_s3_code_path: options.aws_s3_code_path
      }

    @options = config(options)
    @codeCache = codecacher.CodeCacher(@options\get())

  handleResponse: (rst) =>
    return {body: rst, code: 500, status: "500 unexpected response", headers: {'Content-Type': "text/plain"}} if type(rst) ~= 'table'

    rst.code = rst.code or 200
    rst.headers = rst.headers or {}
    rst.headers["Content-Type"] = rst.headers["Content-Type"] or "text/plain"
    rst

  engage: (req) =>
    opts = @options\get()

    opts.requestbuilder.set(req) if req

    rst, err = @codeCache\get(opts)

    return { error: err, code: 500, status: "500 Engine.engage error", headers: {}  } if err
    return { code: 404, headers: {}  } unless rst

    @handleResponse(rst)

Engine
