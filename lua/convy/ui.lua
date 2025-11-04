-- lua/convy/ui.lua
-- UI components for interactive type selection

local M = {}

-- Create a centered floating window
local function create_float_win(width, height, title)
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "convy")

	-- Calculate window position (centered)
	local ui = vim.api.nvim_list_uis()[1]
	local win_width = ui.width
	local win_height = ui.height

	local col = math.floor((win_width - width) / 2)
	local row = math.floor((win_height - height) / 2)

	-- Window options
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
	vim.api.nvim_win_set_option(win, "winblend", 0)
	vim.api.nvim_win_set_option(win, "cursorline", true)

	return buf, win
end

-- Show type selector UI
function M.show_type_selector(types, callback)
	local width = 50
	local height = #types + 4

	-- State
	local state = {
		step = 1, -- 1 = select from_type, 2 = select to_type
		from_type = nil,
		to_type = nil,
		cursor = 1,
	}

	local buf, win

	local function render()
		local lines = {}
		local highlights = {}

		if state.step == 1 then
			table.insert(lines, "  Select INPUT type:")
			table.insert(lines, "")
		else
			table.insert(lines, "  Select OUTPUT type:")
			table.insert(lines, string.format("  (Input: %s)", state.from_type))
			table.insert(lines, "")
		end

		for i, type in ipairs(types) do
			local line
			if i == state.cursor then
				line = string.format("▶ %s", type)
				table.insert(highlights, { line = #lines, hl = "CursorLine" })
			else
				line = string.format("  %s", type)
			end
			table.insert(lines, line)
		end

		table.insert(lines, "")
		table.insert(lines, "  [Enter] Select  [Esc/q] Cancel")

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

		-- Apply highlights
		for _, hl in ipairs(highlights) do
			vim.api.nvim_buf_add_highlight(buf, -1, hl.hl, hl.line, 0, -1)
		end

		-- Make buffer unmodifiable
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
	end

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local function select_type()
		local selected = types[state.cursor]

		if state.step == 1 then
			state.from_type = selected
			state.step = 2
			state.cursor = 1

			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			render()
		else
			state.to_type = selected
			close()
			callback(state.from_type, state.to_type)
		end
	end

	local function move_cursor(delta)
		state.cursor = state.cursor + delta
		if state.cursor < 1 then
			state.cursor = #types
		elseif state.cursor > #types then
			state.cursor = 1
		end

		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		render()
	end

	local function setup_keymaps()
		local opts = { noremap = true, silent = true, buffer = buf }

		-- Navigation
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

		-- Selection
		vim.keymap.set("n", "<CR>", select_type, opts)
		vim.keymap.set("n", "<Space>", select_type, opts)

		-- Cancel
		vim.keymap.set("n", "<Esc>", close, opts)
		vim.keymap.set("n", "q", close, opts)

		-- Go back (only on step 2)
		vim.keymap.set("n", "<BS>", function()
			if state.step == 2 then
				state.step = 1
				state.cursor = 1
				vim.api.nvim_buf_set_option(buf, "modifiable", true)
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
