local lightdrop = require("lightdrop")

local bot = lightdrop("d8fc943e021e48aaebd8805849fa187f1011603393f393abe1fa81e8587c850a318f871205cc05ca7ff9f")

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