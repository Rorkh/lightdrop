local vklib = require("vklib")
local turbo = require("turbo")
local json = require("cjson")

local keyboard = require("lightdrop.backends.vk.keyboard")
local backend = class("vkbackend")

local message_context = {
	reply = function(ctx, text)
		ctx.session.messages.send{user_id=ctx.message.from_id, random_id=math.random(1,100000000), message=text}:cb()
	end,
	send_keyboard = function(ctx, struct, text)
		ctx.session.messages.send{user_id=ctx.message.from_id, random_id=math.random(1,100000000), keyboard=struct, message=text}:cb()
	end,
	clear_keyboard = function(ctx, text)
		ctx.session.messages.send{user_id=ctx.message.from_id, random_id=math.random(1,100000000), keyboard=backend.keyboard:new():get(), message=text}:cb()
	end,	
}

function backend:initialize(bot)
    self.group = {}
	self.session = vklib:Session(bot.token)
    self.bot = bot

    self.keyboard = keyboard
    self.url_template = "%s?act=a_check&key=%s&wait=25&ts=%s"
end

function backend:handle_payload(object, ctx)
     local data = json.decode(payload)

    setmetatable(ctx, {
        __index = message_context
    })

    for _, handler in ipairs(self.bot.payloadHandlers) do
        if data.command == handler[1] then
            handler[2](ctx)
        end
    end
end

function backend:handle_command(object, ctx)
    setmetatable(ctx, {
        __index = message_context
    })

    for _, handler in ipairs(self.bot.messageHandlers) do
        ctx.args = {message.text:match(handler[1])}

        if next(ctx.args) ~= nil then
            handler[2](ctx)
        end
    end
end

function backend:handle_message(object, ctx)
    local message = object.message
    local payload = message.payload

    ctx.message = message

    if payload then self:handle_payload(object, ctx) else self:handle_command(object, ctx) end
end

function backend:handle_raw(object, ctx)
    for _, handler in ipairs(self.bot.rawHandlers) do
        if handler[1] == etype then
            handler[2](ctx)
        end
    end
end

function backend:handle_event(event)
    local object = event.object
    local etype = event.type
	
    local ctx = {session = self.session, object = object}

    if etype == "message_new" then 
        self:handle_message(object, ctx) 
    else
        self:handle_raw(object, ctx)
    end
end

function backend:handle_events(response)
    for _, event in ipairs(response.updates) do
        self:handle_event(event)
    end
end

function backend:request_update()
    local req = string.format(self.url_template, self.server, self.key, self.ts)

    local res = coroutine.yield(turbo.async.HTTPClient({
        verify_ca = false
    }):fetch(req))

    local body = res.body

    if body then
        local data = json.decode(body)
        local failed = data.failed

        if failed == 3 then
            self.session.groups.getLongPollServer{
                group_id = self.group.id
            }:cb(function(resp)
                self.key = resp.key
                self.ts = resp.ts
            end)
        elseif failed == 2 then
            self.session.groups.getLongPollServer{
                group_id = self.group.id
            }:cb(function(resp)
                self.key = resp.key
            end)
        else
            self.ts = data.ts
        end

        self:handle_events(data)
        self:request_update()
    end
end

function backend:start()
    self.session.groups.getById{
        fields = "screen_name"
    }:cb(function(res)
        if not res.response then return end
        self.group.id = res.response[1].id
        self.group.id_name = res.response[1].screen_name
        self.group.name = res.response[1].name
    end)

    if not self.group.id then
        error("Wrong token ")
    end

    print("Starting bot for " .. self.group.name .. " (vk.com/" .. self.group.id_name .. ")")

    self.session.groups.getLongPollServer{
        group_id = self.group.id
    }:cb(function(resp)
        self.key = resp.response.key
        self.server = resp.response.server
        self.ts = resp.response.ts
    end)

    local inst = turbo.ioloop.instance()

    inst:add_callback(function()
        self:request_update()
        inst:close()
    end)

    inst:start()
end

return backend
