#!/bin/bash

CLIENT_ID="jzkbprff40iqj646a697cyrvl0zt2m6"
OUTPUT_PLAYLIST="output.m3u8"

getAccess() {
  local channel="$1"
  curl "https://api.twitch.tv/api/channels/$channel/access_token?client_id=$CLIENT_ID" 2> /dev/null
}

getMasterPlaylist() {
  local channel="$1"
  local access
  local token
  local sig
  access=$(getAccess "$channel")
  token=$(echo "$access" | jq -r ".token")
  sig=$(echo "$access" | jq -r ".sig")
  curl -G --data-urlencode "token=$token" "https://usher.ttvnw.net/api/channel/hls/$channel.m3u8?sig=$sig&allow_source=true" 2> /dev/null
}

getMediaPlaylistUrl() {
  local masterPlaylist="$1"
  echo "$masterPlaylist" | grep -E "^https?:\/\/(www\.)?.*\.m3u8$" | head -n 1
}

getMediaPlaylist() {
  local mediaPlaylistUrl="$1"
  curl "$mediaPlaylistUrl" 2>/dev/null
}

getPlaylistTag() {
  local mediaPlaylist="$1"
  local tag="$2"
  echo "$mediaPlaylist" | sed -n "s/#$tag://p"
}

processMediaSegment() {
  local segmentNumber="$1"
  #echo "processing segment #$segmentNumber"
  if grep "^$segmentNumber.ts$" "$OUTPUT_PLAYLIST" &> /dev/null; then
    #echo "skipped (reason: found in $OUTPUT_PLAYLIST)"
    return
  fi

  local segmentUrl="$2"
  #echo "segment url: $segmentUrl"
  local segmentOutputName="$segmentNumber.ts"
  echo "downloading segment $segmentOutputName"
  wget -O "$segmentOutputName" "$segmentUrl" > /dev/null
  echo "$segmentOutputName" >> "output.m3u8"
}

main() {
  local channel="$1"
  local access
  local token
  local masterPlaylist
  local mediaPlaylistUrl
  local mediaPlaylist
  local targetDuration
  local mediaSequence

  masterPlaylist=$(getMasterPlaylist "$channel")
  mediaPlaylistUrl=$(getMediaPlaylistUrl "$masterPlaylist")

  while true
  do
    #echo "Processing next media playlist"

    mediaPlaylist=$(getMediaPlaylist "$mediaPlaylistUrl")
    targetDuration=$(getPlaylistTag "$mediaPlaylist" "EXT-X-TARGETDURATION")
    mediaSequence=$(getPlaylistTag "$mediaPlaylist" "EXT-X-MEDIA-SEQUENCE")

    echo "$mediaPlaylist" | grep -v "^#" | while IFS= read -r segmentUrl ; do processMediaSegment "$((mediaSequence++))" "$segmentUrl"; done
    
    #echo "Waiting for $targetDuration seconds..."
    sleep "$targetDuration"
  done
}

main "$@"
