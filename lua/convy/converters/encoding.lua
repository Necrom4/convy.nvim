local M = {}

------------
-- BASE64 --
------------

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function encode_b64(text)
	local result = ""

	for i = 1, #text, 3 do
		local b1, b2, b3 = text:byte(i), text:byte(i + 1), text:byte(i + 2)
		local n = (b1 or 0) * 65536 + (b2 or 0) * 256 + (b3 or 0)

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

local function decode_b64(text)
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

-----------
-- MORSE --
-----------

local morse_chars = {
	["A"] = ".-",
	["B"] = "-...",
	["C"] = "-.-.",
	["D"] = "-..",
	["E"] = ".",
	["F"] = "..-.",
	["G"] = "--.",
	["H"] = "....",
	["I"] = "..",
	["J"] = ".---",
	["K"] = "-.-",
	["L"] = ".-..",
	["M"] = "--",
	["N"] = "-.",
	["O"] = "---",
	["P"] = ".--.",
	["Q"] = "--.-",
	["R"] = ".-.",
	["S"] = "...",
	["T"] = "-",
	["U"] = "..-",
	["V"] = "...-",
	["W"] = ".--",
	["X"] = "-..-",
	["Y"] = "-.--",
	["Z"] = "--..",
	["0"] = "-----",
	["1"] = ".----",
	["2"] = "..---",
	["3"] = "...--",
	["4"] = "....-",
	["5"] = ".....",
	["6"] = "-....",
	["7"] = "--...",
	["8"] = "---..",
	["9"] = "----.",
	["."] = ".-.-.-",
	[","] = "--..--",
	["?"] = "..--..",
	["'"] = ".----.",
	["!"] = "-.-.--",
	["/"] = "-..-.",
	["("] = "-.--.",
	[")"] = "-.--.-",
	["&"] = ".-...",
	[":"] = "---...",
	[";"] = "-.-.-.",
	["="] = "-...-",
	["+"] = ".-.-.",
	["-"] = "-....-",
	["_"] = "..--.-",
	['"'] = ".-..-.",
	["$"] = "...-..-",
	["@"] = ".--.-.",
}

local morse_chars_r = {}
for k, v in pairs(morse_chars) do
	morse_chars_r[v] = k
end

local function morse_to_text(morse)
	local parts = {}
	morse = morse:gsub("|", " / ")
	morse = morse:match("^%s*(.-)%s*$") or morse

	for token in morse:gmatch("%S+") do
		if token == "/" then
			table.insert(parts, " ")
		else
			local ch = morse_chars_r[token]
			if ch then
				table.insert(parts, ch)
			else
				table.insert(parts, "?")
			end
		end
	end

	return table.concat(parts)
end

local function text_to_morse(text)
	local out = {}
	for word in text:gmatch("%S+") do
		local letters = {}
		for i = 1, #word do
			local ch = word:sub(i, i)
			local up = ch:upper()
			local m = morse_chars[up]
			if m then
				table.insert(letters, m)
			else
				table.insert(letters, "?")
			end
		end
		table.insert(out, table.concat(letters, " "))
	end
	return table.concat(out, " / ")
end

----------
-- HASH --
----------

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bnot = bit.bnot
local rsh = bit.rshift
local lsh = bit.lshift

local function rrot(x, n)
	return bor(rsh(x, n), lsh(band(x, 0xFFFFFFFF), 32 - n))
end

local SHA256_K = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 }

local function encode_sha256(msg)
	local len = #msg
	local blen = len * 8

	local pad = { string.byte(msg, 1, len) }
	pad[#pad + 1] = 0x80
	while (#pad % 64) ~= 56 do
		pad[#pad + 1] = 0
	end
	for _ = 1, 4 do
		pad[#pad + 1] = 0
	end
	pad[#pad + 1] = band(rsh(blen, 24), 0xFF)
	pad[#pad + 1] = band(rsh(blen, 16), 0xFF)
	pad[#pad + 1] = band(rsh(blen, 8), 0xFF)
	pad[#pad + 1] = band(blen, 0xFF)

	local h0, h1, h2, h3 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
	local h4, h5, h6, h7 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

	for ci = 1, #pad, 64 do
		local w = {}
		for i = 0, 15 do
			local p = ci + i * 4
			w[i] = bor(lsh(pad[p], 24), lsh(pad[p + 1], 16), lsh(pad[p + 2], 8), pad[p + 3])
		end
		for i = 16, 63 do
			local s0 = bxor(rrot(w[i - 15], 7), rrot(w[i - 15], 18), rsh(w[i - 15], 3))
			local s1 = bxor(rrot(w[i - 2], 17), rrot(w[i - 2], 19), rsh(w[i - 2], 10))
			w[i] = band(w[i - 16] + s0 + w[i - 7] + s1, 0xFFFFFFFF)
		end

		local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
		for i = 0, 63 do
			local S1 = bxor(rrot(e, 6), rrot(e, 11), rrot(e, 25))
			local ch = bxor(band(e, f), band(bnot(e), g))
			local t1 = band(h + S1 + ch + SHA256_K[i + 1] + w[i], 0xFFFFFFFF)
			local S0 = bxor(rrot(a, 2), rrot(a, 13), rrot(a, 22))
			local maj = bxor(band(a, b), band(a, c), band(b, c))
			local t2 = band(S0 + maj, 0xFFFFFFFF)
			h, g, f, e = g, f, e, band(d + t1, 0xFFFFFFFF)
			d, c, b, a = c, b, a, band(t1 + t2, 0xFFFFFFFF)
		end

		h0 = band(h0 + a, 0xFFFFFFFF)
		h1 = band(h1 + b, 0xFFFFFFFF)
		h2 = band(h2 + c, 0xFFFFFFFF)
		h3 = band(h3 + d, 0xFFFFFFFF)
		h4 = band(h4 + e, 0xFFFFFFFF)
		h5 = band(h5 + f, 0xFFFFFFFF)
		h6 = band(h6 + g, 0xFFFFFFFF)
		h7 = band(h7 + h, 0xFFFFFFFF)
	end

	return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
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
		local decoded = decode_b64(text)
		for i = 1, #decoded do
			table.insert(numbers, decoded:byte(i))
		end
	elseif input_format == "sha256" then
		error("can't decode hash formats", 0)
	elseif input_format == "morse" then
		local decoded_text = morse_to_text(text)
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
		return encode_b64(text)
	elseif output_format == "sha256" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return encode_sha256(text)
	elseif output_format == "morse" then
		local text = ""
		for _, num in ipairs(numbers) do
			text = text .. string.char(num)
		end
		return text_to_morse(text)
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
