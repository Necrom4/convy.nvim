local M = {}

-- Single source of truth. Groups are ordered; each format entry carries
-- everything about itself: canonical `name`, optional `display` override,
-- and (for unit groups) the conversion `factor` relative to the group base,
-- plus parse/format hints (`signed`, `decimals`, `dynamic`).
M.groups = {
	{
		key = "encoding",
		label = "Encoding",
		kind = "encoding",
		formats = {
			{ name = "ascii" },
			{ name = "bin" },
			{ name = "dec" },
			{ name = "hex" },
			{ name = "oct" },
			{ name = "b64" },
			{ name = "sha256" },
			{ name = "md5" },
			{ name = "morse" },
			{ name = "braille" },
			{ name = "nato" },
		},
	},
	{
		key = "datasize",
		label = "Data Size",
		kind = "linear",
		formats = {
			{ name = "b", display = "B", suffix = "b", factor = 1 },
			-- SI decimal (powers of 1000)
			{ name = "kb", display = "KB", suffix = "kb", factor = 1000 },
			{ name = "mb", display = "MB", suffix = "mb", factor = 1000 ^ 2 },
			{ name = "gb", display = "GB", suffix = "gb", factor = 1000 ^ 3 },
			{ name = "tb", display = "TB", suffix = "tb", factor = 1000 ^ 4 },
			-- IEC binary (powers of 1024)
			{ name = "kib", display = "KiB", suffix = "kib", factor = 1024 },
			{ name = "mib", display = "MiB", suffix = "mib", factor = 1024 ^ 2 },
			{ name = "gib", display = "GiB", suffix = "gib", factor = 1024 ^ 3 },
			{ name = "tib", display = "TiB", suffix = "tib", factor = 1024 ^ 4 },
		},
	},
	{
		key = "datarate",
		label = "Data Rate",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "bps", suffix = "bps", factor = 1 },
			{ name = "kbps", suffix = "kbps", factor = 1000 },
			{ name = "mbps", suffix = "mbps", factor = 1000000 },
			{ name = "gbps", suffix = "gbps", factor = 1000000000 },
			{ name = "tbps", suffix = "tbps", factor = 1000000000000 },
		},
	},
	{
		key = "length",
		label = "Length",
		kind = "linear",
		signed = true,
		decimals = 4,
		formats = {
			-- CSS / screen (smallest to largest)
			{ name = "px", suffix = "px", factor = 0.0254 / 96 },
			{ name = "em", suffix = "em", dynamic = "font" },
			{ name = "rem", suffix = "rem", dynamic = "font" },
			-- Typographic (smallest to largest)
			{ name = "pt", suffix = "pt", factor = 0.0254 / 72 },
			{ name = "pica", suffix = "pica", factor = 0.0254 / 6 },
			-- Metric (smallest to largest)
			{ name = "mm", suffix = "mm", factor = 0.001 },
			{ name = "cm", suffix = "cm", factor = 0.01 },
			{ name = "m", suffix = "m", factor = 1 },
			{ name = "km", suffix = "km", factor = 1000 },
			-- Imperial (smallest to largest)
			{ name = "in", suffix = "in", factor = 0.0254 },
			{ name = "ft", suffix = "ft", factor = 0.3048 },
			{ name = "yd", suffix = "yd", factor = 0.9144 },
			{ name = "mi", suffix = "mi", factor = 1609.344 },
			-- Imperial (less common, alphabetical)
			{ name = "barleycorn", suffix = "barleycorn", factor = 0.0254 / 3 },
			{ name = "bolt", suffix = "bolt", factor = 0.9144 * 40 },
			{ name = "cable", suffix = "cable", factor = 0.3048 * 608 },
			{ name = "chain", suffix = "chain", factor = 20.1168 },
			{ name = "clothyard", suffix = "clothyard", factor = 0.0254 * 37 },
			{ name = "cubit", suffix = "cubit", factor = 0.0254 * 18 },
			{ name = "ell", suffix = "ell", factor = 0.0254 * 45 },
			{ name = "fathom", suffix = "fathom", factor = 1.8288 },
			{ name = "finger", suffix = "finger", factor = 0.0254 * 4.5 },
			{ name = "furlong", suffix = "furlong", factor = 201.168 },
			{ name = "hand", suffix = "hand", factor = 0.1016 },
			{ name = "league", suffix = "league", factor = 4828.032 },
			{ name = "line", suffix = "line", factor = 0.0254 / 12 },
			{ name = "link", suffix = "link", factor = 0.0254 * 7.92 },
			{ name = "megalithicyard", suffix = "megalithicyard", factor = 0.3048 * 2.72 },
			{ name = "nail", suffix = "nail", factor = 0.0254 * 2.25 },
			{ name = "nmi", suffix = "nmi", factor = 1852 },
			{ name = "palm", suffix = "palm", factor = 0.0254 * 3 },
			{ name = "poppyseed", suffix = "poppyseed", factor = 0.0254 / 12 },
			{ name = "pyramidinch", suffix = "pyramidinch", factor = 0.0254 * 1.001 },
			{ name = "rod", suffix = "rod", factor = 0.0254 * 198 },
			{ name = "shackle", suffix = "shackle", factor = 0.0254 * 1080 },
			{ name = "span", suffix = "span", factor = 0.0254 * 9 },
			{ name = "thou", suffix = "thou", factor = 0.0254 / 1000 },
			-- Astronomical (smallest to largest)
			{ name = "angstrom", suffix = "angstrom", factor = 1e-10 },
			{ name = "ls", suffix = "ls", factor = 299792458 },
			{ name = "au", suffix = "au", factor = 149597870700 },
			{ name = "ly", suffix = "ly", factor = 9460730472580800 },
			{ name = "pc", suffix = "pc", factor = 648000 / math.pi * 149597870700 },
		},
	},
	{
		key = "area",
		label = "Area",
		kind = "linear",
		decimals = 6,
		formats = {
			-- Metric (factor = length-factor squared, base = m²)
			{ name = "mm2", suffix = "mm2", factor = 0.001 ^ 2 },
			{ name = "cm2", suffix = "cm2", factor = 0.01 ^ 2 },
			{ name = "m2", suffix = "m2", factor = 1 },
			{ name = "km2", suffix = "km2", factor = 1000 ^ 2 },
			-- Imperial
			{ name = "in2", suffix = "in2", factor = 0.0254 ^ 2 },
			{ name = "ft2", suffix = "ft2", factor = 0.3048 ^ 2 },
			{ name = "yd2", suffix = "yd2", factor = 0.9144 ^ 2 },
			{ name = "mi2", suffix = "mi2", factor = 1609.344 ^ 2 },
			-- Land
			{ name = "hectare", suffix = "ha", factor = 10000 },
			{ name = "acre", suffix = "acre", factor = 4046.8564224 },
		},
	},
	{
		key = "volume",
		label = "Volume",
		kind = "linear",
		decimals = 6,
		formats = {
			{ name = "ml", suffix = "ml", factor = 0.001 },
			{ name = "cl", suffix = "cl", factor = 0.01 },
			{ name = "dl", suffix = "dl", factor = 0.1 },
			{ name = "l", suffix = "l", factor = 1 },
			{ name = "m3", suffix = "m3", factor = 1000 },
			{ name = "tsp", suffix = "tsp", factor = 0.00492892159375 },
			{ name = "tbsp", suffix = "tbsp", factor = 0.01478676478125 },
			{ name = "floz", suffix = "floz", factor = 0.0295735295625 },
			{ name = "cup", suffix = "cup", factor = 0.2365882365 },
			{ name = "pint", suffix = "pint", factor = 0.473176473 },
			{ name = "qt", suffix = "qt", factor = 0.946352946 },
			{ name = "gal", suffix = "gal", factor = 3.785411784 },
		},
	},
	{
		key = "angle",
		label = "Angle",
		kind = "linear",
		signed = true,
		formats = {
			{ name = "deg", suffix = "deg", factor = 1 },
			{ name = "rad", suffix = "rad", factor = 180 / math.pi, decimals = 6 },
			{ name = "grad", suffix = "grad", factor = 0.9 },
			{ name = "turn", suffix = "turn", factor = 360, decimals = 6 },
		},
	},
	{
		key = "time",
		label = "Time",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "ns", suffix = "ns", factor = 1e-9 },
			{ name = "us", suffix = "us", factor = 1e-6 },
			{ name = "ms", suffix = "ms", factor = 0.001 },
			{ name = "s", suffix = "s", factor = 1 },
			{ name = "min", suffix = "min", factor = 60 },
			{ name = "h", suffix = "h", factor = 3600 },
			{ name = "day", suffix = "day", factor = 86400 },
			{ name = "week", suffix = "week", factor = 604800 },
			{ name = "fortnight", suffix = "fortnight", factor = 1209600 },
		},
	},
	{
		key = "speed",
		label = "Speed",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "mps", suffix = "mps", factor = 1 },
			{ name = "kmh", suffix = "kmh", factor = 1000 / 3600 },
			{ name = "mph", suffix = "mph", factor = 0.44704 },
			{ name = "fps", suffix = "fps", factor = 0.3048 },
			{ name = "kn", suffix = "kn", factor = 1852 / 3600 },
		},
	},
	{
		key = "mass",
		label = "Mass",
		kind = "linear",
		decimals = 6,
		formats = {
			{ name = "mg", suffix = "mg", factor = 1e-6 },
			{ name = "g", suffix = "g", factor = 0.001 },
			{ name = "kg", suffix = "kg", factor = 1 },
			{ name = "t", suffix = "t", factor = 1000 },
			{ name = "oz", suffix = "oz", factor = 0.028349523125 },
			{ name = "lb", suffix = "lb", factor = 0.45359237 },
			{ name = "st", suffix = "st", factor = 6.35029318 },
		},
	},
	{
		key = "pressure",
		label = "Pressure",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "pa", display = "Pa", suffix = "Pa", factor = 1 },
			{ name = "kpa", display = "kPa", suffix = "kPa", factor = 1000 },
			{ name = "bar", suffix = "bar", factor = 100000 },
			{ name = "atm", suffix = "atm", factor = 101325 },
			{ name = "psi", suffix = "psi", factor = 6894.757293168 },
			{ name = "mmhg", display = "mmHg", suffix = "mmHg", factor = 133.322387415 },
			{ name = "torr", suffix = "torr", factor = 133.3223684210526 },
		},
	},
	{
		key = "energy",
		label = "Energy",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "j", display = "J", suffix = "J", factor = 1 },
			{ name = "kj", display = "kJ", suffix = "kJ", factor = 1000 },
			{ name = "cal", suffix = "cal", factor = 4.184 },
			{ name = "kcal", suffix = "kcal", factor = 4184 },
			{ name = "wh", display = "Wh", suffix = "Wh", factor = 3600 },
			{ name = "kwh", display = "kWh", suffix = "kWh", factor = 3600000 },
			{ name = "btu", display = "BTU", suffix = "BTU", factor = 1055.05585262 },
		},
	},
	{
		key = "power",
		label = "Power",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "w", display = "W", suffix = "W", factor = 1 },
			{ name = "kw", display = "kW", suffix = "kW", factor = 1000 },
			{ name = "mw", display = "MW", suffix = "MW", factor = 1000000 },
			{ name = "gw", display = "GW", suffix = "GW", factor = 1000000000 },
			{ name = "hp", suffix = "hp", factor = 745.6998715822702 },
		},
	},
	{
		key = "temperature",
		label = "Temperature",
		kind = "temperature",
		signed = true,
		formats = {
			{ name = "celsius", letter = "C" },
			{ name = "fahrenheit", letter = "F" },
			{ name = "kelvin", letter = "K" },
		},
	},
	{
		key = "frequency",
		label = "Frequency",
		kind = "linear",
		decimals = 4,
		formats = {
			{ name = "hz", display = "Hz", suffix = "Hz", factor = 1 },
			{ name = "khz", display = "kHz", suffix = "kHz", factor = 1000 },
			{ name = "mhz", display = "MHz", suffix = "MHz", factor = 1000000 },
			{ name = "ghz", display = "GHz", suffix = "GHz", factor = 1000000000 },
			{ name = "thz", display = "THz", suffix = "THz", factor = 1000000000000 },
		},
	},
	{
		key = "color",
		label = "Color",
		kind = "color",
		formats = {
			{ name = "hex_color" },
			{ name = "rgb" },
			{ name = "hsl" },
			{ name = "tailwind" },
		},
	},
}

-- Lookups: name -> group, name -> entry. Rebuilt whenever groups change.
local name_to_group = {}
local name_to_entry = {}

local function rebuild()
	name_to_group = {}
	name_to_entry = {}
	for _, group in ipairs(M.groups) do
		for _, entry in ipairs(group.formats) do
			name_to_group[entry.name] = group
			name_to_entry[entry.name] = entry
		end
	end
end

rebuild()

-- Register a user-defined group, or extend a built-in one.
--   { extend = "length", formats = { ... } }  -- append to an existing group
--   { key = "epoch", label = ..., kind = ..., formats = { ... } }  -- new group
function M.register_group(spec)
	local target = spec
	if spec.extend then
		target = nil
		for _, group in ipairs(M.groups) do
			if group.key == spec.extend then
				target = group
				break
			end
		end
		if not target then
			error("convy: cannot extend unknown group '" .. spec.extend .. "'", 0)
		end
	else
		if not spec.key or not spec.kind then
			error("convy: a new group needs a 'key' and a 'kind'", 0)
		end
		if M.label(spec.key) then
			error("convy: group key '" .. spec.key .. "' already exists", 0)
		end
	end

	for _, entry in ipairs(spec.formats) do
		if entry.name == "auto" then
			error("convy: 'auto' is a reserved format name", 0)
		end
		if name_to_entry[entry.name] then
			error("convy: format name '" .. entry.name .. "' already exists", 0)
		end
		if (spec.kind or (target and target.kind)) == "custom" and not (entry.decode and entry.encode) then
			error("convy: custom format '" .. entry.name .. "' needs decode and encode functions", 0)
		end
		name_to_entry[entry.name] = entry -- claim the name so later specs see the collision
	end

	if spec.extend then
		for _, entry in ipairs(spec.formats) do
			table.insert(target.formats, entry)
		end
	else
		table.insert(M.groups, spec)
	end

	rebuild()
	local utils = require("convy.utils")
	if utils.reset_detection then
		utils.reset_detection()
	end
end

function M.get_group(name)
	local group = name_to_group[name]
	return group and group.key
end

function M.get_group_def(name)
	return name_to_group[name]
end

function M.get_entry(name)
	return name_to_entry[name]
end

function M.label(group_key)
	for _, group in ipairs(M.groups) do
		if group.key == group_key then
			return group.label
		end
	end
end

function M.display(name)
	local entry = name_to_entry[name]
	return entry and (entry.display or entry.name) or name
end

function M.get_compatible_outputs(name)
	local group = name_to_group[name]
	if not group then
		return {}
	end

	local outputs = {}
	for _, entry in ipairs(group.formats) do
		if entry.name ~= name then
			table.insert(outputs, entry.name)
		end
	end
	return outputs
end

function M.get_all_input_formats()
	local result = { "auto" }
	for _, group in ipairs(M.groups) do
		for _, entry in ipairs(group.formats) do
			table.insert(result, entry.name)
		end
	end
	return result
end

function M.get_output_formats(input_format)
	if input_format == "auto" then
		local result = {}
		for _, group in ipairs(M.groups) do
			for _, entry in ipairs(group.formats) do
				table.insert(result, entry.name)
			end
		end
		return result
	end

	return M.get_compatible_outputs(input_format)
end

function M.are_compatible(format_a, format_b)
	local group_a = name_to_group[format_a]
	local group_b = name_to_group[format_b]
	return group_a ~= nil and group_a == group_b
end

return M
