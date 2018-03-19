#!/bin/bash

STATUS_OK=0
STATUS_ERROR=1

M3U_FILENAME="chunks.m3u"

################################################################################

main() {
    if [ $# != 1 ] ; then
        echo "Error: Wrong arguments amount!"
        echo "Usage: twitch-download.sh <mu3 url>"
        exit $STATUS_ERROR
    fi

    local m3u_url="$1"
    local base_url=$(get_base_url $m3u_url)
    local m3u_file="$M3U_FILENAME"

    echo "Downloading m3u file..."
    download_m3u_file "$m3u_url" "$m3u_file"
    echo "Downloading chunks..."
    download_chunks "$m3u_file" "$base_url"
}

download_m3u_file() {
    if [ $# != 2 ] ; then
        echo "Error: Expected m3u url and filename, but was: $@"
        return $STATUS_ERROR
    fi

    local m3u_url="$1"
    local m3u_file="$2"

    wget -N -O "$m3u_file" "$m3u_url"

    if [ $? != 0 ] ; then
        echo "Error: Could not download m3u file: $m3u_url"
        exit $STATUS_ERROR
    fi

    if [ ! -f "$m3u_file" ]; then
        echo "Error: Could not find downloaded m3u file: $m3u_file"
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

    cat "$m3u_file" | grep -E "^[0-9]+(-muted)?.ts$" | xargs -N -I "{}" wget "$base_url/{}"
}

get_base_url() {
    if [ $# != 1 ] ; then
        echo "Error: Expected url as argument, but was: $@"
        return $STATUS_ERROR
    fi

    local url="$1"
    local base_url="${url%/*}"

    if [ $? != 0 ] ; then
        echo "Error: Could not extract base url: $url"
        exit $STATUS_ERROR
    fi

    echo "$base_url"
}

################################################################################

main "$@"
exit "$?"
