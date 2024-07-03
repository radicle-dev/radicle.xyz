#!/bin/sh
set -e

if [ $# -lt 1 ]; then
  echo "usage: $0 <path>..."
  exit 1
fi

if ! command -v tidy 2>&1; then
  echo "error: the 'tidy' executable is required for formatting"
  exit 1
fi

# Function to process a single file
process() {
    FILE="$1"

    # Ensure the file exists
    if [ ! -f "$FILE" ]; then
      echo "error: '$FILE' does not exist."
      return
    fi

    # Format SVG.
    tidy -xml -i -m -q -w 0 "$FILE"
    # Remove `<?xml>` header, if present.
    sed -i '1{/^<?xml/d;}' "$FILE"

    # Remove all instances of `font-family="..."` and `font-size="..."`
    sed -i -e 's/font-family="[^"]*"//g' -e 's/font-size="16px"//g' "$FILE"
    # Remove comments.
    sed -i -e '/<!--.*-->/d' "$FILE"
    # Replace the contents of <style> tags
    sed -i '/<defs>/,/<\/defs>/c\
  <defs>\
    <style>\
      @import url("/assets/css/fonts.css");\
      svg { font-size: 16px; font-family: "Inter", sans-serif; }\
    </style>\
  </defs>' "$FILE"

    echo "Processed $FILE"
  }

# Iterate over each file provided as an argument
for file in "$@"; do
  process "$file"
done
