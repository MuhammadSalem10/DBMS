#!/bin/bash

function table_menu() {
    if [ -z "$CURRENT_DB" ]; then
        echo "Error: No database connected. Returning to Main Menu."
        return 1
    fi

    local choice
    local options
    local prompt

    prompt="Enter your choice: "
    options=("Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Back to Main Menu")

    while true; do
        clear
        echo "==================== Database Menu ====================="
        echo "  Connected to Database: $CURRENT_DB"
        echo "------------------------------------------------------"

        select opt in "${options[@]}"; do
            case $REPLY in
            1)
                create_table
                break
                ;;
            2)
                list_tables
                break
                ;;
            3)
                drop_table
                break
                ;;
            4)
                insert_into_table
                break
                ;;
            5)
                select_from_table
                break
                ;;
            6)
                delete_from_table
                break
                ;;
            7)
                update_table
                break
                ;;
            8)
                echo "Returning to the main menu..."
                return
                ;;
            *) echo "Invalid choice. Try again." ;;
            esac
        done
        echo ""
        pause "Press Enter to continue..."
    done
}
