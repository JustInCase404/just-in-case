#!/bin/bash

# Define an array of essential applications
apps_to_install=(
    "lmms"
    "kdenlive"
    "telegram-desktop"
    "signal-desktop"
    "obsidian"
    "gparted"
    "google-chrome"
    "tor-browser"
    "mullvad-vpn"
    "visual-studio-code"
    "vlc"
)

# Function to install apps from the official Manjaro repositories
install_apps() {
    echo "Updating package list..."
    sudo pacman -Syu --noconfirm

    for app in "${apps_to_install[@]}"; do
        echo "Installing $app..."
        if ! pacman -Qi "$app" &> /dev/null; then
            sudo pacman -S "$app" --noconfirm
        else
            echo "$app is already installed."
        fi
    done
}

# Function to create web apps using a desktop environment like GNOME, KDE, or others
create_webapps() {
    echo "Creating web apps for GitHub, ChatGPT, Suno, Kits.ai, Proton Drive, Bitwarden, Netflix, YouTube Music, and Photopea..."

    # Define a list of web apps
    declare -A web_apps
    web_apps=(
        ["Github"]="https://github.com"
        ["ChatGPT"]="https://chat.openai.com"
        ["Suno"]="https://suno.ai"
        ["Kits.ai"]="https://kits.ai"
        ["Proton Drive"]="https://drive.protonmail.com"
        ["Bitwarden"]="https://vault.bitwarden.com"
        ["Netflix"]="https://www.netflix.com"
        ["YouTube Music"]="https://music.youtube.com"
        ["Photopea"]="https://www.photopea.com"
    )

    # Loop through the web apps and create them
    for app_name in "${!web_apps[@]}"; do
        app_url="${web_apps[$app_name]}"
        app_desktop_file="$HOME/.local/share/applications/$app_name.desktop"

        if [[ ! -f "$app_desktop_file" ]]; then
            echo "Creating desktop shortcut for $app_name..."
            echo "[Desktop Entry]" > "$app_desktop_file"
            echo "Version=1.0" >> "$app_desktop_file"
            echo "Name=$app_name" >> "$app_desktop_file"
            echo "Exec=xdg-open $app_url" >> "$app_desktop_file"
            echo "Icon=web" >> "$app_desktop_file"
            echo "Terminal=false" >> "$app_desktop_file"
            echo "Type=Application" >> "$app_desktop_file"
            echo "Categories=Internet;" >> "$app_desktop_file"
            chmod +x "$app_desktop_file"
        else
            echo "$app_name already has a desktop shortcut."
        fi
    done
}

# Function to ensure that web app icons are correctly set up
set_webapp_icons() {
    echo "Setting web app icons..."

    for app_name in "${!web_apps[@]}"; do
        app_desktop_file="$HOME/.local/share/applications/$app_name.desktop"

        if [[ -f "$app_desktop_file" ]]; then
            # Download a generic web icon for the web apps
            icon_url="https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Iconic_link.svg/1024px-Iconic_link.svg.png"
            icon_path="$HOME/.local/share/icons/$app_name.png"
            curl -s -o "$icon_path" "$icon_url"
            sed -i "s|Icon=web|Icon=$icon_path|" "$app_desktop_file"
        fi
    done
}

# Function to ensure the menu bar organization
organize_menu() {
    echo "Organizing applications in the menu bar..."

    menu_dir="$HOME/.local/share/applications"
    mkdir -p "$menu_dir/Multimedia"
    mkdir -p "$menu_dir/Development"
    mkdir -p "$menu_dir/Internet"
    mkdir -p "$menu_dir/Utilities"

    # Move installed applications to the correct folders
    mv "$menu_dir/lmms.desktop" "$menu_dir/Multimedia/"
    mv "$menu_dir/kdenlive.desktop" "$menu_dir/Multimedia/"
    mv "$menu_dir/telegram-desktop.desktop" "$menu_dir/Internet/"
    mv "$menu_dir/signal-desktop.desktop" "$menu_dir/Internet/"
    mv "$menu_dir/obsidian.desktop" "$menu_dir/Utilities/"
    mv "$menu_dir/gparted.desktop" "$menu_dir/Utilities/"
    mv "$menu_dir/google-chrome.desktop" "$menu_dir/Internet/"
    mv "$menu_dir/tor-browser.desktop" "$menu_dir/Internet/"
    mv "$menu_dir/mullvad-vpn.desktop" "$menu_dir/Utilities/"
    mv "$menu_dir/visual-studio-code.desktop" "$menu_dir/Development/"
    mv "$menu_dir/vlc.desktop" "$menu_dir/Multimedia/"
}

# Function to install Yubikey-related software (not placed on menu bar)
install_yubikey_software() {
    echo "Installing Yubikey tools (not placed on menu bar)..."
    sudo pacman -S yubikey-manager yubico-authenticator --noconfirm
}

# Main function to call all the necessary operations
main() {
    install_apps
    install_yubikey_software
    create_webapps
    set_webapp_icons
    organize_menu

    echo "Installation and organization complete!"
}

# Execute the main function
main

