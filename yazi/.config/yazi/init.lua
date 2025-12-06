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
