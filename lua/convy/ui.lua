local M = {}

local formats_mod = require("convy.formats")

-- Display width accounting for multi-byte UTF-8 chars
local function display_width(str)
	local width = 0
	local i = 1
	while i <= #str do
		local byte = string.byte(str, i)
		if byte < 0x80 then
			width = width + 1
			i = i + 1
		elseif byte < 0xC0 then
			i = i + 1
		elseif byte < 0xE0 then
			width = width + 1
			i = i + 2
		elseif byte < 0xF0 then
			width = width + 1
			i = i + 3
		else
			width = width + 1
			i = i + 4
		end
	end
	return width
end

local function pad_to_width(str, target_width)
	local current = display_width(str)
	local needed = target_width - current
	if needed > 0 then
		return str .. string.rep(" ", needed)
	end
	return str
end

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

	local config_w = require("convy").config.window

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = config_w.border,
		title = title,
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.wo[win].winblend = config_w.blend
	vim.wo[win].cursorline = false

	return buf, win
end

-- Show interactive selection window
local function build_columns()
	local columns = {}

	for _, group_key in ipairs(formats_mod.group_order) do
		local group = formats_mod.groups[group_key]
		table.insert(columns, {
			group_key = group_key,
			label = group.label,
			items = vim.deepcopy(group.formats),
		})
	end

	return columns
end

local function calc_column_widths(columns)
	local widths = {}

	for _, col in ipairs(columns) do
		local max_w = display_width(col.label)
		for _, item in ipairs(col.items) do
			local item_w = display_width(item) + 2
			if item_w > max_w then
				max_w = item_w
			end
		end
		table.insert(widths, max_w)
	end

	return widths
end

local function render_input_window(buf, columns, col_widths, cursor_on_auto, cursor_col, cursor_row, content_width)
	local col_gap = 2
	local left_pad = 2

	local lines = {}
	local highlights = {}

	table.insert(lines, "  Select INPUT format")
	table.insert(highlights, { line = 0, hl = "Title" })

	local auto_label = "AUTO"
	local prefix = cursor_on_auto and "▶ " or ""
	local auto_text = prefix .. auto_label
	local auto_display_w = display_width(auto_text)
	local auto_pad = math.max(0, math.floor((content_width - auto_display_w) / 2))
	local auto_line = string.rep(" ", left_pad + auto_pad) .. auto_text
	table.insert(lines, auto_line)
	do
		local line_idx = #lines - 1
		local start_byte = left_pad + auto_pad
		local end_byte = start_byte + #auto_text
		if cursor_on_auto then
			table.insert(highlights, { line = line_idx, hl = "Visual", col_start = start_byte, col_end = end_byte })
			table.insert(highlights, { line = line_idx, hl = "String", col_start = start_byte, col_end = end_byte })
		else
			table.insert(highlights, { line = line_idx, hl = "Identifier", col_start = start_byte, col_end = end_byte })
		end
	end
	table.insert(lines, "")

	local max_items = 0
	for _, col in ipairs(columns) do
		if #col.items > max_items then
			max_items = #col.items
		end
	end

	local total_rows = 2 + max_items

	for row_i = 1, total_rows do
		local line_parts = {}
		local byte_offset = left_pad

		table.insert(line_parts, string.rep(" ", left_pad))

		for ci, col in ipairs(columns) do
			local this_col_w = col_widths[ci]
			local cell = ""
			local cell_hl = nil

			if row_i == 1 then
				cell = col.label
				cell_hl = "Title"
			elseif row_i == 2 then
				local label_dw = display_width(col.label)
				cell = string.rep("─", label_dw)
				cell_hl = "Comment"
			else
				local item_idx = row_i - 2
				if item_idx <= #col.items then
					local item = col.items[item_idx]
					local is_selected = not cursor_on_auto and ci == cursor_col and item_idx == cursor_row
					if is_selected then
						cell = "▶ " .. item
						cell_hl = "String"
					else
						cell = "" .. item
						cell_hl = "Identifier"
					end
				end
			end

			local padded = pad_to_width(cell, this_col_w)
			table.insert(line_parts, padded)

			local line_idx = #lines
			if cell_hl and cell ~= "" then
				local cell_byte_start = byte_offset
				local cell_byte_end = byte_offset + #cell

				table.insert(highlights, {
					line = line_idx,
					hl = cell_hl,
					col_start = cell_byte_start,
					col_end = cell_byte_end,
				})

				if row_i > 2 then
					local item_idx = row_i - 2
					if not cursor_on_auto and ci == cursor_col and item_idx == cursor_row then
						table.insert(highlights, {
							line = line_idx,
							hl = "Visual",
							col_start = cell_byte_start,
							col_end = cell_byte_start + #padded,
						})
					end
				end
			end

			byte_offset = byte_offset + #padded

			if ci < #columns then
				table.insert(line_parts, string.rep(" ", col_gap))
				byte_offset = byte_offset + col_gap
			end
		end

		table.insert(lines, table.concat(line_parts))
	end

	table.insert(lines, "")
	table.insert(lines, "  [j/k] Up/Down  [h/l/Tab] Column  [Enter] Select  [Esc/q] Cancel")
	table.insert(highlights, { line = #lines - 1, hl = "Comment", col_start = 0, col_end = -1 })

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	for _, hl in ipairs(highlights) do
		local col_start = hl.col_start or 0
		local col_end = hl.col_end or -1
		vim.api.nvim_buf_add_highlight(buf, -1, hl.hl, hl.line, col_start, col_end)
	end
end

local function render_output_window(buf, output_formats, input_format, cursor_row)
	local lines = {}
	local highlights = {}

	table.insert(lines, "  Select OUTPUT format")
	table.insert(highlights, { line = 0, hl = "Title" })
	table.insert(lines, string.format("  (Input: %s)", input_format))
	table.insert(highlights, { line = 1, hl = "Comment" })
	table.insert(lines, "")

	for i, format in ipairs(output_formats) do
		local line
		if i == cursor_row then
			line = string.format(" ▶ %s", format)
			table.insert(highlights, { line = #lines, hl = "Visual", text_hl = "String" })
		else
			line = string.format("   %s", format)
			table.insert(highlights, { line = #lines, hl = "Normal", text_hl = "Identifier" })
		end
		table.insert(lines, line)
	end

	table.insert(lines, "")
	table.insert(lines, "  [Enter/l] Select  [BS/h] Back  [Esc/q] Cancel")
	table.insert(highlights, { line = #lines - 1, hl = "Comment" })

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	for _, hl in ipairs(highlights) do
		if hl.text_hl then
			local start_col = 3
			vim.api.nvim_buf_add_highlight(buf, -1, hl.text_hl, hl.line, start_col, -1)
		end
		if hl.hl and hl.hl ~= "Normal" then
			local col_start = hl.col_start or 0
			local col_end = hl.col_end or -1
			vim.api.nvim_buf_add_highlight(buf, -1, hl.hl, hl.line, col_start, col_end)
		end
	end
end

function M.show_format_selector(callback, source_text)
	local columns = build_columns()
	local col_widths = calc_column_widths(columns)
	local col_gap = 2
	local left_pad = 2
	local right_pad = 2

	local state = {
		step = 1,
		input_format = nil,
		output_formats = nil,
		col = 0,
		row = 1,
		cursor = 1,
	}

	local buf, win

	local content_width = 0
	for _, w in ipairs(col_widths) do
		content_width = content_width + w
	end
	content_width = content_width + (#columns - 1) * col_gap
	local total_width = left_pad + content_width + right_pad

	local max_items = 0
	for _, col in ipairs(columns) do
		if #col.items > max_items then
			max_items = #col.items
		end
	end
	local total_height = 3 + 1 + 1 + 2 + max_items + 1

	local function render()
		vim.bo[buf].modifiable = true

		if state.step == 1 then
			local on_auto = (state.col == 0)
			render_input_window(buf, columns, col_widths, on_auto, state.col, state.row, content_width)
		else
			render_output_window(buf, state.output_formats, state.input_format, state.cursor)
		end

		vim.bo[buf].modifiable = false
	end

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local function get_selected_format()
		if state.col == 0 then
			return "auto"
		end
		return columns[state.col].items[state.row]
	end

	local function select_format()
		if state.step == 1 then
			local selected_format = get_selected_format()
			state.input_format = selected_format

			if selected_format == "auto" then
				if source_text and source_text ~= "" then
					local utils = require("convy.utils")
					local detected = utils.detect_format(source_text)
					state.output_formats = formats_mod.get_compatible_outputs(detected)
				else
					state.output_formats = formats_mod.get_output_formats("auto")
				end
			else
				state.output_formats = formats_mod.get_compatible_outputs(selected_format)
			end

			if #state.output_formats == 0 then
				close()
				return
			end

			state.step = 2
			state.cursor = 1

			local new_height = #state.output_formats + 6
			local new_width = 50

			vim.api.nvim_win_set_config(win, {
				relative = "editor",
				width = new_width,
				height = new_height,
				col = math.floor((vim.o.columns - new_width) / 2),
				row = math.floor((vim.o.lines - new_height) / 2),
			})

			render()
		else
			local selected = state.output_formats[state.cursor]
			close()
			callback(state.input_format, selected)
		end
	end

	local function move_vertical(delta)
		if state.step == 1 then
			if state.col == 0 then
				if delta > 0 then
					state.col = 1
					state.row = 1
				else
					state.col = 1
					state.row = #columns[1].items
				end
			else
				local new_row = state.row + delta
				if new_row < 1 then
					state.col = 0
					state.row = 1
				elseif new_row > #columns[state.col].items then
					state.col = 0
					state.row = 1
				else
					state.row = new_row
				end
			end
		else
			state.cursor = state.cursor + delta
			if state.cursor < 1 then
				state.cursor = #state.output_formats
			elseif state.cursor > #state.output_formats then
				state.cursor = 1
			end
		end

		render()
	end

	local function move_horizontal(delta)
		if state.step ~= 1 then
			return
		end

		if state.col == 0 then
			if delta > 0 then
				state.col = 1
			else
				state.col = #columns
			end
			state.row = 1
		else
			local new_col = state.col + delta
			if new_col < 1 then
				new_col = #columns
			elseif new_col > #columns then
				new_col = 1
			end

			state.col = new_col

			if state.row > #columns[state.col].items then
				state.row = #columns[state.col].items
			end
		end

		render()
	end

	local function back_action()
		if state.step == 2 then
			state.step = 1
			state.input_format = nil

			vim.api.nvim_win_set_config(win, {
				relative = "editor",
				width = total_width,
				height = total_height,
				col = math.floor((vim.o.columns - total_width) / 2),
				row = math.floor((vim.o.lines - total_height) / 2),
			})

			render()
		end
	end

	local function setup_keymaps()
		local opts = { noremap = true, silent = true, buffer = buf }

		vim.keymap.set("n", "j", function()
			move_vertical(1)
		end, opts)
		vim.keymap.set("n", "k", function()
			move_vertical(-1)
		end, opts)
		vim.keymap.set("n", "<Down>", function()
			move_vertical(1)
		end, opts)
		vim.keymap.set("n", "<Up>", function()
			move_vertical(-1)
		end, opts)
		vim.keymap.set("n", "l", function()
			if state.step == 1 then
				move_horizontal(1)
			else
				select_format()
			end
		end, opts)
		vim.keymap.set("n", "h", function()
			if state.step == 1 then
				move_horizontal(-1)
			else
				back_action()
			end
		end, opts)
		vim.keymap.set("n", "<Left>", function()
			move_horizontal(-1)
		end, opts)
		vim.keymap.set("n", "<Right>", function()
			move_horizontal(1)
		end, opts)
		vim.keymap.set("n", "<Tab>", function()
			move_horizontal(1)
		end, opts)
		vim.keymap.set("n", "<S-Tab>", function()
			move_horizontal(-1)
		end, opts)
		vim.keymap.set("n", "<CR>", select_format, opts)
		vim.keymap.set("n", "<Esc>", close, opts)
		vim.keymap.set("n", "q", close, opts)
		vim.keymap.set("n", "<BS>", back_action, opts)
	end

	-- Create window and render
	buf, win = create_float_win(total_width, total_height, " Convy ")
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
