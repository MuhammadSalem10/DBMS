#!/usr/bin/awk -f

BEGIN {
    FS = ":"
    OFS = " | "
    columns_count = split(columns_indexes, selected_cols, " ")
}

{
    if (filter_col_index != "" && $filter_col_index != filter_val) {
        next
    }

    for (i = 1; i <= columns_count; i++) {
        printf "%s", $selected_cols[i] == 1 ? $selected_cols[i] : OFS $selected_cols[i]
    }
    print ""
}
