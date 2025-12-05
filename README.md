# Dotfiles

My personal configuration files (dotfiles), managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

-   **bash/**: Bash shell configuration
-   **hypr/**: Hyprland configuration
-   **nvim/**: Neovim configuration
-   **zsh/**: Zsh shell configuration
-   **Code/**: Visual Studio Code settings

## Requirements

-   [GNU Stow](https://www.gnu.org/software/stow/)
-   git

## Installation

1. Clone this repository:

    ```sh
    git clone https://github.com/Kiriketsuki/dots.git ~/dots
    cd ~/dots
    ```

2. Install configurations using stow:

    ```sh
    # Install everything
    stow .

    # Or install specific packages
    stow zsh nvim
    ```

    By default, stow will create symlinks in the parent directory (`../`), which should be your home directory if you cloned into `~/dots`.

## Management

-   **Update**: `git pull` inside the directory.
-   **Uninstall**: `stow -D <package>` (e.g., `stow -D nvim`).
