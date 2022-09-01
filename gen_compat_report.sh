#!/usr/bin/bash

usage() {
    echo "${0##*/} [-s SYSTEM] -f FILE -p PATH"
    echo "  -s SYSTEM  Prepend SYSTEM to filename when writing output files"
    echo "  -f FILE    AIX command file"
    echo "  -p PATH    Starting-point"
    exit 1
}


while getopts f:s:p: option; do
    case ${option} in
        s) SYSTEM="$OPTARG"_ ;;
        f) readarray CMD_FILE < "$OPTARG" ;;
        p) readarray -d '' FILES < <(find $OPTARG -type f -print0) ;;
        ?) usage ;;
    esac
done

shift "$(( OPTIND -1 ))"


if [ -z "$CMD_FILE" ] || [ -z "$FILES" ]; then
        usage
        exit 1
fi

# output filenames
unsupported_out=${SYSTEM}unsupported_scripts.csv
supported_out=${SYSTEM}supported_scripts.csv

:> $unsupported_out
:> $supported_out


for file in "${FILES[@]}"; do

    unsupported_cmd=
    for cmd in ${CMD_FILE[@]}; do
        # ignore commented lines
        if [[ $( sed '/^#/d' $file | grep $cmd ) ]]; then
            if [[ ! ${unsupported_cmd} ]]; then
                # prepend multiline cell with quotation mark
                printf "${file},\"" >> $unsupported_out
            fi
            echo -e "$cmd" >> $unsupported_out
            unsupported_cmd=true
        fi
    done

    if [[ ${unsupported_cmd} ]]; then
        # append quotation mark to close multiline cell
        sed -i '$ s/$/"/' $unsupported_out
    fi

    if [[ ! ${unsupported_cmd} ]]; then
        echo "$file" >> $supported_out
    fi
done
