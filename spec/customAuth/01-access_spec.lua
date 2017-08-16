local helpers = require "spec.helpers"
local handler = require "kong.plugins.customAuth.handler"

describe("custom-auth: customAuth (access)", function()
  local client

  setup(function()
    local apiOK = assert(helpers.dao.apis:insert {
        name = "api-OK",
        hosts = { "ok.com" },
        upstream_url = "http://mockbin.com",
    })

    assert(helpers.dao.plugins:insert {
      api_id = apiOK.id,
      name = "customAuth",
      config = {
        authorize_scheme = "http",
        authorize_host = "httpbin.org",
        authorize_path = "/ip"
      }
    })

    local apiNOK = assert(helpers.dao.apis:insert {
        name = "api-NOK",
        hosts = { "nok.com" },
        upstream_url = "http://mockbin.com",
    })

    local config = {}
    assert(helpers.dao.plugins:insert {
      api_id = apiNOK.id,
      name = "customAuth",
      config = {
        authorize_scheme = "http",
        authorize_host = "httpbin.org",
        authorize_path = "/boom",
        skipped_paths = {"/ip"}
      }
    })

    -- start kong, while setting the config item `custom_plugins` to make sure our
    -- plugin gets loaded
    assert(helpers.start_kong {custom_plugins = "customAuth"})
  end)

  teardown(function()
    helpers.stop_kong()
  end)

  before_each(function()
    client = helpers.proxy_client()
  end)

  after_each(function()
    if client then client:close() end
  end)

  it("should build authorize url", function()
    local conf = {
      authorize_scheme = "http",
      authorize_host = "test.host",
      authorize_path = "/authorize"
    }
    local url = handler:authorize_url(conf)
    assert.are.equals(url, "http://test.host/authorize")
  end)

  describe("it requests OKAPI (auth service respond 200)", function()
    it("should authorize on a 200 response from authorize service", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          host = "ok.com"
        }
      })

      assert.response(r).has.status(200)
    end)
  end)

  describe("it request NOKAPI (auth service does not respond 200)", function()
    it("You shall not pass", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          host = "nok.com"
        }
      })

      assert.response(r).has.status(401)
    end)

    it("You shall pass if in skipped_paths", function()
      local r = assert(client:send {
        method = "GET",
        path = "/ip",
        headers = {
          host = "nok.com"
        }
      })

      assert.response(r).has.status(200)
    end)
  end)
end)
