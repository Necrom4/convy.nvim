local M = {}

-- Letters a-z map to the standard 6-dot braille cells. Digits reuse the
-- a-j cells and are emitted after a number sign (⠼) when encoding.
local braille_chars = {
	["A"] = "⠁",
	["B"] = "⠃",
	["C"] = "⠉",
	["D"] = "⠙",
	["E"] = "⠑",
	["F"] = "⠋",
	["G"] = "⠛",
	["H"] = "⠓",
	["I"] = "⠊",
	["J"] = "⠚",
	["K"] = "⠅",
	["L"] = "⠇",
	["M"] = "⠍",
	["N"] = "⠝",
	["O"] = "⠕",
	["P"] = "⠏",
	["Q"] = "⠟",
	["R"] = "⠗",
	["S"] = "⠎",
	["T"] = "⠞",
	["U"] = "⠥",
	["V"] = "⠧",
	["W"] = "⠺",
	["X"] = "⠭",
	["Y"] = "⠽",
	["Z"] = "⠵",
	[" "] = " ",
}

local NUMBER_SIGN = "⠼"
local digit_to_letter = {
	["1"] = "A",
	["2"] = "B",
	["3"] = "C",
	["4"] = "D",
	["5"] = "E",
	["6"] = "F",
	["7"] = "G",
	["8"] = "H",
	["9"] = "I",
	["0"] = "J",
}

local letter_to_cell = {}
for k, v in pairs(braille_chars) do
	letter_to_cell[k] = v
end
for d, l in pairs(digit_to_letter) do
	letter_to_cell[d] = braille_chars[l]
end

local cell_to_letter = {}
for letter, cell in pairs(braille_chars) do
	cell_to_letter[cell] = letter
end

-- Iterate UTF-8 characters of a string (braille cells are 3 bytes each).
local function utf8_chars(str)
	return str:gmatch("[%z\1-\127\194-\244][\128-\191]*")
end

-- Decode braille cells -> text. After a number sign, a-j cells read as 1-0.
function M.to_text(braille)
	local out = {}
	local numeric = false
	for ch in utf8_chars(braille) do
		if ch == NUMBER_SIGN then
			numeric = true
		elseif ch == " " then
			numeric = false
			table.insert(out, " ")
		else
			local letter = cell_to_letter[ch]
			if not letter then
				table.insert(out, "?")
			elseif numeric and letter:match("[A-J]") then
				table.insert(out, tostring((letter:byte() - 65 + 1) % 10))
			else
				table.insert(out, letter:lower())
			end
		end
	end
	return table.concat(out)
end

-- Encode text -> braille cells, inserting a number sign before digit runs.
function M.from_text(text)
	local out = {}
	local in_number = false
	for i = 1, #text do
		local ch = text:sub(i, i):upper()
		if ch:match("%d") then
			if not in_number then
				out[#out + 1] = NUMBER_SIGN
				in_number = true
			end
			out[#out + 1] = letter_to_cell[ch]
		else
			in_number = false
			out[#out + 1] = letter_to_cell[ch] or "?"
		end
	end
	return table.concat(out)
end

return M
