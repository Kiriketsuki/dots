# Styles

This directory contains CSS files that define color palettes. These files are intended to be used as themes or color schemes for other applications or configurations.

## Guidelines

-   **Content**: Files should only contain CSS variable definitions for colors.
-   **Format**: Use the `:root` pseudo-class to define variables.
-   **Quantity**: Each file must define **at least 5 colors**.
-   **Naming**: Color names can be arbitrary (e.g., `--background`, `--primary`, `--accent-1`).

## Example

```css
:root {
    --background: #1a1b26;
    --foreground: #c0caf5;
    --primary: #7aa2f7;
    --secondary: #bb9af7;
    --alert: #f7768e;
}
```
