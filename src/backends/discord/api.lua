local json = require("cjson")
local turbo = require("turbo")

local api = {}

local BASE_URL = "https://discord.com/api/v8"

local JSON = 'application/json'
local PRECISION = 'millisecond'
local MULTIPART = 'multipart/form-data;boundary='

local USER_AGENT = string.format('DiscordBot (http://github.com/Rorkh/lightdrop, 1)')

function api:new(token)
	local obj = {}
		obj.token = token
		obj.endpoints = require("backends/discord/endpoints")
	local authorization = "Bot " .. token
	
	function obj:commit(method, url, req, payload, callback)
		local inst = turbo.ioloop.instance()
		inst:add_callback(function()
			local res = coroutine.yield(turbo.async.HTTPClient({verify_ca=false}):fetch(url, {
				body = payload,
				user_agent = USER_AGENT,

				method = method,
				on_headers = function(h)
					for k, v in pairs(req) do
						h:add(k, v)
					end
				end
			}))
			
			if callback then callback(json.decode(res.body)) end

			inst:close()
		end)
		inst:start()
	end

	function obj:request(method, endpoint, payload, callback)
		local url = BASE_URL .. endpoint
		local req = {
			['User-Agent'] = USER_AGENT,
			['X-RateLimit-Precision'] =  PRECISION,
			['Authorization'] = authorization,
		}
		
		if payload then
			payload = payload and json.encode(payload) or '{}'
			req['Content-Type'] = JSON
			req['Content-Length'] = #payload
		end

		self:commit(method, url, req, payload, callback)
	end

	function obj:getCurrentUser(callback)
		self:request("GET", self.endpoints.USER_ME, nil, callback)
	end

	function obj:getGatewayBot(callback)
		self:request("GET", self.endpoints.GATEWAY_BOT, nil, callback)
	end

	setmetatable(obj, self)
	self.__index = self
	
	return obj
end

return api
