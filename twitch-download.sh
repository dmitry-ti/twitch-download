#!/bin/bash

STATUS_OK=0
STATUS_ERROR=1

OUTPUT_FILENAME="all.ts"

################################################################################

main() {
    if [ $# != 1 ] ; then
        echo "Error: Wrong arguments amount!"
        echo "Usage: twitch-download.sh <mu3 url>"
        exit $STATUS_ERROR
    fi

    local m3u_url="$1"

    echo "Downloading m3u file..."
    download_m3u_file "$m3u_url"

    local m3u_file=$(get_filename_from_url "$m3u_url")

    echo "Validating m3u file..."
    validate_m3u_file "$m3u_file"

    local base_url=$(get_base_url "$m3u_url")

    echo "Downloading chunks..."
    download_chunks "$m3u_file" "$base_url"

    local output_file="$OUTPUT_FILENAME"

    echo "Writing to output file..."
    write_output_file "$m3u_file" "$output_file"
}

download_m3u_file() {
    if [ $# != 1 ] ; then
        echo "Error: Expected m3u url, but was: $@"
        exit $STATUS_ERROR
    fi

    local m3u_url="$1"

    wget -c "$m3u_url"

    if [ $? != 0 ] ; then
        echo "Error: Could not download m3u file: $m3u_url"
        exit $STATUS_ERROR
    fi
}

validate_m3u_file() {
    if [ $# != 1 ] ; then
        echo "Error: Expected m3u filename, but was: $@"
        exit $STATUS_ERROR
    fi

    local m3u_file="$1"

    if [ ! -f "$m3u_file" ] ; then
        echo "Error: Could not find m3u file: $m3u_file"
        exit $STATUS_ERROR
    fi

    local header=$(head -n 1 "$m3u_file")

    if [ "$header" != "#EXTM3U" ] ; then
        echo "Error: m3u file validation failed: $m3u_file"
        exit $STATUS_ERROR
    fi
}

download_chunks() {
    if [ $# != 2 ] ; then
        echo "Error: Expected m3u filename and base url, but was: $@"
        exit $STATUS_ERROR
    fi

    local m3u_file="$1"
    local base_url="$2"

    cat "$m3u_file" | grep -v "^#" | xargs -I "{}" wget -c "$base_url/{}"

    if [ $? != 0 ] ; then
        echo "Error: Could not download chunks from file: $m3u_file and base url: $base_url"
        exit $STATUS_ERROR
    fi
}

write_output_file() {
    if [ $# != 2 ] ; then
        echo "Error: Expected m3u filename and output filename, but was: $@"
        exit $STATUS_ERROR
    fi

    local m3u_file="$1"
    local output_file="$2"

    cat "$m3u_file" | grep -E "^[0-9]+(-muted)?.ts$" | xargs cat > "$output_file"

    if [ $? != 0 ] ; then
        echo "Error: Failed to write data to output file: $output_file"
        exit $STATUS_ERROR
    fi
}

get_base_url() {
    if [ $# != 1 ] ; then
        echo "Error: Expected url as argument, but was: $@"
        exit $STATUS_ERROR
    fi

    local url="$1"
    local base_url="${url%/*}"

    if [ $? != 0 ] ; then
        echo "Error: Could not extract base url: $url"
        exit $STATUS_ERROR
    fi

    echo "$base_url"
}

get_filename_from_url() {
    if [ $# != 1 ] ; then
        echo "Error: Expected url as argument, but was: $@"
        exit $STATUS_ERROR
    fi

    local url="$1"
    local filename="${url##*/}"

    if [ $? != 0 ] ; then
        echo "Error: Could not extract filename from url: $url"
        exit $STATUS_ERROR
    fi

    echo "$filename"
}

################################################################################

main "$@"
