local lightdrop = require("lightdrop")
local backend = require("lightdrop.backends.vk")

local bot = lightdrop:bot("your_token_here")

bot:messageHandler("Hello", function(ctx)
	ctx.reply("Hello, stranger!")
end)
bot:messageHandler("Say (.+)", function(ctx)
	ctx.reply(ctx.args[1])
end)

bot:rawHandler("group_join", function(ctx)
	print(ctx.object.user_id .. " just joined the group.")
end)

backend:start(bot)
