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

    local column_added=false

    while true; do
        read -p "Add column (name:type). write \"done\" to finish: " col_input
        if [[ "$col_input" == "done" ]]; then
            if [ "$column_added" = false ]; then
                echo "Error: Please add at least one column."
            else
                break
            fi
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
        echo "$col_name" >>"$data_file"
        column_added=true

    done

    local count=1
    while IFS=: read -r col_name col_type; do
        echo "$count. $col_name"
        ((count++))
    done <"$metadata_file"

    read -p "Choose primary key column: " PK_col

    sed -i "s/^$PK_col:.*/&:primary_key/" "$metadata_file"
    cut -d: -f1 "$metadata_file" | paste -d: -s >"$data_file"
    echo "Table '$table_name' created in '$CURRENT_DB'."
    pause
}

function list_tables() {
    local tables
    echo "=============  List Tables in Database  ========== "
    tables=$(find "$DB_DIR/$CURRENT_DB" -name "*.meta" | awk -F'/' '{print $NF}' | sed "s/\.meta$//")

    if [[ -z "$tables" ]]; then
        echo "The database is empty."
    fi
    echo "Tables in $CURRENT_DB database are: "
    echo "$tables" | nl
    pause
}

function drop_table() {
    echo "============= Drop Table from Database ========="
    local table_name
    tables=$(find "$DB_DIR/$CURRENT_DB" -name "*.meta" | awk -F'/' '{print $NF}' | sed "s/\.meta$//")

    if [[ -z "$tables" ]]; then
        echo "The database is empty."
    fi
    echo "Tables in $CURRENT_DB database are: "
    echo "$tables" | nl

    read -p "Enter table name to drop: " table_name

    table_file="$DB_DIR/$CURRENT_DB/$table_name.meta"

    if [[ -f "$table_file" ]]; then
        read -p "Are you sure you want to delete table '$table_name'? (y/n): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            rm "$DB_DIR/$CURRENT_DB/$table_name.meta"
            rm "$DB_DIR/$CURRENT_DB/$table_name.data"
            echo -e "Table '$table_name' deleted successfully."
        else
            echo -e "Table drop canceled."
        fi
    else
        echo -e "Error: Table '$table_name' does not exist."
    fi

    pause

}

function insert_into_table() {
    echo "============= Insert into a Table ========="

    tables=$(find "$DB_DIR/$CURRENT_DB" -name "*.meta" | awk -F'/' '{print $NF}' | sed "s/\.meta$//")

    if [[ -z "$tables" ]]; then
        echo "The database is empty."
    fi
    echo "Tables in $CURRENT_DB database are: "
    echo "$tables" | nl

    local table_name
    read -p "Enter table name: " table_name

    local metadata_file="$DB_DIR/$CURRENT_DB/$table_name.meta"
    local data_file="$DB_DIR/$CURRENT_DB/$table_name.data"

    if [[ ! -f "$metadata_file" || ! -f "$data_file" ]]; then
        echo "Error: Table $table_name doesn't exist!"
        return 1
    fi

    mapfile -t columns < <(cut -d: -f 1 "$metadata_file")
    mapfile -t types < <(cut -d: -f 2 "$metadata_file")

    echo "${columns[@]}"
    echo "${types[@]}"

    local PK_column=$(awk -F: '/:primary_key$/ {print $1}' "$metadata_file")

    declare -a values
    for ((i = 0; i < ${#columns[@]}; i++)); do
        local col_name="${columns[i]}"
        local col_type="${types[i]}"

        while true; do
            read -p "Enter value for $col_name ($col_type): " value
            if [[ "$col_name" == "$PK_column" ]]; then
                if grep -q "^$value:" "$data_file"; then
                    echo "Error: Primary key $value already exists!"
                    continue
                fi
            fi

            if [[ "$col_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "Error: '$col_name' must be an integer!"
                continue
            fi

            if [[ "$col_type" == "string" && "$value" =~ [:] ]]; then
                echo "Error: '$col_name' cannot contain ':'!"
                continue
            fi

            values+=("$value")
            break
        done
    done

    printf "%s\n" "$(
        IFS=:
        echo "${values[*]}"
    )" >>"$data_file"
    echo "Data inserted successfully into '$table_name'."

    pause
}

function select_from_table {
    local table_name
    local desired_cols=()
    local filter_col_name=""
    local filter_val=""
    local filter_col_index=""
    read -p "Enter table name to select from: " table_name

    local metadata_file="$DB_DIR/$CURRENT_DB/$table_name.meta"
    local data_file="$DB_DIR/$CURRENT_DB/$table_name.data"
    if [[ ! -f "$metadata_file" || ! -f "$data_file" ]]; then
        echo "Error: Table '$table_name' does not exist!"
        return 1
    fi

    local header
    header=$(head -n 1 "$data_file")
    IFS=':' read -ra fields <<<"$header"
    unset IFS
    # mapfile -t -d: fields <<<"$header"

    echo "Available columns: "
    head -n 1 "$data_file" | tr ":" " "

    read -p "Do you want to retrive all the data 
            1. All 
            2. Choose sepcific columns 
            " proj_input

    if [[ "$proj_input" == 1 ]]; then
        desired_cols="${fields[*]}"
    elif [[ "$proj_input" == 2 ]]; then
        while true; do
            echo "Enter column names to retrieve (separated by ','): "
            read -r user_input
            IFS="," read -ra desired_cols <<<"$user_input"
            unset IFS

            invalid_columns=()
            for col in "${desired_cols[@]}"; do
                if [[ ! "${fields[*]}" =~ $col ]]; then
                    invalid_columns+=("$col")
                fi
            done

            if [[ ${#invalid_columns[@]} -eq 0 ]]; then
                break
            else
                echo "Error: The following columns do not exist in the table: ${invalid_columns[*]}"
                echo "Please enter valid column names."
            fi
        done

    fi

    read -p "Do you want to filter rows based on a column value? (y/n): " filter_choice
    if [[ "$filter_choice" =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter the column name to filter on: " filter_col_name

            if echo "${fields[@]}" | grep -wq "$filter_col_name"; then
                read -p "Enter the filter value: " filter_val
                break
            else
                echo "Error: Column '$filter_col_name' not found in the table!"
                continue
            fi
        done
    fi

    declare -A columns_dict

    count=1
    for field in "${fields[@]}"; do
        if echo "${desired_cols[@]}" | grep -wq "$field"; then
            columns_dict[$field]=$count
        fi
        # if [[ -n "$filter_col_name" && "$filter_col_name" == "$field" ]]; then
        #     filter_col_index=$count
        #     echo "$filter_col_name fcn $field fi $count count"
        # fi
        if [[ -n "$filter_col_name" ]]; then
            echo "filter_col_name is not empty: $filter_col_name"
            if [[ "$filter_col_name" == "$field" ]]; then
                echo "Match found: $filter_col_name equals $field"
                filter_col_index=$count
                echo "Assigned filter_col_index: $filter_col_index (count: $count)"
            else
                echo "No match: $filter_col_name does not equal $field"
                echo "Length of filter_col_name: ${#filter_col_name}"
                echo "Length of field: ${#field}"
            fi
        else
            echo "filter_col_name is empty"
        fi
        ((++count))
    done

    values_array=("${columns_dict[@]}")
    #sorted_columns_nums=$(printf "%s\n" "${values_array[@]}" | sort -n)
    sorted_columns_nums=$(sort -n <<<"${values_array[@]}")
    serialized_array=$(
        IFS=" "
        echo "${sorted_columns_nums[*]}"
    )

    echo "filter index $filter_col_index and fv $filter_val"

    awk -v columns_indexes="$serialized_array" -v filter_col_index="$filter_col_index" -v filter_val="$filter_val" -f ./awk/select_script.awk "$data_file"
    pause
}

function update_table() {
    local table_name
    local target_column_number
    local target_column
    declare -A typesMap
    read -p "Enter table name to update: " table_name

    local metadata_file="$DB_DIR/$CURRENT_DB/$table_name.meta"
    local data_file="$DB_DIR/$CURRENT_DB/$table_name.data"

    if [[ ! -f "$metadata_file" || ! -f "$data_file" ]]; then
        echo "Error: Table '$table_name' does not exist!"
        return 1
    fi

    local header
    header=$(head -n 1 "$data_file")
    IFS=":" read -a columns <<<"$header"
    #colums: id name phone address
    # for col in "${columns[@]}"; do
    #     typesMap["$col"]= awk -F: '{}'
    # done
    local pk_col
    local pk_val
    pk_col=$(grep ":primary_key" "$metadata_file" | cut -d: -f 1)
    local col_index
    col_index=$(awk -F':' -v pk_col="$pk_col" '{ for (i=1; i<=NF; i++) if ($i == pk_col) print i; }' <<<"$header")

    pause
}
