-- plugin/convy.lua
-- This file runs at startup for version check and command registration

if vim.fn.has("nvim-0.8.0") ~= 1 then
	vim.api.nvim_err_writeln("convy.nvim requires at least nvim-0.8.0.")
	return
end

-- Create the main :Convy command
vim.api.nvim_create_user_command("Convy", function(opts)
	local args = vim.split(opts.args, "%s+")
	local from_type = args[1]
	local to_type = args[2]

	if not from_type or not to_type then
		-- If no arguments, show available types (future: open selection UI)
		vim.notify(
			"Usage: :Convy <from_type> <to_type>\nAvailable types: dec, hex, bin, oct, ascii, base64",
			vim.log.levels.INFO
		)
		return
	end

	require("convy").convert(from_type, to_type, opts.range > 0)
end, {
	nargs = "*",
	range = true,
	desc = "Convert between different number/text formats",
})

-- Create convenience commands for common conversions
vim.api.nvim_create_user_command("ConvyToHex", function(opts)
	require("convy").convert("auto", "hex", opts.range > 0)
end, { range = true, desc = "Convert to hexadecimal" })

vim.api.nvim_create_user_command("ConvyToDec", function(opts)
	require("convy").convert("auto", "dec", opts.range > 0)
end, { range = true, desc = "Convert to decimal" })

vim.api.nvim_create_user_command("ConvyToBin", function(opts)
	require("convy").convert("auto", "bin", opts.range > 0)
end, { range = true, desc = "Convert to binary" })

vim.api.nvim_create_user_command("ConvyToAscii", function(opts)
	require("convy").convert("auto", "ascii", opts.range > 0)
end, { range = true, desc = "Convert to ASCII" })
