if vim.fn.has("nvim-0.8.0") ~= 1 then
	vim.api.nvim_err_writeln("convy.nvim requires at least nvim-0.8.0.")
	return
end

vim.api.nvim_create_user_command("Convy", function(opts)
	local args = vim.split(opts.args, "%s+")
	local input_format = args[1]
	local output_format = args[2]

	if not input_format or input_format == "" then
		require("convy").show_selector(opts.range > 0)
		return
	end

	if not output_format or output_format == "" then
		require("convy").show_selector(opts.range > 0)
		return
	end

	require("convy").convert(input_format, output_format, opts.range > 0)
end, {
	nargs = "*",
	range = true,
	complete = function(arg_lead, cmd_line, cursor_pos)
		-- Parse command line to see which argument we're completing
		local formats_mod = require("convy.formats")

		local args = vim.split(cmd_line, "%s+", { trimempty = true })
		local num_args = #args

		-- If typing `:Convy <cursor>`, we're on first arg
		-- If typing `:Convy dec <cursor>`, we're on second arg
		if cmd_line:sub(cursor_pos, cursor_pos) == " " then
			num_args = num_args + 1
		end

		-- Complete from the formats list
		local completions = {}

		if num_args <= 2 then
			completions = formats_mod.get_all_input_formats()
		else
			local input_format = args[2]
			if input_format == "auto" then
				completions = formats_mod.get_output_formats("auto")
			else
				completions = formats_mod.get_output_formats(input_format)
			end
		end

		local matches = {}
		for _, fmt in ipairs(completions) do
			if fmt:find(arg_lead, 1, true) == 1 then
				table.insert(matches, fmt)
			end
		end
		return matches
	end,
	desc = "Convert format",
})

vim.api.nvim_create_user_command("ConvySeparator", function(opts)
	local set_separator = require("convy.utils").set_separator

	local function clean_input(str)
		str = vim.trim(str or "")

		if (str:sub(1, 1) == '"' and str:sub(-1) == '"') or (str:sub(1, 1) == "'" and str:sub(-1) == "'") then
			str = str:sub(2, -2)
		end

		str = str:gsub('\\"', '"')
		str = str:gsub("\\'", "'")

		return str
	end

	if not opts.args then
		set_separator(" ")
		return
	elseif opts.range > 0 then
		local text = require("convy.utils").get_visual_selection()
		set_separator(text)
		return
	end

	set_separator(clean_input(opts.args))
end, {
	nargs = "*",
	range = true,
	desc = "Change convertion separator",
})
