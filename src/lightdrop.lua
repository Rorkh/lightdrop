local class = require("middleclass")
local bot = require("lightdrop.backends.vk")

local lightdrop = class("lightdrop")

function lightdrop:initialize(token)
        self.token = token

        self.messageHandlers = {}
        self.rawHandlers = {}
        self.payloadHandlers = {}
end

function lightdrop:messageHandler(pattern, func)
	table.insert(self.messageHandlers, {pattern, func})
end

function lightdrop:rawHandler(etype, func)
	table.insert(self.rawHandlers, {etype, func})
end
	
function lightdrop:payloadHandler(cmd, func)
	table.insert(self.payloadHandlers, {cmd, func})
end

function lightdrop:onStart(func)
	table.insert(self.payloadHandlers, {"start", func})
end

function lightdrop:start()
	bot:new(self):start()	
end

return lightdrop
