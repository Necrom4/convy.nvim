local M = {}

local shared = require("convy.converters.shared")
local formats = require("convy.formats")

local function to_celsius(value, name)
	if name == "celsius" then
		return value
	elseif name == "fahrenheit" then
		return (value - 32) * 5 / 9
	else
		return value - 273.15
	end
end

local function from_celsius(celsius, name)
	if name == "celsius" then
		return celsius
	elseif name == "fahrenheit" then
		return celsius * 9 / 5 + 32
	else
		return celsius + 273.15
	end
end

-- Returns "degree" | "letter" | "none" and the matched (original-cased) letter.
local function suffix_style(text, letter)
	local clean = text:match("^%s*(.-)%s*$") or text
	local present, matched = shared.detect_suffix(clean, letter)
	if not present then
		return "none", nil
	end
	if clean:sub(-(#letter + #"°"), -(#letter + 1)) == "°" then
		return "degree", matched
	end
	return "letter", matched
end

function M.convert(text, input_format, output_format)
	local in_entry = formats.get_entry(input_format)
	local out_entry = formats.get_entry(output_format)

	local style, matched = suffix_style(text, in_entry.letter)

	local num_str = (text:match("^%s*(.-)%s*$") or text):match("^([%-]?[%d%.]+)")
	local value = num_str and tonumber(num_str)
	if not value then
		error("Could not parse temperature value from: " .. text, 0)
	end

	local result = from_celsius(to_celsius(value, input_format), output_format)
	local formatted = shared.format_number(result)

	local letter = shared.apply_casing(out_entry.letter, matched)
	if style == "degree" then
		formatted = formatted .. "°" .. letter
	elseif style == "letter" then
		formatted = formatted .. letter
	end

	return formatted
end

return M
