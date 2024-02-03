#!/bin/bash

# Function to print a centered header
print_centered_header() {
    local header="$1"
    local length=${#header}
    local total_length=60  # Adjust this value for desired header width

    # Calculate the number of equal signs before and after the header
    local equal_signs_length=$(( (total_length - length) / 2 ))

    # Construct the header
    local header_line="/// $(printf '=%.0s' $(seq 1 $equal_signs_length)) $header $(printf '=%.0s' $(seq 1 $equal_signs_length)) ///"

    # Print the header
    echo "$header_line"
}

# Check if a header argument is provided
if [ $# -eq 1 ]; then
    header_variable="$1"
    print_centered_header "$header_variable"
else
    echo "Usage: $0 <header>"
fi

# ./scripts/header.sh "DELEGATE SETTINGS"