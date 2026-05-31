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

return M
