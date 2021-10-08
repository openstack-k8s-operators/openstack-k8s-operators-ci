# LABEL with OSBS specific fields in bundle.Dockerfile should be
# just above line:
#  "# Copy files to locations specified by labels."
function pre_template() {
    local input_dockerfile=$1
    tags=$(grep -e "$TEMPLATE_TAG_START" -e "$TEMPLATE_TAG_END" "${input_dockerfile}")
    if [ $(echo "$tags"|wc -l) -ne 2 ]; then
        echo "Insert tags to the osp-operator-bundle Dockerfile: ${input_dockerfile}"
        OUTFILE=$(mktemp)
        awk -v start="$TEMPLATE_TAG_START" -v end="$TEMPLATE_TAG_END" 'NR == FNR {
	      if ($0 ~ /# Copy files to locations specified by labels./)
		        p=FNR-1
		        next
        }1
        FNR == p {
          printf "%s\n%s\n\n",start,end
        }' "$input_dockerfile" "$input_dockerfile" > "$OUTFILE"
        mv "$OUTFILE" "$input_dockerfile"
    fi
}
