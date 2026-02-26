#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# tools.sh — optional but frequently used CLI tools
# Not required by the dotfiles. Safe to re-run (uses --needed).
# ─────────────────────────────────────────────────────────────────────────────

TOOLS=(
    croc        # peer-to-peer encrypted file transfer
    ripgrep     # fast grep replacement (rg)
    fd          # fast find replacement (fd)
    bat         # cat with syntax highlighting
    eza         # modern ls replacement with icons
    dust        # intuitive du replacement
    procs       # modern ps replacement
    bottom      # htop alternative with graphs (btm)
    lazygit     # terminal UI for git
    jq          # JSON processor
    yq          # YAML/JSON/TOML processor
    httpie      # user-friendly HTTP client (http)
    tldr        # simplified man pages
    tokei       # count lines of code
    hyperfine   # command-line benchmarking
    glow        # render markdown in the terminal
    tmux        # terminal multiplexer
    tailscale   # mesh VPN
)

yay -S --needed --noconfirm "${TOOLS[@]}"
