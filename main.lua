local lightdrop = require("lightdrop")
local backend = require("backends/vklongpoll")

local bot = lightdrop:bot("19da8ca6a6e1e3fea33bdcc6aedc8575ec1e09b22de1023ad9920f36522ef173b105984f23987ca562ad5")
bot:messageHandler("Hello", function(ctx)
	ctx.reply("Hello!")
end)
bot:rawHandler("group_join", function(ctx)
	print(ctx.object.user_id)
end)

backend:start(bot)
