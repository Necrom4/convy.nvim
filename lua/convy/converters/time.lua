local M = {}

local to_seconds = {
	ms = 0.001,
	s = 1,
	min = 60,
	h = 3600,
}

local function has_unit_suffix(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text
	return clean:match(input_format .. "$") ~= nil
end

local function parse_time(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%d%.]+)")
	if not num_str then
		error("Could not parse time value from: " .. text, 0)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str, 0)
	end

	local factor = to_seconds[input_format]
	if not factor then
		error("Unknown time format: " .. tostring(input_format), 0)
	end

	return value * factor
end

local function format_time(seconds, output_format, include_suffix)
	local factor = to_seconds[output_format]
	if not factor then
		error("Unknown time format: " .. tostring(output_format), 0)
	end

	local value = seconds / factor

	local formatted
	if math.abs(value - math.floor(value + 0.5)) < 1e-9 then
		formatted = string.format("%d", math.floor(value + 0.5))
	else
		formatted = string.format("%.4f", value)
		formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
	end

	if include_suffix then
		formatted = formatted .. output_format
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local suffix = has_unit_suffix(text, input_format)
	local seconds = parse_time(text, input_format)
	return format_time(seconds, output_format, suffix)
end

return M
