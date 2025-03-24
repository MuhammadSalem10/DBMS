#!/bin/bash

function is_valid_name() {
    if [[ $1 =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 0
    else
        echo "$2 name can only contain letters, numbers, or underscore and should start with a letter and it should NOT contain spaces."
        return 1
    fi
}

function pause() {
    read -p "Press Enter to continue..."
}
