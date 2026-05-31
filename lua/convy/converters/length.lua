local M = {}

local shared = require("convy.converters.shared")

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

local function parse_length(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%-]?[%d%.]+)")
	if not num_str then
		error("Could not parse length value from: " .. text, 0)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str, 0)
	end

	local factor
	if input_format == "rem" then
		factor = get_rem_factor()
	else
		factor = to_meters[input_format]
	end

	if not factor then
		error("Unknown length format: " .. tostring(input_format), 0)
	end

	return value * factor
end

local function format_length(meters, output_format, suffix)
	local factor
	if output_format == "rem" then
		factor = get_rem_factor()
	else
		factor = to_meters[output_format]
	end

	if not factor then
		error("Unknown length format: " .. tostring(output_format), 0)
	end

	local value = meters / factor

	local formatted = shared.format_number(value, 4)

	if suffix then
		formatted = formatted .. shared.apply_casing(output_format, suffix)
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local _, suffix = shared.detect_suffix(text, input_format)
	local meters = parse_length(text, input_format)
	return format_length(meters, output_format, suffix)
end

return M
