local M = {}

local shared = require("convy.converters.shared")
local formats = require("convy.formats")

-- rem depends on the configured base font size.
local function factor_of(entry)
	if entry.dynamic == "rem" then
		local base = require("convy").config.css_base_font_size or 16
		return base * (0.0254 / 96)
	end
	return entry.factor
end

local function parse(text, entry, signed)
	local clean = text:match("^%s*(.-)%s*$") or text
	local pattern = signed and "^([%-]?[%d%.]+)" or "^([%d%.]+)"
	local num_str = clean:match(pattern)
	local value = num_str and tonumber(num_str)
	if not value then
		error("Could not parse value from: " .. text, 0)
	end
	return value * factor_of(entry)
end

function M.convert(text, input_format, output_format)
	local group = formats.get_group_def(input_format)
	local in_entry = formats.get_entry(input_format)
	local out_entry = formats.get_entry(output_format)

	local base = parse(text, in_entry, group.signed)
	local value = base / factor_of(out_entry)

	local decimals = out_entry.decimals or group.decimals or 2
	local formatted = shared.format_number(value, decimals)

	local _, suffix = shared.detect_suffix(text, in_entry.suffix)
	if suffix then
		formatted = formatted .. shared.apply_casing(out_entry.suffix, suffix)
	end

	return formatted
end

return M
