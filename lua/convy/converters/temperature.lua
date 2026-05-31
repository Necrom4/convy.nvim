local M = {}

local shared = require("convy.converters.shared")

local suffix_letters = {
	celsius = "C",
	fahrenheit = "F",
	kelvin = "K",
}

local function detect_suffix_style(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text
	local letter = suffix_letters[input_format]

	local present, matched = shared.detect_suffix(clean, letter)
	if not present then
		return "none", nil
	end

	-- A degree symbol (°) is two bytes in UTF-8; check the bytes preceding
	-- the matched letter to distinguish "°C" from a bare "C".
	if clean:sub(-(#letter + #"°"), -(#letter + 1)) == "°" then
		return "degree", matched
	end

	return "letter", matched
end

local function parse_temperature(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text

	local num_str = clean:match("^([%-]?[%d%.]+)")
	if not num_str then
		error("Could not parse temperature value from: " .. text, 0)
	end

	local value = tonumber(num_str)
	if not value then
		error("Invalid numeric value: " .. num_str, 0)
	end

	if input_format == "celsius" then
		return value
	elseif input_format == "fahrenheit" then
		return (value - 32) * 5 / 9
	elseif input_format == "kelvin" then
		return value - 273.15
	else
		error("Unknown temperature format: " .. tostring(input_format), 0)
	end
end

local function format_temperature(celsius, output_format, suffix_style, source_letter)
	local value

	if output_format == "celsius" then
		value = celsius
	elseif output_format == "fahrenheit" then
		value = celsius * 9 / 5 + 32
	elseif output_format == "kelvin" then
		value = celsius + 273.15
	else
		error("Unknown temperature format: " .. tostring(output_format), 0)
	end

	local formatted = shared.format_number(value)

	local letter = shared.apply_casing(suffix_letters[output_format], source_letter)

	if suffix_style == "degree" then
		formatted = formatted .. "°" .. letter
	elseif suffix_style == "letter" then
		formatted = formatted .. letter
	end

	return formatted
end

function M.convert(text, input_format, output_format)
	local suffix_style, source_letter = detect_suffix_style(text, input_format)
	local celsius = parse_temperature(text, input_format)
	return format_temperature(celsius, output_format, suffix_style, source_letter)
end

return M
