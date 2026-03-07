local M = {}

local to_bytes = {
	B = 1,
	KB = 1024,
	MB = 1024 * 1024,
	GB = 1024 * 1024 * 1024,
	TB = 1024 * 1024 * 1024 * 1024,
}

local function has_unit_suffix(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text
	return clean:match(input_format .. "$") ~= nil
end

local function parse_datasize(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%d%.]+)")
	if not num_str then
		error("Could not parse data size value from: " .. text)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str)
	end

	local factor = to_bytes[input_format]
	if not factor then
		error("Unknown data size format: " .. tostring(input_format))
	end

	return value * factor
end

local function format_datasize(bytes, output_format, include_suffix)
	local factor = to_bytes[output_format]
	if not factor then
		error("Unknown data size format: " .. tostring(output_format))
	end

	local value = bytes / factor

	local formatted
	if math.abs(value - math.floor(value + 0.5)) < 1e-9 then
		formatted = string.format("%d", math.floor(value + 0.5))
	else
		formatted = string.format("%.2f", value)
		formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
	end

	if include_suffix then
		formatted = formatted .. output_format
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local suffix = has_unit_suffix(text, input_format)
	local bytes = parse_datasize(text, input_format)
	return format_datasize(bytes, output_format, suffix)
end

return M
