local http = require "resty.http"

local plugin = require("kong.plugins.base_plugin"):extend()

function plugin:new()
  plugin.super.new(self, "customAuth")
end

function plugin:init_worker(config)
  plugin.super.init_worker(self)
end

function plugin:access(conf)
  plugin.super.access(self)


  local httpc = http:new()

  if has_value(conf.skipped_paths, ngx.var.request_uri) then
    return
  else
    local headers = ngx.req.get_headers()
    headers['host'] = nil
    local res, err = httpc:request_uri(plugin:authorize_url(conf), {
      method = "GET",
      path = conf.authorize_path,
      headers =  headers
    })

    if not res then
      ngx.log(ngx.ERR, require 'pl.pretty'.dump(err))
      plugin:exit_unauthorized(err)
    else
      if res.status == 200 then
        ngx.log(ngx.ERR, require 'pl.pretty'.dump(res.body))
        return
      else
        plugin:exit_unauthorized(res.body)
      end
    end
  end
end

function plugin:authorize_url(conf)
  return conf.authorize_scheme .. "://" .. conf.authorize_host .. conf.authorize_path
end

function plugin:exit_unauthorized(reason)
  if reason == nil then reason = "" end

  ngx.status = ngx.HTTP_UNAUTHORIZED

  ngx.header["Content-Type"] = "application/json"
  ngx.say(reason)
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

plugin.PRIORITY = 1000

return plugin
