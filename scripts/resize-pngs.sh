#!/bin/sh

set -e

input="$1"
output="${input%.*}.medium.png"

echo "resizing $input -> $output"
convert "$input" -resize 1280x1280 "$output"
pngquant "$output" -o "$output.quant"

mv -f "$output.quant" "$output"

oxipng "$output"
