#!/usr/bin/env bash
# Tells apps to use a dark scheme. Firefox, Electron apps and libadwaita read
# color-scheme through the settings portal. GTK3 apps read gtk-theme. Plain
# Adwaita is right: Adwaita-dark needs gnome-themes-extra, which is not installed.
# The Chrysaki colors come from ~/.config/gtk-3.0/gtk.css and gtk-4.0/gtk.css.
set -u
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Chrysaki'
gsettings set org.gnome.desktop.interface font-name 'Red Hat Mono 11'
