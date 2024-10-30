#!/bin/bash
TASK_FILE="tasks.txt"
BACKUP_DIR="task_backups"
CONFIG_FILE="taskify_config.txt"

# Load or create default configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "auto_backup=true" > "$CONFIG_FILE"
        echo "reminder_enabled=true" >> "$CONFIG_FILE"
        echo "priority_colors=true" >> "$CONFIG_FILE"
    fi
    source "$CONFIG_FILE"
}

# Initialize backup directory
init_backup() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi
}

# Function to backup tasks
backup_tasks() {
    if [ "$auto_backup" = "true" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        cp "$TASK_FILE" "$BACKUP_DIR/tasks_backup_$timestamp.txt"
        echo "Backup created: tasks_backup_$timestamp.txt"
    fi
}

# Function to restore from backup
restore_from_backup() {
    echo "Available backups:"
    ls -1 "$BACKUP_DIR"
    read -p "Enter backup filename to restore: " backup_file
    if [ -f "$BACKUP_DIR/$backup_file" ]; then
        cp "$BACKUP_DIR/$backup_file" "$TASK_FILE"
        echo "Tasks restored from backup."
    else
        echo "Backup file not found."
    fi
}

# Function to add a task with priority and due date
add_task() {
    echo "Priority levels: [High] [Medium] [Low]"
    read -p "Enter priority level (H/M/L): " priority
    read -p "Enter due date (YYYY-MM-DD): " due_date
    case $priority in
        [Hh]) priority="[High]" ;;
        [Mm]) priority="[Medium]" ;;
        [Ll]) priority="[Low]" ;;
        *) priority="[Medium]" ;;
    esac
    echo "[Pending] $priority [$due_date] $1" >> "$TASK_FILE"
    echo "Task '$1' added with $priority priority and due date $due_date."
    backup_tasks
}

# Function to display tasks with color based on priority
display_colored_task() {
    if [ "$priority_colors" = "true" ]; then
        if [[ $1 == *"[High]"* ]]; then
            echo -e "\e[31m$1\e[0m"  # Red for high priority
        elif [[ $1 == *"[Medium]"* ]]; then
            echo -e "\e[33m$1\e[0m"  # Yellow for medium priority
        else
            echo -e "\e[32m$1\e[0m"  # Green for low priority
        fi
    else
        echo "$1"
    fi
}

# Function to check due dates and show reminders
check_due_dates() {
    if [ "$reminder_enabled" = "true" ] && [ -f "$TASK_FILE" ]; then
        today=$(date +%Y-%m-%d)
        while IFS= read -r task; do
            if [[ $task == *"[Pending]"* ]]; then
                due_date=$(echo "$task" | grep -o '\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\]' | tr -d '[]')
                if [ ! -z "$due_date" ] && [ "$due_date" = "$today" ]; then
                    echo "⚠️ REMINDER: Task due today: $task"
                fi
            fi
        done < "$TASK_FILE"
    fi
}

# Enhanced view_all_tasks with sorting options
view_all_tasks() {
    if [ -f "$TASK_FILE" ]; then
        echo "Sort by: "
        echo "1. Priority"
        echo "2. Due Date"
        echo "3. Default (No sorting)"
        read -p "Choose sorting option [1-3]: " sort_option
        case $sort_option in
            1) sort -t']' -k2 "$TASK_FILE" | nl -w2 -s'. ' | while read -r task; do
                display_colored_task "$task"
            done ;;
            2) sort -t']' -k3 "$TASK_FILE" | nl -w2 -s'. ' | while read -r task; do
                display_colored_task "$task"
            done ;;
            3) nl -w2 -s'. ' "$TASK_FILE" | while read -r task; do
                display_colored_task "$task"
            done ;;
        esac
    else
        echo "No tasks available."
    fi
}

# Function to search tasks
search_tasks() {
    read -p "Enter search term: " search_term
    if [ -f "$TASK_FILE" ]; then
        echo "Search results:"
        grep -i "$search_term" "$TASK_FILE" | nl -w2 -s'. ' | while read -r task; do
            display_colored_task "$task"
        done
    fi
}

# Function to toggle settings
manage_settings() {
    echo "Settings:"
    echo "1. Toggle auto backup (currently: $auto_backup)"
    echo "2. Toggle reminders (currently: $reminder_enabled)"
    echo "3. Toggle priority colors (currently: $priority_colors)"
    read -p "Choose setting to toggle [1-3]: " setting_option
    case $setting_option in
        1) auto_backup=$([ "$auto_backup" = "true" ] && echo "false" || echo "true")
           sed -i "s/auto_backup=.*/auto_backup=$auto_backup/" "$CONFIG_FILE" ;;
        2) reminder_enabled=$([ "$reminder_enabled" = "true" ] && echo "false" || echo "true")
           sed -i "s/reminder_enabled=.*/reminder_enabled=$reminder_enabled/" "$CONFIG_FILE" ;;
        3) priority_colors=$([ "$priority_colors" = "true" ] && echo "false" || echo "true")
           sed -i "s/priority_colors=.*/priority_colors=$priority_colors/" "$CONFIG_FILE" ;;
    esac
    echo "Settings updated."
}

# Enhanced menu with new options
menu() {
    check_due_dates
    echo ""
    echo "📝 Taskify - Advanced Task Manager"
    echo "1. Add a task"
    echo "2. View all tasks"
    echo "3. View pending tasks"
    echo "4. View completed tasks"
    echo "5. Mark a task as done"
    echo "6. Delete a task"
    echo "7. Search tasks"
    echo "8. Backup tasks"
    echo "9. Restore from backup"
    echo "10. Manage settings"
    echo "11. Exit"
    echo ""
    read -p "Choose an option [1-11]: " option
}

# Initialize
load_config
init_backup

# Main loop with enhanced options
while true; do
    menu
    case $option in
        1) read -p "Enter the task description: " task_desc
           add_task "$task_desc" ;;
        2) view_all_tasks ;;
        3) view_pending_tasks ;;
        4) view_done_tasks ;;
        5) view_pending_tasks
           read -p "Enter the task number to mark as done: " task_num
           mark_task_done "$task_num" ;;
        6) view_all_tasks
           read -p "Enter the task number to delete: " task_num
           delete_task "$task_num" ;;
        7) search_tasks ;;
        8) backup_tasks ;;
        9) restore_from_backup ;;
        10) manage_settings ;;
        11) echo "Goodbye! 👋"
            exit 0 ;;
        *) echo "Invalid option. Please choose a number between 1 and 11." ;;
    esac
done
