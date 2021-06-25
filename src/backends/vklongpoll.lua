local vklib = require("vklib")
local turbo = require("turbo")
local json = require("cjson")

local backend = {}

function backend:start(bot)
	local obj = {}
		obj.name = "VK LongPoll"

		obj.group = {}
		obj.session = vklib:Session(bot.token)
		obj.url_template = "%s?act=a_check&key=%s&wait=25&ts=%s"
	
	function obj:_handle_event(event)
		local object = event.object
		local etype = event.type

		local ctx = {
			session = obj.session,
			object = object
		}

		if etype == "message_new" then
			local message = object.message

			ctx.reply = function(text)
				ctx.session.messages.send{user_id=message.from_id, random_id=math.random(1,100000000), message=text}:cb()
			end			

			for _, handler in ipairs(bot.messageHandlers) do
				ctx.args = {message.text:match(handler[1])}

				if next(ctx.args) ~= nil then
					handler[2](ctx)		
				end
			end
		else
			for _, handler in ipairs(bot.rawHandlers) do
				if handler[1] == etype then
					handler[2](ctx)
				end
			end
		end
	end
		
	function obj:_handle_events(response)
		for _, event in ipairs(response.updates) do
			self:_handle_event(event)
		end
        end

        function obj:_request_update()
                local req = string.format(self.url_template, self.server, self.key, self.ts)
                local res = coroutine.yield(turbo.async.HTTPClient({verify_ca=false}):fetch(req))

                local body = res.body
                if body then
                        local data = json.decode(body)

			local failed = data.failed
			if failed == 3 then
				obj.session.groups.getLongPollServer{group_id = self.group.id}:cb(function(resp)
					self.key = resp.key
					self.ts = resp.ts
				end)			
			elseif failed == 2 then
				obj.session.groups.getLongPollServer{group_id = self.group.id}:cb(function(resp)
					self.key = resp.key
				end)
			else
                        	self.ts = data.ts
			end

                        self:_handle_events(data)
                        self:_request_update()
                end
        end

	obj.session.groups.getById{fields = "screen_name"}:cb(function(res)
		if not res.response then return end

		obj.group.id = res.response[1].id
		obj.group.id_name = res.response[1].screen_name
		obj.group.name = res.response[1].name
	end)
	if not obj.group.id then error("Wrong token ") end

	print("Starting bot for " .. obj.group.name .. " (vk.com/" .. obj.group.id_name .. ")")
	obj.session.groups.getLongPollServer{group_id = obj.group.id}:cb(function(resp)
		obj.key = resp.response.key
		obj.server = resp.response.server
		obj.ts = resp.response.ts
	end)

	local inst = turbo.ioloop.instance()
	
	inst:add_callback(function()
		obj:_request_update()
		inst:close()
	end)

	inst:start()

	setmetatable(obj, self)
	self.__index = self

	return obj
end

return backend
