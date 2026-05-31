local M = {}

function M.format_number(value, decimals)
	decimals = decimals or 2

	if math.abs(value - math.floor(value + 0.5)) < 1e-9 then
		return string.format("%d", math.floor(value + 0.5))
	end

	local formatted = string.format("%." .. decimals .. "f", value)
	formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
	return formatted
end

function M.detect_suffix(text, input_format)
	local clean = text:match("^%s*(.-)%s*$") or text
	local len = #input_format
	local tail = clean:sub(-len)

	if tail:lower() == input_format:lower() then
		return true, tail
	end

	return false, nil
end

return M
