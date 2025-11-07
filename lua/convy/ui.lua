local M = {}

local function create_float_win(width, height, title)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "convy"

	-- Calculate window position (centered)
	local ui = vim.api.nvim_list_uis()[1]
	local win_width = ui.width
	local win_height = ui.height

	local col = math.floor((win_width - width) / 2)
	local row = math.floor((win_height - height) / 2)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Set window options
	vim.wo[win].winblend = 0
	vim.wo[win].cursorline = false

	return buf, win
end

-- Show interactive selection window
function M.show_format_selector(input_formats, callback, get_output_formats_fn)
	local width = 50

	local state = {
		step = 1, -- 1 = select input_format, 2 = select output_format
		input_format = nil,
		output_format = nil,
		cursor = 1,
		current_formats = input_formats,
	}

	local buf, win

	local height = #input_formats + 5

	local function render()
		local lines = {}
		local highlights = {}

		if state.step == 1 then
			table.insert(lines, "")
			table.insert(lines, "  Select INPUT format:")
			table.insert(highlights, { line = 1, hl = "Title" })
			table.insert(lines, "")
		else
			table.insert(lines, "")
			table.insert(lines, "  Select OUTPUT format:")
			table.insert(highlights, { line = 1, hl = "Title" })
			table.insert(lines, string.format("  (Input: %s)", state.input_format))
			table.insert(highlights, { line = 2, hl = "Comment" })
			table.insert(lines, "")
		end

		for i, format in ipairs(state.current_formats) do
			local line
			if i == state.cursor then
				line = string.format(" ▶ %s", format)
				table.insert(highlights, { line = #lines, hl = "Visual", text_hl = "String" })
			else
				line = string.format("   %s", format)
				table.insert(highlights, { line = #lines, hl = "Normal", text_hl = "Identifier" })
			end
			table.insert(lines, line)
		end

		table.insert(lines, "")
		if state.step == 1 then
			table.insert(lines, "  [Enter] Select  [Esc/q] Cancel")
		else
			table.insert(lines, "  [Enter] Select  [BS] Back  [Esc/q] Cancel")
		end
		table.insert(highlights, { line = #lines - 1, hl = "Comment" })

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

		-- Apply highlights
		for _, hl in ipairs(highlights) do
			if hl.text_hl then
				local start_col = 3
				vim.api.nvim_buf_add_highlight(buf, -1, hl.text_hl, hl.line, start_col, -1)
			end
			if hl.hl and hl.hl ~= "Normal" then
				vim.api.nvim_buf_add_highlight(buf, -1, hl.hl, hl.line, 0, -1)
			end
		end

		vim.bo[buf].modifiable = false
	end

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local function select_format()
		local selected = state.current_formats[state.cursor]

		if state.step == 1 then
			state.input_format = selected
			state.step = 2
			state.cursor = 1

			state.current_formats = get_output_formats_fn()

			-- Resize window for new list
			local new_height = #state.current_formats + 6
			vim.api.nvim_win_set_config(win, {
				relative = "editor",
				width = width,
				height = new_height,
				col = math.floor((vim.o.columns - width) / 2),
				row = math.floor((vim.o.lines - new_height) / 2),
			})

			vim.bo[buf].modifiable = true
			render()
		else
			state.output_format = selected
			close()
			callback(state.input_format, state.output_format)
		end
	end

	local function move_cursor(delta)
		state.cursor = state.cursor + delta
		if state.cursor < 1 then
			state.cursor = #state.current_formats
		elseif state.cursor > #state.current_formats then
			state.cursor = 1
		end

		vim.bo[buf].modifiable = true
		render()
	end

	local function setup_keymaps()
		local opts = { noremap = true, silent = true, buffer = buf }

		vim.keymap.set("n", "j", function()
			move_cursor(1)
		end, opts)
		vim.keymap.set("n", "k", function()
			move_cursor(-1)
		end, opts)
		vim.keymap.set("n", "<Down>", function()
			move_cursor(1)
		end, opts)
		vim.keymap.set("n", "<Up>", function()
			move_cursor(-1)
		end, opts)
		vim.keymap.set("n", "<CR>", select_format, opts)
		vim.keymap.set("n", "<Space>", select_format, opts)
		vim.keymap.set("n", "<Esc>", close, opts)
		vim.keymap.set("n", "q", close, opts)

		-- Go back (only on step 2)
		vim.keymap.set("n", "<BS>", function()
			if state.step == 2 then
				state.step = 1
				state.cursor = 1
				state.current_formats = input_formats

				-- Resize window back
				local new_height = #input_formats + 5
				vim.api.nvim_win_set_config(win, {
					relative = "editor",
					width = width,
					height = new_height,
					col = math.floor((vim.o.columns - width) / 2),
					row = math.floor((vim.o.lines - new_height) / 2),
				})

				vim.bo[buf].modifiable = true
				render()
			end
		end, opts)
	end

	-- Create window and render
	buf, win = create_float_win(width, height, " Convy - Type Selector ")
	render()
	setup_keymaps()

	-- Auto-close on leaving window
	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		buffer = buf,
		once = true,
		callback = close,
	})
end

return M
