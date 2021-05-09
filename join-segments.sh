#!/bin/bash

OUTPUT_FILE="all.ts"

main() {
  local playlist="$1"
  if [ -z "$playlist" ]; then
    echo "Error: playlist filename must be provided"
    return
  fi
  grep "^.*\.ts$" "$playlist" | sort -n | xargs cat > "$OUTPUT_FILE"
}

main "$@"