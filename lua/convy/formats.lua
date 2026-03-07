local M = {}

M.group_order = { "encoding", "datasize", "length", "color", "time", "angle", "temperature" }

M.groups = {
	angle = {
		label = "Angle",
		formats = { "deg", "rad", "grad", "turn" },
	},
	color = {
		label = "Color",
		formats = { "hex_color", "rgb", "hsl", "tailwind" },
	},
	datasize = {
		label = "Data Size",
		formats = { "B", "KB", "MB", "GB", "TB" },
	},
	encoding = {
		label = "Encoding",
		formats = { "ascii", "bin", "dec", "hex", "oct", "b64", "morse" },
	},
	length = {
		label = "Length",
		formats = { "px", "rem", "pt", "mm", "cm", "m", "km", "in", "ft", "yd", "mi" },
	},
	temperature = {
		label = "Temperature",
		formats = { "celsius", "fahrenheit", "kelvin" },
	},
	time = {
		label = "Time",
		formats = { "ms", "s", "min", "h" },
	},
}

-- Build a reverse lookup: format_name -> group_key
local format_to_group = {}
for group_key, group in pairs(M.groups) do
	for _, fmt in ipairs(group.formats) do
		format_to_group[fmt] = group_key
	end
end

function M.get_group(format_name)
	return format_to_group[format_name]
end

function M.get_compatible_outputs(format_name)
	local group_key = format_to_group[format_name]
	if not group_key then
		return {}
	end

	local outputs = {}
	for _, fmt in ipairs(M.groups[group_key].formats) do
		if fmt ~= format_name then
			table.insert(outputs, fmt)
		end
	end
	return outputs
end

function M.get_group_formats_with_auto(format_name)
	local group_key = format_to_group[format_name]
	if not group_key then
		return { "auto" }
	end

	local result = { "auto" }
	for _, fmt in ipairs(M.groups[group_key].formats) do
		table.insert(result, fmt)
	end
	return result
end

function M.get_all_input_formats()
	local result = { "auto" }
	for _, group_key in ipairs(M.group_order) do
		for _, fmt in ipairs(M.groups[group_key].formats) do
			table.insert(result, fmt)
		end
	end
	return result
end

function M.get_output_formats(input_format)
	if input_format == "auto" then
		local result = {}
		for _, group_key in ipairs(M.group_order) do
			for _, fmt in ipairs(M.groups[group_key].formats) do
				table.insert(result, fmt)
			end
		end
		return result
	end

	return M.get_compatible_outputs(input_format)
end

function M.are_compatible(format_a, format_b)
	local group_a = format_to_group[format_a]
	local group_b = format_to_group[format_b]
	return group_a ~= nil and group_a == group_b
end

return M
