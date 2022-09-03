#!/bin/bash
# change to use/bin/bash

# add command line example
usage() {
    echo "Usage: ${0##*/} [-t, --tag=<TAG>] -f, --file=<FILE> PATH [PATH]..."
    echo "  -t, --tag=<TAG>    Prefix TAG to filename when writing output files"
    echo "  -f --file=<FILE>    AIX command file"
    echo "  -n --name=<NAME> Only match filenames that match EXPR"
    exit 1
}

die() {
    echo "$*" >&2;
    exit 2;
}  # complain to STDERR and exit with error

needs_arg() {
    if [ -z "$OPTARG" ]; then
        die "No arg for --$OPT option";
    fi;
}

while getopts t:k:e:-: OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
        OPT="${OPTARG%%=*}"       # extract long option name
        OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
        OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi
    case ${OPT} in
        t | tag )    TAG="${OPTARG}_" ;;
        k | keyfile )   CMD_FILE="${OPTARG}" ;;
        n | name )   name="${OPTARG}" ;;
        ??* )          die "Illegal option --$OPT" ;;  # bad long option
        ?) usage ;;
    esac
done

readonly CMD_FILE
readonly TAG
readonly name

shift "$(( OPTIND -1 ))"

_PATH="$@"


if [ -z "$CMD_FILE" ] || [ -z "$_PATH" ]; then
        usage
        exit 2
fi

#if [[ -s $CMD_FILE ]]; then
#    usage
#    exit 1
#fi

if [[ $# -eq 0 ]]; then
    usage
    exit 2
fi

# make generic , i.e. NO_MATCH_CSV
# output filenames
unsupported_out=${TAG}unsupported.csv
supported_out=${TAG}supported.csv

:> $unsupported_out
:> $supported_out

if [ -z "$EXPR" ]; then
    EXPR='*'
fi


while read -d $'\0' file; do
    unsupported_cmd=
    while read cmd; do
        # ignore commented lines
        if [[ $( sed '/^\s*#/d' $file | grep $cmd ) ]]; then
            if [[ ! ${unsupported_cmd} ]]; then
                # prepend quotation mark to multi-line field
                printf "${file},\"" >> $unsupported_out
            fi
            echo "$cmd" >> $unsupported_out
            unsupported_cmd=true
        fi
    done < "$file"

    if [[ ${unsupported_cmd} ]]; then
        # append quotation mark to end multiline field
        sed -i '$ s/$/"/' $unsupported_out
    fi

    if [[ ! ${unsupported_cmd} ]]; then
        echo "$file" >> $supported_out
    fi
done < <(find $_PATH -name "${name}" -type f -print0)
