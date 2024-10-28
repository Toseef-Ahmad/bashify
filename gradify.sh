#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize package manager variable
pkm=""

# Print colored output
print_color() {
    case $1 in
        "red") echo -e "${RED}$2${NC}" ;;
        "green") echo -e "${GREEN}$2${NC}" ;;
        "yellow") echo -e "${YELLOW}$2${NC}" ;;
        "blue") echo -e "${BLUE}$2${NC}" ;;
    esac
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color "red" "This script must be run as root (sudo)"
        exit 1
    fi
}

# Function to update OS
update_os() {
    print_color "blue" "\nUpdating package repositories..."
    case $pkm in
        "apt")
            apt-get update
            ;;
        "dnf")
            dnf check-update
            ;;
        "yum")
            yum check-update
            ;;
        "pacman")
            pacman -Sy
            ;;
        "zypper")
            zypper refresh
            ;;
        "emerge")
            emerge --sync
            ;;
    esac
    if [ $? -eq 0 ]; then
        print_color "green" "Update completed successfully!"
    else
        print_color "red" "Update failed!"
        exit 1
    fi
}

# Function to upgrade OS
upgrade_os() {
    print_color "blue" "\nUpgrading packages..."
    case $pkm in
        "apt")
            apt-get upgrade -y
            ;;
        "dnf")
            dnf upgrade -y
            ;;
        "yum")
            yum upgrade -y
            ;;
        "pacman")
            pacman -Syu --noconfirm
            ;;
        "zypper")
            zypper update -y
            ;;
        "emerge")
            emerge -uDN @world
            ;;
    esac
    if [ $? -eq 0 ]; then
        print_color "green" "Upgrade completed successfully!"
    else
        print_color "red" "Upgrade failed!"
        exit 1
    fi
}

# Function to clean up
cleanup_system() {
    print_color "blue" "\nCleaning up system..."
    case $pkm in
        "apt")
            apt-get autoremove -y
            apt-get clean
            ;;
        "dnf")
            dnf autoremove -y
            dnf clean all
            ;;
        "yum")
            yum autoremove -y
            yum clean all
            ;;
        "pacman")
            pacman -Sc --noconfirm
            ;;
        "zypper")
            zypper clean -a
            ;;
        "emerge")
            emerge --depclean
            ;;
    esac
}

# Function to detect package manager
get_pkm() {
    if command -v apt-get >/dev/null 2>&1; then
        pkm="apt"
    elif command -v dnf >/dev/null 2>&1; then
        pkm="dnf"
    elif command -v yum >/dev/null 2>&1; then
        pkm="yum"
    elif command -v pacman >/dev/null 2>&1; then
        pkm="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        pkm="zypper"
    elif command -v emerge >/dev/null 2>&1; then
        pkm="emerge"
    else
        print_color "red" "No known package manager found."
        exit 1
    fi
}

# Function to show disk space
show_disk_space() {
    print_color "yellow" "\nCurrent Disk Space Usage:"
    df -h /
}

# Main menu
show_menu() {
    clear
    print_color "blue" "================================"
    print_color "blue" "   System Update & Maintenance   "
    print_color "blue" "================================"
    print_color "yellow" "Detected Package Manager: $pkm"
    echo -e "\nPlease choose an option:"
    echo "1. Update OS (Refresh Package List)"
    echo "2. Upgrade OS (Install Updates)"
    echo "3. Update & Upgrade OS"
    echo "4. Clean Up System"
    echo "5. Show Disk Space"
    echo "6. Exit"
    echo "================================"
    read -p "Enter your choice [1-6]: " user_choice
}

# Main execution
check_root
get_pkm

while true; do
    show_menu
    case $user_choice in
        1)
            update_os
            ;;
        2)
            upgrade_os
            ;;
        3)
            update_os
            upgrade_os
            cleanup_system
            ;;
        4)
            cleanup_system
            ;;
        5)
            show_disk_space
            ;;
        6)
            print_color "green" "Exiting..."
            exit 0
            ;;
        *)
            print_color "red" "Invalid option. Please try again."
            ;;
    esac
    read -p "Press Enter to continue..."
done
