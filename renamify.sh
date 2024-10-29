#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print colored output
print_color() {
    case $1 in
        "red") echo -e "${RED}$2${NC}" ;;
        "green") echo -e "${GREEN}$2${NC}" ;;
        "yellow") echo -e "${YELLOW}$2${NC}" ;;
        "blue") echo -e "${BLUE}$2${NC}" ;;
    esac
}

# Show banner
show_banner() {
    print_color "blue" "================================"
    print_color "blue" "          RENAMIFY v2.0         "
    print_color "blue" "   Batch File Renaming Utility  "
    print_color "blue" "================================"
}

# Function to check if directory exists and is writable
check_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        print_color "red" "Error: Directory '$dir' does not exist."
        return 1
    elif [ ! -w "$dir" ]; then
        print_color "red" "Error: Directory '$dir' is not writable."
        return 1
    fi
    return 0
}

# Function for sequential renaming
rename_files() {
    local target_files=$1
    local new_name=$2
    local target_directory=$3
    local start_number=${4:-1}
    local padding=${5:-1}

    check_directory "$target_directory" || return 1

    shopt -s nullglob
    files=("$target_directory"/*"$target_files")
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        print_color "yellow" "No files matching the pattern '$target_directory/*$target_files'."
        return 1
    fi

    print_color "blue" "\nPreviewing changes:"
    counter=$start_number
    for i in "${files[@]}"; do
        if [ -f "$i" ]; then
            base_file=$(basename "$i")
            padded_number=$(printf "%0${padding}d" $counter)
            new_file="${target_directory}/${new_name}_${padded_number}${target_files}"
            echo "'$base_file' → '$(basename "$new_file")'"
            ((counter++))
        fi
    done

    read -p "Proceed with renaming? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        print_color "yellow" "Operation cancelled."
        return 0
    fi

    counter=$start_number
    for i in "${files[@]}"; do
        if [ -f "$i" ]; then
            base_file=$(basename "$i")
            padded_number=$(printf "%0${padding}d" $counter)
            new_file="${target_directory}/${new_name}_${padded_number}${target_files}"
            mv "$i" "$new_file"
            print_color "green" "✓ Renamed '$base_file' to '$(basename "$new_file")'"
            ((counter++))
        fi
    done
}

# Function to add prefix/suffix
add_text_in_name() {
    local target_files=$1
    local new_text=$2
    local target_directory=$3
    local position=$4

    check_directory "$target_directory" || return 1

    shopt -s nullglob
    files=("$target_directory"/*"$target_files")
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        print_color "yellow" "No files matching the pattern '$target_directory/*$target_files'."
        return 1
    fi

    print_color "blue" "\nPreviewing changes:"
    for i in "${files[@]}"; do
        if [ -f "$i" ]; then
            base_file=$(basename "$i")
            filename="${base_file%.*}"
            extension="${base_file##*.}"
            
            if [ "$position" = "prefix" ]; then
                new_file="${target_directory}/${new_text}_${filename}.${extension}"
            else
                new_file="${target_directory}/${filename}_${new_text}.${extension}"
            fi
            echo "'$base_file' → '$(basename "$new_file")'"
        fi
    done

    read -p "Proceed with renaming? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        print_color "yellow" "Operation cancelled."
        return 0
    fi

    for i in "${files[@]}"; do
        if [ -f "$i" ]; then
            base_file=$(basename "$i")
            filename="${base_file%.*}"
            extension="${base_file##*.}"
            
            if [ "$position" = "prefix" ]; then
                new_file="${target_directory}/${new_text}_${filename}.${extension}"
            else
                new_file="${target_directory}/${filename}_${new_text}.${extension}"
            fi
            mv "$i" "$new_file"
            print_color "green" "✓ Renamed '$base_file' to '$(basename "$new_file")'"
        fi
    done
}

# Show menu
show_menu() {
    echo -e "\nPlease choose an option:"
    echo "1. Sequential renaming (file_001.txt, file_002.txt...)"
    echo "2. Add prefix to filenames"
    echo "3. Add suffix to filenames"
    echo "4. Replace text in filenames"
    echo "5. Exit"
}

# Main execution
show_banner

while true; do
    show_menu
    read -p "Enter your choice (1-5): " user_choice

    case "$user_choice" in
        1)
            read -p "Enter file extension (e.g., .txt): " file_extension
            [[ "$file_extension" != .* ]] && { print_color "red" "Error: File extension should start with a dot."; continue; }
            
            read -p "Enter new base name: " new_name
            [[ -z "$new_name" ]] && { print_color "red" "Error: Base name cannot be empty."; continue; }
            
            read -p "Enter target directory: " target_directory
            read -p "Enter starting number [1]: " start_number
            start_number=${start_number:-1}
            
            read -p "Enter number padding (e.g., 3 for 001) [1]: " padding
            padding=${padding:-1}
            
            rename_files "$file_extension" "$new_name" "$target_directory" "$start_number" "$padding"
            ;;
        2|3)
            read -p "Enter file extension (e.g., .txt): " file_extension
            [[ "$file_extension" != .* ]] && { print_color "red" "Error: File extension should start with a dot."; continue; }
            
            read -p "Enter text to add: " new_text
            [[ -z "$new_text" ]] && { print_color "red" "Error: Text cannot be empty."; continue; }
            
            read -p "Enter target directory: " target_directory
            position=$([[ "$user_choice" == "2" ]] && echo "prefix" || echo "suffix")
            
            add_text_in_name "$file_extension" "$new_text" "$target_directory" "$position"
            ;;
        4)
            read -p "Enter file extension (e.g., .txt): " file_extension
            [[ "$file_extension" != .* ]] && { print_color "red" "Error: File extension should start with a dot."; continue; }
            
            read -p "Enter text to search for: " search_text
            read -p "Enter text to replace with: " replace_text
            read -p "Enter target directory: " target_directory
            
            replace_text "$file_extension" "$search_text" "$replace_text" "$target_directory"
            ;;
        5)
            print_color "green" "Thank you for using Renamify!"
            exit 0
            ;;
        *)
            print_color "red" "Invalid choice. Please try again."
            ;;
    esac
done

