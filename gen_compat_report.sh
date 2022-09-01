#!/usr/bin/bash

# TODO
# make more generic, i.e. tag, filenames, vars

# add command line example
usage() {
    echo "${0##*/} [-s SYSTEM] -f FILE -p PATH"
    echo "  -s SYSTEM  Prepend SYSTEM to filename when writing output files"
    echo "  -f FILE    AIX command file"
    echo "  -p PATH    Starting-point"
    exit 1
}


# add support for long options
# add support for file extension (*.ksh) (find ./ -name "*.ksh"
while getopts f:s:p: option; do
    case ${option} in
        s) SYSTEM="$OPTARG"_ ;;
        
        # only declare
        f) readarray CMD_FILE < "$OPTARG" ;;
        
        # only declare var and do find later
        # maybe move this out of positional args and use as $[@]
        p) readarray -d '' FILES < <(find $OPTARG -type f -print0) ;;
        ?) usage ;;
    esac
done

shift "$(( OPTIND -1 ))"


if [ -z "$CMD_FILE" ] || [ -z "$FILES" ]; then
        usage
        exit 1
fi

# add check to see cmd_file exists and is not empty
# add check to see that $@ is -ne 0


# make generic , i.e. NO_MATCH_CSV
# output filenames
unsupported_out=${SYSTEM}unsupported_scripts.csv
supported_out=${SYSTEM}supported_scripts.csv

:> $unsupported_out
:> $supported_out


# change to "for file in $(find $[@]..." (we are not using an array)
# note that we want to support multiple paths and wildcards
for file in "${FILES[@]}"; do

    # change to match=
    unsupported_cmd=
    
    # change to "for cmd in $(< $cmd_file); do"
    for cmd in ${CMD_FILE[@]}; do
        # ignore commented lines
        # add optional whitespace or tab before comment
        if [[ $( sed '/^#/d' $file | grep $cmd ) ]]; then
            if [[ ! ${unsupported_cmd} ]]; then
                # prepend quotation mark to multi-line field
                printf "${file},\"" >> $unsupported_out
            fi
            # whats the purpose of -e?
            echo -e "$cmd" >> $unsupported_out
            unsupported_cmd=true
        fi
    done

    if [[ ${unsupported_cmd} ]]; then
        # append quotation mark to end multiline field
        sed -i '$ s/$/"/' $unsupported_out
    fi

    if [[ ! ${unsupported_cmd} ]]; then
        echo "$file" >> $supported_out
    fi
done
