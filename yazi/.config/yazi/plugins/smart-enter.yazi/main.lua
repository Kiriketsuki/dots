--- @since 25.5.31
--- @sync entry

local function setup(self, opts) self.open_multi = opts.open_multi end

local function entry(self)
	local h = cx.active.current.hovered
	-- Force multi-select behavior as setup() config might not persist to here
	local multi = true
	ya.emit(h and h.cha.is_dir and "enter" or "open", { hovered = not multi })
end

return { entry = entry, setup = setup }
