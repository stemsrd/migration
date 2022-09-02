#!/usr/bin/bash

# TODO
# make more generic, i.e. tag, filenames, vars

# add command line example
usage() {
    echo "Usage: ${0##*/} [-s SYSTEM] -f FILE PATH ..."
    echo "  -t, --tag=TAG     Prefix TAG to filename when writing output files"
    echo "  -f FILE    AIX command file"
    echo "  -e EXPR    Only match filenames that match EXPR"
    exit 1
}

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

# add support for long options
# add support for file extension (*.ksh) (find ./ -name "*.ksh"
while getopts t:f:e:-: OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
        OPT="${OPTARG%%=*}"       # extract long option name
        OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
        OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi
    case ${OPT} in
        t | tag )    TAG="$OPTARG"_ ;;

        f | file )   CMD_FILE=$OPTARG ;;

        e | expr )   EXPR=${OPTARG} ;;

        ??* )          die "Illegal option --$OPT" ;;  # bad long option

        ?) usage ;;
    esac
done

shift "$(( OPTIND -1 ))"

_PATH="$@"

#echo $_PATH
#echo $EXT

if [ -z "$CMD_FILE" ] || [ -z "$_PATH" ]; then
        usage
        exit 1
fi

# add check to see cmd_file exists and is not empty
#if [[ -s $CMD_FILE ]]; then
#    usage
#    exit 1
#fi

# add check to see that $@ is -ne 0
#if [[ $# -eq 0 ]]; then
#    usage
#    exit 1
#fi

# make generic , i.e. NO_MATCH_CSV
# output filenames
unsupported_out=${TAG}unsupported.csv
supported_out=${TAG}supported.csv

:> $unsupported_out
:> $supported_out

if [ -z "$EXPR" ]; then
    EXPR='*'
fi

#echo ${NAME}

# change to "for file in $(find $[@]..." (we are not using an array)
# note that we want to support multiple paths and wildcards
        #p) readarray -d '' FILES < <(find $OPTARG -type f -print0) ;;
#for file in "$(find testdir -type f -print0)"; do
#echo "find $_PATH ${NAME} -type f -print0"
find $_PATH -name "${EXPR}" -type f -print0 | while read -d $'\0' file; do

    # change to match=
    unsupported_cmd=

    # change to "for cmd in $(< $cmd_file); do"
#    for cmd in $(< $CMD_FILE); do
    while read cmd; do
        # ignore commented lines
        # add optional whitespace or tab before comment
        if [[ $( sed '/^\s*#/d' $file | grep $cmd ) ]]; then
            if [[ ! ${unsupported_cmd} ]]; then
                # prepend quotation mark to multi-line field
                printf "${file},\"" >> $unsupported_out
            fi
            # whats the purpose of -e?
            echo "$cmd" >> $unsupported_out
            unsupported_cmd=true
        fi
    done < "$CMD_FILE"

    if [[ ${unsupported_cmd} ]]; then
        # append quotation mark to end multiline field
        sed -i '$ s/$/"/' $unsupported_out
    fi

    if [[ ! ${unsupported_cmd} ]]; then
        echo "$file" >> $supported_out
    fi
done
