local M = {}

local to_meters = {
	px = 0.0254 / 96,
	pt = 0.0254 / 72,
	rem = nil,
	mm = 0.001,
	cm = 0.01,
	m = 1,
	km = 1000,
	["in"] = 0.0254,
	ft = 0.3048,
	yd = 0.9144,
	mi = 1609.344,
}

local function get_rem_factor()
	local config = require("convy").config
	local base = config.css_base_font_size or 16
	return base * (0.0254 / 96)
end

local function has_unit_suffix(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text
	return clean:match(input_format .. "$") ~= nil
end

local function parse_length(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%-]?[%d%.]+)")
	if not num_str then
		error("Could not parse length value from: " .. text)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str)
	end

	local factor
	if input_format == "rem" then
		factor = get_rem_factor()
	else
		factor = to_meters[input_format]
	end

	if not factor then
		error("Unknown length format: " .. tostring(input_format))
	end

	return value * factor
end

local function format_length(meters, output_format, include_suffix)
	local factor
	if output_format == "rem" then
		factor = get_rem_factor()
	else
		factor = to_meters[output_format]
	end

	if not factor then
		error("Unknown length format: " .. tostring(output_format))
	end

	local value = meters / factor

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
	local meters = parse_length(text, input_format)
	return format_length(meters, output_format, suffix)
end

return M
