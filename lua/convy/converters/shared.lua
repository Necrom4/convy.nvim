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

function M.apply_casing(canonical, source)
	if not source or #source ~= #canonical then
		return canonical
	end

	local result = {}
	for i = 1, #canonical do
		local src_char = source:sub(i, i)
		local out_char = canonical:sub(i, i)
		if src_char:match("%l") then
			out_char = out_char:lower()
		elseif src_char:match("%u") then
			out_char = out_char:upper()
		end
		result[i] = out_char
	end

	return table.concat(result)
end

return M
