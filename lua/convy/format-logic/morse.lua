local M = {}

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

function M.to_text(morse)
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

function M.from_text(text)
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

return M
