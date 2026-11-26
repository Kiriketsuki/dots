-- Add a custom widget to the Status Bar at the bottom left
Status:children_add(function()
	return ui.Line {
		ui.Span(" [Keybinds] "):fg("yellow"):bold(),
		ui.Span("Copy:"):fg("blue"),
		ui.Span("y "),
		ui.Span("Cut:"):fg("blue"),
		ui.Span("x "),
		ui.Span("Paste:"):fg("blue"),
		ui.Span("p "),
		ui.Span("Del:"):fg("red"),
		ui.Span("d "),
		ui.Span(" | "),
	}
end, 1000, Status.LEFT)

require("smart-enter"):setup {
	open_multi = true,
}

-- Portal file chooser: overwrite dialog, OPEN/SAVE header, invalid-pick warnings.
-- The setup call is required even with default options.
require("filechooser"):setup {
	overwrite_dialog = true,
	open_multi_dialog = 5,
	header = true,
	yank_save_dummy = true,
}

