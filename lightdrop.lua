local vklib = require("deps/vklib")
local turbo = require("turbo")
local escape = turbo.escape

local ffi = require("ffi")
ffi.cdef "unsigned int sleep(unsigned int seconds);"

local lightdrop = {}

function lightdrop:bot(token)
	local bot = {}
		bot.group = {}
		bot.token = token

		bot.messageHandlers = {}
		bot.rawHandlers = {}	

	function bot:messageHandler(regex, func)
		-- Maybe self.handlers[regex] = func pattern?
		-- TODO: Make comparison

		table.insert(self.messageHandlers, {regex, func})
	end

	function bot:rawHandler(etype, func)
		table.insert(self.rawHandlers, {etype, func})
	end
	
	setmetatable(bot, self)
	self.__index = self

	return bot
end

return lightdrop