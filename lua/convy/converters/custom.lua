local M = {}

local formats = require("convy.formats")

-- Convert via the group's shared base: out.encode(in.decode(text)).
function M.convert(text, input_format, output_format)
	local in_entry = formats.get_entry(input_format)
	local out_entry = formats.get_entry(output_format)

	local base = in_entry.decode(text)
	if base == nil then
		error("Could not decode " .. input_format .. " value from: " .. text, 0)
	end

	return out_entry.encode(base)
end

return M
