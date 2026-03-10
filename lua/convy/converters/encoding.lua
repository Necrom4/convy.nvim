local M = {}
local base64 = require("convy.format-logic.base64")
local hash = require("convy.format-logic.hash")
local morse = require("convy.format-logic.morse")

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
	elseif input_format == "b64" then
		local decoded = base64.decode(text)
		for i = 1, #decoded do
			table.insert(numbers, decoded:byte(i))
		end
	elseif input_format == "sha256" or input_format == "md5" then
		error("can't decode hash formats", 0)
	elseif input_format == "morse" then
		local decoded_text = morse.to_text(text)
		for i = 1, #decoded_text do
			table.insert(numbers, decoded_text:byte(i))
		end
	else
		error("Unknown input format: " .. tostring(input_format), 0)
	end

	return numbers
end

local function format_output(numbers, output_format)
	local config = require("convy").config
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
		return table.concat(results, config.separator)
	elseif output_format == "dec" then
		for _, num in ipairs(numbers) do
			table.insert(results, tostring(num))
		end
		return table.concat(results, config.separator)
	elseif output_format == "hex" then
		for _, num in ipairs(numbers) do
			table.insert(results, string.format("0x%x", num))
		end
		return table.concat(results, config.separator)
	elseif output_format == "oct" then
		for _, num in ipairs(numbers) do
			table.insert(results, string.format("0o%o", num))
		end
		return table.concat(results, config.separator)
	elseif output_format == "b64" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return base64.encode(text)
	elseif output_format == "sha256" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return hash.sha256(text)
	elseif output_format == "md5" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return hash.md5(text)
	elseif output_format == "morse" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return morse.from_text(text)
	else
		error("Unknown output format: " .. tostring(output_format), 0)
	end
end

function M.convert(text, input_format, output_format)
	local numbers = parse_input(text, input_format)

	if #numbers == 0 then
		error("No valid numbers found in input", 0)
	end

	return format_output(numbers, output_format)
end

return M
