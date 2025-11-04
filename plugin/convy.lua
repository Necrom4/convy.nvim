-- plugin/convy.lua
-- This file runs at startup for version check and command registration

if vim.fn.has("nvim-0.8.0") ~= 1 then
	vim.api.nvim_err_writeln("convy.nvim requires at least nvim-0.8.0.")
	return
end

-- Available types for completion
local types = { "dec", "hex", "bin", "oct", "ascii", "base64", "auto" }

-- Create the main :Convy command
vim.api.nvim_create_user_command("Convy", function(opts)
	local args = vim.split(opts.args, "%s+")
	local from_type = args[1]
	local to_type = args[2]

	-- If no arguments, open selection UI
	if not from_type or not to_type then
		require("convy").show_selector(opts.range > 0)
		return
	end

	require("convy").convert(from_type, to_type, opts.range > 0)
end, {
	nargs = "*",
	range = true,
	complete = function(arg_lead, cmd_line, cursor_pos)
		-- Parse command line to see which argument we're completing
		local args = vim.split(cmd_line, "%s+", { trimempty = true })
		local num_args = #args

		-- If typing :Convy <cursor>, we're on first arg
		-- If typing :Convy dec <cursor>, we're on second arg
		if cmd_line:sub(cursor_pos, cursor_pos) == " " then
			num_args = num_args + 1
		end

		-- Complete from the types list
		local matches = {}
		for _, type in ipairs(types) do
			if type:find(arg_lead, 1, true) == 1 then
				table.insert(matches, type)
			end
		end
		return matches
	end,
	desc = "Convert between different number/text formats",
})
