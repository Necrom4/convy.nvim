local M = {}

-- Single source of truth. Groups are ordered; each format entry carries
-- everything about itself: canonical `name`, optional `display` override,
-- and (for unit groups) the conversion `factor` relative to the group base,
-- plus parse/format hints (`signed`, `decimals`, `dynamic`).
M.groups = {
	{
		key = "encoding",
		label = "Encoding",
		kind = "encoding",
		formats = {
			{ name = "ascii" },
			{ name = "bin" },
			{ name = "dec" },
			{ name = "hex" },
			{ name = "oct" },
			{ name = "b64" },
			{ name = "sha256" },
			{ name = "md5" },
			{ name = "morse" },
		},
	},
	{
		key = "datasize",
		label = "Data Size",
		kind = "linear",
		formats = {
			{ name = "b", display = "B", suffix = "b", factor = 1 },
			{ name = "kb", display = "KB", suffix = "kb", factor = 1024 },
			{ name = "mb", display = "MB", suffix = "mb", factor = 1024 ^ 2 },
			{ name = "gb", display = "GB", suffix = "gb", factor = 1024 ^ 3 },
			{ name = "tb", display = "TB", suffix = "tb", factor = 1024 ^ 4 },
		},
	},
	{
		key = "length",
		label = "Length",
		kind = "linear",
		signed = true,
		decimals = 4,
		formats = {
			{ name = "px", suffix = "px", factor = 0.0254 / 96 },
			{ name = "rem", suffix = "rem", dynamic = "font" },
			{ name = "em", suffix = "em", dynamic = "font" },
			{ name = "pt", suffix = "pt", factor = 0.0254 / 72 },
			{ name = "mm", suffix = "mm", factor = 0.001 },
			{ name = "cm", suffix = "cm", factor = 0.01 },
			{ name = "m", suffix = "m", factor = 1 },
			{ name = "km", suffix = "km", factor = 1000 },
			{ name = "in", suffix = "in", factor = 0.0254 },
			{ name = "ft", suffix = "ft", factor = 0.3048 },
			{ name = "yd", suffix = "yd", factor = 0.9144 },
			{ name = "mi", suffix = "mi", factor = 1609.344 },
		},
	},
	{
		key = "color",
		label = "Color",
		kind = "color",
		formats = {
			{ name = "hex_color" },
			{ name = "rgb" },
			{ name = "hsl" },
			{ name = "tailwind" },
		},
	},
	{
		key = "time",
		label = "Time",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "ms", suffix = "ms", factor = 0.001 },
			{ name = "s", suffix = "s", factor = 1 },
			{ name = "min", suffix = "min", factor = 60 },
			{ name = "h", suffix = "h", factor = 3600 },
		},
	},
	{
		key = "angle",
		label = "Angle",
		kind = "linear",
		signed = true,
		formats = {
			{ name = "deg", suffix = "deg", factor = 1 },
			{ name = "rad", suffix = "rad", factor = 180 / math.pi, decimals = 6 },
			{ name = "grad", suffix = "grad", factor = 0.9 },
			{ name = "turn", suffix = "turn", factor = 360, decimals = 6 },
		},
	},
	{
		key = "temperature",
		label = "Temperature",
		kind = "temperature",
		signed = true,
		formats = {
			{ name = "celsius", letter = "C" },
			{ name = "fahrenheit", letter = "F" },
			{ name = "kelvin", letter = "K" },
		},
	},
}

-- Lookups: name -> group, name -> entry.
local name_to_group = {}
local name_to_entry = {}
for _, group in ipairs(M.groups) do
	for _, entry in ipairs(group.formats) do
		name_to_group[entry.name] = group
		name_to_entry[entry.name] = entry
	end
end

function M.get_group(name)
	local group = name_to_group[name]
	return group and group.key
end

function M.get_group_def(name)
	return name_to_group[name]
end

function M.get_entry(name)
	return name_to_entry[name]
end

function M.label(group_key)
	for _, group in ipairs(M.groups) do
		if group.key == group_key then
			return group.label
		end
	end
end

function M.display(name)
	local entry = name_to_entry[name]
	return entry and (entry.display or entry.name) or name
end

function M.get_compatible_outputs(name)
	local group = name_to_group[name]
	if not group then
		return {}
	end

	local outputs = {}
	for _, entry in ipairs(group.formats) do
		if entry.name ~= name then
			table.insert(outputs, entry.name)
		end
	end
	return outputs
end

function M.get_all_input_formats()
	local result = { "auto" }
	for _, group in ipairs(M.groups) do
		for _, entry in ipairs(group.formats) do
			table.insert(result, entry.name)
		end
	end
	return result
end

function M.get_output_formats(input_format)
	if input_format == "auto" then
		local result = {}
		for _, group in ipairs(M.groups) do
			for _, entry in ipairs(group.formats) do
				table.insert(result, entry.name)
			end
		end
		return result
	end

	return M.get_compatible_outputs(input_format)
end

function M.are_compatible(format_a, format_b)
	local group_a = name_to_group[format_a]
	local group_b = name_to_group[format_b]
	return group_a ~= nil and group_a == group_b
end

return M
