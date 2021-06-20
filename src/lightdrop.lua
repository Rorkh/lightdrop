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
