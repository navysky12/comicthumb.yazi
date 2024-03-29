#!/bin/bash

CBZ_FILE="$1"; shift

[ ! -f "$CBZ_FILE" ] && echo "CBZ file does not exist: $CBZ_FILE" && exit 1

FIRST_IMAGE=$(7z -ba l "$CBZ_FILE" \
    | awk 'tolower($0) ~ /\.(jpg|jpeg|png|gif)$/ {print substr($0, index($0,$6))}' \
    | sort \
    | head -n 1) &>/dev/null

[ -z "$FIRST_IMAGE" ] && echo "No images found in the CBZ file." && exit 1

7z e "$CBZ_FILE" "$FIRST_IMAGE" "$@"

