# Kong plugin for API Particulier authorization

This plugin filters requests with a given API key authorization server

## Pré-requis

- Lua
- luarocks :  https://github.com/luarocks/luarocks
- kong : https://getkong.org/

## Installation
1. Install the rock
```
luarocks make
```
2. Add plugin in kong.conf custom plugins

3. Connect the plugin with an API
```
curl -XPOST http://localhost:8001/apis/api-particulier/plugins/ \
  -d "name=customAuth" \
  -d "config.authorize_scheme=http" \
  -d "config.authorize_host=localhost:{{ particulier_auth_api_port }}" \
  -d "config.authorize_path=/api/auth/authorize" \
  -d "config.whitelisted_paths=/api/ping,/api/impots/ping,/api/caf/ping,/api/swagger.yml"
```

## Test
First install all dependencies (not tested)
- For debian users :
```
./spec/install.sh
```

- For mac user : ```brew install openresty/brew/openresty```

`luarocks install busted`


Then run the tests (it needs to have an authorization server started listening to port 7000)
```
./bin/busted
```
