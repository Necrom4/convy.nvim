local M = {}

local formats = require("convy.formats")

-- Converter module per group kind.
local kind_modules = {
	linear = "convy.converters.linear",
	encoding = "convy.converters.encoding",
	color = "convy.converters.color",
	temperature = "convy.converters.temperature",
	custom = "convy.converters.custom",
}

function M.convert(text, input_format, output_format)
	local group = formats.get_group(input_format)
	if not group then
		error("Unknown input format: " .. tostring(input_format), 0)
	end

	local out_group = formats.get_group(output_format)
	if not out_group then
		error("Unknown output format: " .. tostring(output_format), 0)
	end

	if group ~= out_group then
		error(
			string.format(
				"Cannot convert between incompatible format groups: %s (%s) -> %s (%s)",
				input_format,
				formats.label(group),
				output_format,
				formats.label(out_group)
			)
		)
	end

	local kind = formats.get_group_def(input_format).kind
	local module_path = kind_modules[kind]
	if not module_path then
		error("No converter for kind: " .. tostring(kind), 0)
	end

	return require(module_path).convert(text, input_format, output_format)
end

return M
