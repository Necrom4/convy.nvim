local M = {}

local formats = require("convy.formats")

local group_modules = {
	text = "convy.converters.text",
	color = "convy.converters.color",
	temperature = "convy.converters.temperature",
	length = "convy.converters.length",
	datasize = "convy.converters.datasize",
	time = "convy.converters.time",
	angle = "convy.converters.angle",
}

function M.convert(text, input_format, output_format)
	local group = formats.get_group(input_format)
	if not group then
		error("Unknown input format: " .. tostring(input_format))
	end

	local out_group = formats.get_group(output_format)
	if not out_group then
		error("Unknown output format: " .. tostring(output_format))
	end

	if group ~= out_group then
		error(
			string.format(
				"Cannot convert between incompatible format groups: %s (%s) -> %s (%s)",
				input_format,
				formats.groups[group].label,
				output_format,
				formats.groups[out_group].label
			)
		)
	end

	local module_path = group_modules[group]
	if not module_path then
		error("No converter module for group: " .. tostring(group))
	end

	return require(module_path).convert(text, input_format, output_format)
end

return M
