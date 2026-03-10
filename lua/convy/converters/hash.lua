-- file holds hash-related code for encoding.lua
local M = {}

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bnot = bit.bnot
local rsh = bit.rshift
local lsh = bit.lshift

------------
-- SHA256 --
------------

local function rrot(x, n)
	return bor(rsh(x, n), lsh(band(x, 0xFFFFFFFF), 32 - n))
end

local SHA256_K = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 }

function M.sha256(msg)
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

---------
-- MD5 --
---------

local MD5_K = {}
for i = 1, 64 do
	MD5_K[i] = math.floor(2 ^ 32 * math.abs(math.sin(i)))
end

local MD5_S = {
	7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
	5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
	4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
	6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
}

local function lrot(x, n)
	return bor(lsh(band(x, 0xFFFFFFFF), n), rsh(x, 32 - n))
end

function M.md5(msg)
	local len = #msg
	local blen = len * 8

	local pad = { string.byte(msg, 1, len) }
	pad[#pad + 1] = 0x80
	while (#pad % 64) ~= 56 do
		pad[#pad + 1] = 0
	end
	-- Length in bits as 64-bit little-endian
	pad[#pad + 1] = band(blen, 0xFF)
	pad[#pad + 1] = band(rsh(blen, 8), 0xFF)
	pad[#pad + 1] = band(rsh(blen, 16), 0xFF)
	pad[#pad + 1] = band(rsh(blen, 24), 0xFF)
	for _ = 1, 4 do
		pad[#pad + 1] = 0
	end

	local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

	for ci = 1, #pad, 64 do
		local w = {}
		for i = 0, 15 do
			local p = ci + i * 4
			w[i] = bor(pad[p], lsh(pad[p + 1], 8), lsh(pad[p + 2], 16), lsh(pad[p + 3], 24))
		end

		local a, b, c, d = a0, b0, c0, d0
		for i = 0, 63 do
			local f, g
			if i < 16 then
				f = bxor(d, band(b, bxor(c, d)))
				g = i
			elseif i < 32 then
				f = bxor(c, band(d, bxor(b, c)))
				g = (5 * i + 1) % 16
			elseif i < 48 then
				f = bxor(b, bxor(c, d))
				g = (3 * i + 5) % 16
			else
				f = bxor(c, bor(b, bnot(d)))
				g = (7 * i) % 16
			end

			f = band(f + a + MD5_K[i + 1] + w[g], 0xFFFFFFFF)
			a = d
			d = c
			c = b
			b = band(b + lrot(f, MD5_S[i + 1]), 0xFFFFFFFF)
		end

		a0 = band(a0 + a, 0xFFFFFFFF)
		b0 = band(b0 + b, 0xFFFFFFFF)
		c0 = band(c0 + c, 0xFFFFFFFF)
		d0 = band(d0 + d, 0xFFFFFFFF)
	end

	local function le(x)
		return string.format("%02x%02x%02x%02x", band(x, 0xFF), band(rsh(x, 8), 0xFF), band(rsh(x, 16), 0xFF), band(rsh(x, 24), 0xFF))
	end

	return le(a0) .. le(b0) .. le(c0) .. le(d0)
end

return M
