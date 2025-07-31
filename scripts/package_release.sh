#!/bin/bash
set -e
OUTPUT=${1:-SmartDeal_release.zip}
TMP_DIR=$(mktemp -d)
OUTPUT_PATH="$PWD/$OUTPUT"

# copy server functions
cp -r functions "$TMP_DIR/"
# copy iOS source directories
cp -r Application Controllers Common Resources "$TMP_DIR/"

# gather documentation PDFs if any
mkdir -p "$TMP_DIR/Documentation"
shopt -s nullglob
for pdf in Documentation/*.pdf *.pdf; do
  cp "$pdf" "$TMP_DIR/Documentation/" 2>/dev/null || true
done
shopt -u nullglob

( cd "$TMP_DIR" && zip -r "$OUTPUT_PATH" . )
rm -rf "$TMP_DIR"

echo "Release package created: $OUTPUT_PATH"
