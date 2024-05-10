declare -A OSBS_LABELS_TEMPLATE="$(dirname "$0")/osbs_templates/osbs_dockerfile_labels.j2"

function replace_ARG_values() {
    local operator_name=$1
    local input_dockerfile=$2
    local operator_branch=$3
    ENVFILE=$(mktemp --suffix ".env")
    # Always source default.env and default.env from the branch if exists
    # At this point we do not care if the value is specified multiple times as this will be overriden
    # by sourcing this file from shell.

    [ -f "${OSBS_VARS_DIR}/default.env" ] && cat "${OSBS_VARS_DIR}/default.env" > "$ENVFILE"
    [ -f "${OSBS_VARS_DIR}/${operator_name}.env" ] && cat "${OSBS_VARS_DIR}/${operator_name}.env" >> "$ENVFILE"
    if [ ! -z ${operator_branch} ]; then
        [ -f "${OSBS_VARS_DIR}/${operator_branch}/default.env" ] && cat "${OSBS_VARS_DIR}/${operator_name}.env" >> "$ENVFILE"
    [ -f "${OSBS_VARS_DIR}/${operator_branch}/${operator_name}.env" ] && cat "${OSBS_VARS_DIR}/${operator_name}.env" >> "$ENVFILE"
    fi
    echo "Using source file: $ENVFILE"
    source "$ENVFILE"
    for value in $(cat "$ENVFILE"|awk -F "=" '{print $1}'|uniq);
    do
        # Replace all Dockerfile ${ARGNAME} with the value from $ENVFILE
        # Use non priting character $'\001' to ensure it's not in the value
        # sed is preffered over envsubst
        sed -ir s$'\001'\${"$value"}$'\001'"${!value}"$'\001' "$input_dockerfile"

        # Ensure none of the specified arguments is set
        # This is required as Dockerfile ARG must be without = sign
        # when no value is assigned.
        sed -ir "s/a*\s*ARG .*$value=.*/ARG $value/" "$input_dockerfile"

        ARG_STR="ARG ${value}"
        if [ ! -z "${!value}" ]; then
            ARG_STR="${ARG_STR}=\"${!value}\""
            # Set appropriate arguments
            sed -ir s$'\001'"a*\s*ARG .*$value\>"$'\001'"$ARG_STR"$'\001' "$input_dockerfile"
        fi
    done
}

function replace_labels_from_template() {
    local input_dockerfile=$1
    echo "Checking if both tags are present"
    tags=$(grep -e "$TEMPLATE_TAG_START" -e "$TEMPLATE_TAG_END" "${input_dockerfile}")
    if [ $(echo "$tags"|wc -l) -eq 2 ]; then
        OUTFILE=$(mktemp)
        awk -v start="$TEMPLATE_TAG_START" -v end="$TEMPLATE_TAG_END" 'NR==FNR{
            new = new $0 ORS; next
        }
        $0~end{f=0}
        !f{print}
        $0~start{
            printf "%s",new; f=1
        }' "$OSBS_LABELS_TEMPLATE" "$input_dockerfile" > "$OUTFILE"
        mv "$OUTFILE" "$input_dockerfile"
    else
        echo "ERROR: Dockerfile ${input_dockerfile} is not designed to work with this script"
        exit 2
    fi
}

# To be overriden by function for each individual operator
function pre_template() {
    printf "\n${FUNCNAME[ 0 ]} called by ${FUNCNAME[ 1 ]}\n"
}

# To be overriden by function for each individual operator
function post_template() {
    printf "\n${FUNCNAME[ 0 ]} called by ${FUNCNAME[ 1 ]}\n"
}
