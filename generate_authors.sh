#!/bin/bash

# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

authors_list=$(git log --format='%aN <%aE>' | \
    awk '{
        # Convert email to lowercase
        match($0, /<.*>/);
        email = substr($0, RSTART+1, RLENGTH-2);
        email = tolower(email);
        name = substr($0, 1, RSTART-2);
        formatted_entry = name " <" email ">";
        if (!seen[email]++) {
            print formatted_entry;
        }
    }' | \
    sort -u | \
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
    sed -E 's/^([^,]+), ([^<]+) <(.+)>$/\2 \1 <\3>/' | \
    awk '{print "Copyright (c) 2024, " $0}' | \
    awk '{printf "%s\n", $0}')

echo "$authors_list" > $1

