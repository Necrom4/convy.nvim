local M = {}

local shared = require("convy.converters.shared")

local to_degrees = {
	deg = 1,
	rad = 180 / math.pi,
	grad = 0.9,
	turn = 360,
}

local function parse_angle(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%-]?[%d%.]+)")
	if not num_str then
		error("Could not parse angle value from: " .. text, 0)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str, 0)
	end

	local factor = to_degrees[input_format]
	if not factor then
		error("Unknown angle format: " .. tostring(input_format), 0)
	end

	return value * factor
end

-- Format a degrees value to the target angle format.
local function format_angle(degrees, output_format, suffix)
	local factor = to_degrees[output_format]
	if not factor then
		error("Unknown angle format: " .. tostring(output_format), 0)
	end

	local value = degrees / factor

	local decimals = (output_format == "rad" or output_format == "turn") and 6 or 2
	local formatted = shared.format_number(value, decimals)

	if suffix then
		formatted = formatted .. shared.apply_casing(output_format, suffix)
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local _, suffix = shared.detect_suffix(text, input_format)
	local degrees = parse_angle(text, input_format)
	return format_angle(degrees, output_format, suffix)
end

return M
