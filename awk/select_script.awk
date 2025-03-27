#!/usr/bin/awk -f

BEGIN {
    FS = ":"                  # Input field separator
    OFS = " | "               # Output field separator
    n = split(columns_indexes, selected_cols, " ")  # Get selected column indexes into an array
}

{
    # Skip any empty lines
    if ($0 ~ /^[[:space:]]*$/) next

    # If filtering is enabled, skip rows that don't match the filter value.
    if (filter_col_index != "" && $filter_col_index != filter_val)
        next

    # Build the output string using the selected columns.
    output = ""
    for (i = 1; i <= n; i++) {
        # selected_cols[i] holds the numeric column index to print.
        if (i == 1)
            output = $(selected_cols[i])
        else
            output = output OFS $(selected_cols[i])
    }
    print output
}
