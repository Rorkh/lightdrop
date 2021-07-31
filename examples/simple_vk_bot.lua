local lightdrop = require("lightdrop")

local bot = lightdrop("your_token_here")

bot:messageHandler("Hello", function(ctx)
	ctx.reply("Hello, stranger!")
end)
bot:messageHandler("Say (.+)", function(ctx)
	ctx.reply(ctx.args[1])
end)

bot:rawHandler("group_join", function(ctx)
	print(ctx.object.user_id .. " just joined the group.")
end)

bot:start()
