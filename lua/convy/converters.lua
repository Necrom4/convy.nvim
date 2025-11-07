local M = {}

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function encode_base64(text)
	local result = ""

	for i = 1, #text, 3 do
		local b1, b2, b3 = text:byte(i), text:byte(i + 1), text:byte(i + 2)
		local n = b1 * 65536 + (b2 or 0) * 256 + (b3 or 0)

		local c1 = math.floor(n / 262144) % 64
		local c2 = math.floor(n / 4096) % 64
		local c3 = math.floor(n / 64) % 64
		local c4 = n % 64

		result = result .. b64chars:sub(c1 + 1, c1 + 1) .. b64chars:sub(c2 + 1, c2 + 1)

		if b2 then
			result = result .. b64chars:sub(c3 + 1, c3 + 1)
		else
			result = result .. "="
		end

		if b3 then
			result = result .. b64chars:sub(c4 + 1, c4 + 1)
		else
			result = result .. "="
		end
	end

	return result
end

local function decode_base64(text)
	-- Remove whitespace
	text = text:gsub("%s", "")

	-- Build reverse lookup table
	local b64lookup = {}
	for i = 1, #b64chars do
		b64lookup[b64chars:sub(i, i)] = i - 1
	end

	local result = ""

	for i = 1, #text, 4 do
		local c1 = b64lookup[text:sub(i, i)] or 0
		local c2 = b64lookup[text:sub(i + 1, i + 1)] or 0
		local c3 = b64lookup[text:sub(i + 2, i + 2)] or 0
		local c4 = b64lookup[text:sub(i + 3, i + 3)] or 0

		local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4

		local b1 = math.floor(n / 65536) % 256
		result = result .. string.char(b1)

		if text:sub(i + 2, i + 2) ~= "=" then
			local b2 = math.floor(n / 256) % 256
			result = result .. string.char(b2)
		end

		if text:sub(i + 3, i + 3) ~= "=" then
			local b3 = n % 256
			result = result .. string.char(b3)
		end
	end

	return result
end

local function parse_input(text, input_format)
	local numbers = {}

	if input_format == "ascii" then
		for i = 1, #text do
			table.insert(numbers, text:byte(i))
		end
	elseif input_format == "bin" then
		for num in text:gmatch("0?b?([01]+)") do
			table.insert(numbers, tonumber(num, 2))
		end
	elseif input_format == "base64" then
		local decoded = decode_base64(text)
		for i = 1, #decoded do
			table.insert(numbers, decoded:byte(i))
		end
	elseif input_format == "dec" then
		for num in text:gmatch("[0-9]+") do
			table.insert(numbers, tonumber(num))
		end
	elseif input_format == "hex" then
		for num in text:gmatch("0?x?([0-9a-fA-F]+)") do
			table.insert(numbers, tonumber(num, 16))
		end
	elseif input_format == "oct" then
		for num in text:gmatch("0?o?([0-7]+)") do
			table.insert(numbers, tonumber(num, 8))
		end
	else
		error("Unknown input format: " .. input_format)
	end

	return numbers
end

local function format_output(numbers, output_format)
	local results = {}

	if output_format == "ascii" then
		for _, num in ipairs(numbers) do
			if num >= 0 and num <= 127 then
				table.insert(results, string.char(num))
			else
				table.insert(results, "?")
			end
		end
		return table.concat(results)
	elseif output_format == "base64" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return encode_base64(text)
	elseif output_format == "bin" then
		for _, num in ipairs(numbers) do
			local bin = ""
			local n = num
			if n == 0 then
				bin = "0"
			else
				while n > 0 do
					bin = tostring(n % 2) .. bin
					n = math.floor(n / 2)
				end
			end
			table.insert(results, "0b" .. bin)
		end
		return table.concat(results, " ")
	elseif output_format == "dec" then
		for _, num in ipairs(numbers) do
			table.insert(results, tostring(num))
		end
		return table.concat(results, " ")
	elseif output_format == "hex" then
		for _, num in ipairs(numbers) do
			table.insert(results, string.format("0x%x", num))
		end
		return table.concat(results, " ")
	elseif output_format == "oct" then
		for _, num in ipairs(numbers) do
			table.insert(results, string.format("0o%o", num))
		end
		return table.concat(results, " ")
	else
		error("Unknown output format: " .. output_format)
	end
end

function M.convert(text, input_format, output_format)
	local numbers = parse_input(text, input_format)

	if #numbers == 0 then
		error("No valid numbers found in input")
	end

	return format_output(numbers, output_format)
end

return M
