local M = {}

local shared = require("convy.converters.shared")

local to_seconds = {
	ms = 0.001,
	s = 1,
	min = 60,
	h = 3600,
}

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

local function format_time(seconds, output_format, suffix)
	local factor = to_seconds[output_format]
	if not factor then
		error("Unknown time format: " .. tostring(output_format), 0)
	end

	local value = seconds / factor

	local formatted = shared.format_number(value, 4)

	if suffix then
		formatted = formatted .. shared.apply_casing(output_format, suffix)
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local _, suffix = shared.detect_suffix(text, input_format)
	local seconds = parse_time(text, input_format)
	return format_time(seconds, output_format, suffix)
end

return M
