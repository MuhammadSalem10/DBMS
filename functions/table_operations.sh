#!/bin/bash

function table_menu() {
    if [ -z "$CURRENT_DB" ]; then
        echo "Error: No database connected. Returning to Main Menu."
        return 1
    fi

    while true; do
        clear
        echo "================= Database Menu ==================="
        echo " Connected to Database: $CURRENT_DB"
        echo "----------------------------------------------------"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select From Table"
        echo "6. Delete From Table"
        echo "7. Update Table"
        echo "8. Back to Main Menu"
        echo "======================================================"
        read -p "Enter your choice: " choice

        case "$choice" in
        1) create_table ;;
        2) list_tables ;;
        3) drop_table ;;
        4) insert_into_table ;;
        5) select_from_table ;;
        6) delete_from_table ;;
        7) update_table ;;
        8)
            echo "Returning to Main Menu..."
            break
            ;;
        *) echo "Invalid choice. Try again." ;;
        esac
        echo ""
    done
}

function create_table {
    local table_name
    local PK_col
    read -p "Enter table name: " table_name

    if ! is_valid_name "$table_name" "Table"; then
        return 1
    fi

    local metadata_file="$DB_DIR/$CURRENT_DB/$table_name.meta"
    local data_file="$DB_DIR/$CURRENT_DB/$table_name.data"

    if [[ -f "$metadata_file" ]]; then
        echo "Error: Table '$table_name' already exists!"
        return 1
    fi

    while true; do
        read -p "Add column (name:type). write \"done\" to finish: " col_input
        if [[ "$col_input" == "done" ]]; then
            break
        fi

        IFS=':'
        read -r col_name col_type <<<"$col_input"

        if [[ -z "$col_name" || -z "$col_type" ]]; then
            echo "Error: Invalid column format. Use name:type"
            continue
        fi

        case "$col_type" in
        1 | int) col_type="int" ;;
        2 | string) col_type="string" ;;
        *)
            echo "Error: Invalid data type. Use 1 (int) or 2 (string)"
            continue
            ;;
        esac

        echo "$col_name:$col_type" >>"$metadata_file"
    done

    local count=1
    while IFS=: read -r col_name col_type; do
        echo "$count. $col_name"
        ((count++))
    done <"$metadata_file"

    read -p "Choose primary key column: " PK_col

    sed -i "${PK_col}s/$/:primary_key/" "$metadata_file"

    touch "$data_file"
    echo "Table '$table_name' created in '$CURRENT_DB'."
}
