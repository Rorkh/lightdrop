local json = require("cjson")

local keyboard = {}

function keyboard:new(one_time)
	local obj = {}
		obj.struct = {one_time=one_time, buttons={}}

	function obj:add_button(struct)
		local element = {}
		setmetatable(element, json.array_mt)
		
		struct.action = {
			type = struct.type,
			payload = string.format("{\"command\": \"%s\"}", struct.command),
			label = struct.label
		}

		struct.command = nil
		struct.type = nil
		struct.label = nil
		
		table.insert(element, struct)
		table.insert(self.struct.buttons, element)
	end

	function obj:get()
		return json.encode(self.struct)		
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

return keyboard
