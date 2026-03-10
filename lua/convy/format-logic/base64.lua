local M = {}
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function M.encode(text)
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

function M.decode(text)
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

return M
