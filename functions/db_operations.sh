#!/bin/bash
source ./variables.sh

function create_db {
    echo "====== Create Database ============"
    echo "-----------------------------------"
    read -p "Database name: " db_name

    if ! is_valid_name "$db_name" "Database"; then
        return 1
    fi

    if [[ -d "$DB_DIR/$db_name" ]]; then
        echo "Error: Database $db_name already exists!"
    else
        mkdir -p "$DB_DIR/$db_name"
        if [[ $? -eq 0 ]]; then
            echo "Database $db_name created successfully."
        else
            echo "Error creating database '$db_name'."
        fi
    fi
}

function list_dbs {
    echo "Available databases."
    ls -d $DB_DIR/* | cut -d/ -f 2
}

function drop_db {
    set -x
    local db_name
    read -p "Database name: " db_name
    local db_path="$DB_DIR/$db_name"

    if [[ -d $db_path ]]; then
        read -p "Are you sure want to delete ${db_name}? (y/n) " confirm
        if [[ $confirm =~ ^[yY]$ ]]; then
            if rm -r "$db_path"; then
                echo "Database $db_name dropped"
                if [ "$CURRENT_DB" == "$db_name" ]; then
                    CURRENT_DB=""
                fi
            else
                echo "Error: Failed to drop $db_name database"
            fi
        else
            echo "Operation cancelled."
        fi
    else
        echo "Database $db_name not found!"
        return 1
    fi
    set +x
}

function connect_db {
    local db_name
    read -p "Database name to connect to: " db_name
    db_path="$DB_DIR/$db_name"
    if [[ -d "$db_path" ]]; then
        CURRENT_DB=$db_name
        echo "Connected to database $db_name"
        table_menu "$db_name"
    else
        echo "Database $db_name not found."
        pause
    fi
    pause
}
