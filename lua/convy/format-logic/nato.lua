local M = {}

local nato_chars = {
	["A"] = "Alfa",
	["B"] = "Bravo",
	["C"] = "Charlie",
	["D"] = "Delta",
	["E"] = "Echo",
	["F"] = "Foxtrot",
	["G"] = "Golf",
	["H"] = "Hotel",
	["I"] = "India",
	["J"] = "Juliett",
	["K"] = "Kilo",
	["L"] = "Lima",
	["M"] = "Mike",
	["N"] = "November",
	["O"] = "Oscar",
	["P"] = "Papa",
	["Q"] = "Quebec",
	["R"] = "Romeo",
	["S"] = "Sierra",
	["T"] = "Tango",
	["U"] = "Uniform",
	["V"] = "Victor",
	["W"] = "Whiskey",
	["X"] = "Xray",
	["Y"] = "Yankee",
	["Z"] = "Zulu",
	["0"] = "Zero",
	["1"] = "One",
	["2"] = "Two",
	["3"] = "Three",
	["4"] = "Four",
	["5"] = "Five",
	["6"] = "Six",
	["7"] = "Seven",
	["8"] = "Eight",
	["9"] = "Nine",
}

local nato_chars_r = {}
for k, v in pairs(nato_chars) do
	nato_chars_r[v:upper()] = k
end

-- Decode "Hotel India" -> "HI". Word separators ("/") become spaces.
function M.to_text(nato)
	local parts = {}
	nato = nato:gsub("|", " / ")
	nato = nato:match("^%s*(.-)%s*$") or nato

	for token in nato:gmatch("%S+") do
		if token == "/" then
			table.insert(parts, " ")
		else
			table.insert(parts, nato_chars_r[token:upper()] or "?")
		end
	end

	return table.concat(parts)
end

-- Encode "HI" -> "Hotel India". Spaces between words become " / ".
function M.from_text(text)
	local out = {}
	for word in text:gmatch("%S+") do
		local letters = {}
		for i = 1, #word do
			local up = word:sub(i, i):upper()
			table.insert(letters, nato_chars[up] or "?")
		end
		table.insert(out, table.concat(letters, " "))
	end
	return table.concat(out, " / ")
end

return M
