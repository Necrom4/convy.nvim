local M = {}

local to_degrees = {
	deg = 1,
	rad = 180 / math.pi,
	grad = 0.9,
	turn = 360,
}

local function has_unit_suffix(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text
	return clean:match(input_format .. "$") ~= nil
end

local function parse_angle(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%-]?[%d%.]+)")
	if not num_str then
		error("Could not parse angle value from: " .. text)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str)
	end

	local factor = to_degrees[input_format]
	if not factor then
		error("Unknown angle format: " .. tostring(input_format))
	end

	return value * factor
end

-- Format a degrees value to the target angle format.
local function format_angle(degrees, output_format, include_suffix)
	local factor = to_degrees[output_format]
	if not factor then
		error("Unknown angle format: " .. tostring(output_format))
	end

	local value = degrees / factor

	local formatted
	if math.abs(value - math.floor(value + 0.5)) < 1e-9 then
		formatted = string.format("%d", math.floor(value + 0.5))
	else
		if output_format == "rad" or output_format == "turn" then
			formatted = string.format("%.6f", value)
		else
			formatted = string.format("%.2f", value)
		end
		formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
	end

	if include_suffix then
		formatted = formatted .. output_format
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local suffix = has_unit_suffix(text, input_format)
	local degrees = parse_angle(text, input_format)
	return format_angle(degrees, output_format, suffix)
end

return M
