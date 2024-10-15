#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <path>..."
  exit 1
fi

if ! command -v plantuml 2>&1; then
  echo "error: the 'plantuml' executable is required for formatting"
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
    plantuml -tsvg "$FILE"

    echo "Processed $FILE"
  }

# Iterate over each file provided as an argument
for file in "$@"; do
  process "$file"
done
