_G.TURBO_SSL = true

local turbo = require("turbo")
local json = require("cjson")

local ffi = require "ffi"
local C = ffi.C
ffi.cdef "unsigned int sleep(unsigned int seconds);"

local discord = require("backends/discord/api")

local backend = {}

function backend:start(bot)
	local obj = {}
		obj.name = "Discord"
		obj.api = discord:new(bot.token)
	
	function obj:_identify(socket)
		local message = json.encode({
			op = 2,
			d = {
				token = bot.token,
				properties = {
      					["$os"] = jit.os,
      					["$browser"] = "lightdrop",
     					["$device"] = "lightdrop",
					['$referrer'] = '',
					['$referring_domain'] = '',
    				}
			}
		})
			
		self.seq = nil		
		socket:write_message(message)
	end

	function obj:_handle_heartbeat(socket, data)
		local interval = data.d.heartbeat_interval / 1000
		local message = json.encode({op = 1, d = self.seq or 0}) -- json.null
		
		socket:write_message(message)

		local thread = turbo.thread.Thread(function(th)
			while true do
				C.sleep(interval)
				socket:write_message(message)
			end
		end)

		self:_identify(socket)
		thread:wait_for_finish()
	end

	function obj:_handle_event(socket, data)
		local etype = data.t
		local d = data.d
		
		self.seq = data.s

		local ctx = {
			api = self.api,
			object = d
		}		

		if etype == "MESSAGE_CREATE" then
			for _, handler in ipairs(bot.messageHandlers) do
				ctx.args = {d.content:match(handler[1])}
				ctx.reply = function(message)
					local endpoint = string.format(self.api.endpoints["CHANNEL_MESSAGE"], d.channel_id, "")
					self.api:request("POST", endpoint, {content = message})
				 end

                                if next(ctx.args) ~= nil then
					handler[2](ctx)
				end
			end		
		else
			for _, handler in ipairs(bot.rawHandlers) do
				if handler[1] == type then
					handler[2](ctx)
				end
			end
		end
	end
	
	local user
	obj.api:getCurrentUser(function(data)
		user = data
	end)
	if not user.username then error("Wrong token") end

	print(string.format("Authenticated as %s#%s", user.username, user.discriminator))

	local gateway
	obj.api:getGatewayBot(function(data)
		gateway = data
	end)

	obj.gateway = gateway.url .. "/?v=6&encoding=json"

	turbo.ioloop.instance():add_callback(function()
		turbo.websocket.WebSocketClient(obj.gateway, {
			ssl_options = {verify_ca = false},

			on_message = function(socket, msg)
				local data = json.decode(msg)
				local op = data.op

				if op == 10 then
					obj:_handle_heartbeat(socket, data)
				elseif op == 0 then
					obj:_handle_event(socket, data)
				end
			end
		})
	end):start()
	
	setmetatable(obj, self)
	self.__index = self

	return obj
end

return backend
