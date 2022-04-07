#!/bin/bash

# Description:      Shell script to perform CRUD operations on the cosmos DB
# Parameters:
#   connStr:        the cmdb connection string
#   collection:     which collection to modify or read from
#   id:             id of the object to read, create, or modify
#   crud:           one of [ create, read, update, delete ]
#   updates:        set of key value pairs to update or include in creation

# Assign the options to variables
ARGS=$(getopt -a -n modify_cmdb --options s:c:i:o:u: --long "connStr:,collection:,id:,crud:,updates:" -- "$@")
VALID_ARGUMENTS=$?
if [ "${VALID_ARGUMENTS}" != 0 ]; then
    exit 1
fi

eval set -- "$ARGS"
while true; do
    case "$1" in
        -s | --connStr)       
            connStr="$2"
            if [ ${connStr::1} == "-" ]; then
                echo "ERROR: option '$1' requires an argument"
                exit 1
            fi
            shift 2 
            ;;
        -c | --collection)
            collection="$2"
            if [ ${collection::1} == "-" ]; then
                echo "ERROR: option '$1' requires an argument"
                exit 1
            fi
            shift 2 
            ;;
        -i | --id)
            id="$2"
            if [ ${id::1} == "-" ]; then
                echo "ERROR: option '$1' requires an argument"
                exit 1
            fi
            shift 2
            ;;
        -o | --crud)
            crud="$2"
            if [ ${crud::1} == "-" ]; then
                echo "ERROR: option '$1' requires an argument"
                exit 1
            fi
            shift 2
            ;;
        -u | --updates)
            updates="$2"
            if [ ${updates::1} == "-" ]; then
                echo "ERROR: option '$1' requires an argument"
                exit 1
            elif [ ${updates::1} != "{" ]; then
                echo "ERROR: expected JSON string for option '$1'"
                exit 1
            fi
            shift 2 
            ;;
        --)
            break 
            ;;
    esac
done

# Required variable check
params_missing=0
if [ -z "${connStr}" ]; then
    echo "ERROR: the --connStr flag is required"
    params_missing=1
fi
if [ -z "${collection}" ]; then
    echo "ERROR: the --collection flag is required"
    params_missing=1
fi
if [ -z "${id}" ]; then
    echo "ERROR: the --id flag is required"
    params_missing=1
fi
if [ -z "${crud}" ]; then
    echo "ERROR: the --crud flag is required"
    params_missing=1
fi
if [ -z "${updates}" ]; then
    updates="{}"
fi
if [ $params_missing -eq 1 ]; then
    echo "Please try again"
    exit 1
fi

# Get script directory
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

# Convert variables to javascript
echo -e "var connStr = '$connStr'; \nvar collection = '$collection'; \nvar id = '$id'; \nvar crud = '$crud'; \nvar updates = $updates;" > $script_directory/dbvars.js

# Modify or read the database
if [ "${crud}" == "read" ]; then
    mongosh --quiet --nodb -f $script_directory/dbvars.js -f $script_directory/modifyCmdb.js
else
    mongosh --nodb -f $script_directory/dbvars.js -f $script_directory/modifyCmdb.js
fi

# Exit gracefully
return_code=$?
if [ $return_code != 0 ]; then
    echo "FAILURE"
else
    if [ "${crud}" != "read" ]; then
        echo "SUCCESS"
    fi
fi
rm $script_directory/dbvars.js
exit $return_code
