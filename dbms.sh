#!/bin/bash

source ./functions/utility.sh
source ./functions/db_operations.sh
source ./functions/table_operations.sh
source ./variables.sh

while true; do
    echo "============ Main Menu ============="
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"

    read -p "Choose an option: " choice

    case $choice in
    1)
        create_db
        ;;
    2)
        list_dbs
        ;;
    3)
        connect_db
        ;;
    4)
        drop_db
        ;;
    5)
        exit 0
        ;;
    *)
        echo "Invalid option"
        ;;

    esac
done

#select - update - create table - list tables - Connect to DB - Drop table
