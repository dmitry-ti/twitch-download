#!/bin/bash

CLIENT_ID="jzkbprff40iqj646a697cyrvl0zt2m6"
OUTPUT_PLAYLIST="output.m3u8"

getAccess() {
  local channel="$1"
  local clientId="$2"
  curl "https://api.twitch.tv/api/channels/$channel/access_token?client_id=$clientId" 2> /dev/null
}

getMasterPlaylist() {
  local channel="$1"
  local token="$2"
  local sig="$3"
  curl -G --data-urlencode "token=$token" "https://usher.ttvnw.net/api/channel/hls/$channel.m3u8?sig=$sig&allow_source=true" 2> /dev/null
}

getJSONField() {
  local json="$1"
  local fieldName="$2"
  echo "$json" | jq -r ".$fieldName"
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
  if grep "^$segmentNumber.ts$" "$outputDir/$OUTPUT_PLAYLIST" &> /dev/null; then
    return
  fi

  local outputDir="$3"
  local segmentOutputName="$segmentNumber.ts"
  echo "downloading segment $segmentOutputName"
  local segmentUrl="$2"
  wget -O "$outputDir/$segmentOutputName" "$segmentUrl" &> /dev/null
  echo "$segmentOutputName" >> "$outputDir/$OUTPUT_PLAYLIST"
}

main() {
  local channel="$1"
  if [ -z "$channel" ]; then
    echo "Error: channel name must be provided"
    return
  fi

  local outputDir
  outputDir="${channel}_$(date +%Y-%m-%d_%H-%M-%S)"
  mkdir "$outputDir"
  if [ $? -ne 0 ] ; then
    echo "Error: could not create output directory: $outputDir"
    return
  fi

  local masterPlaylist
  local mediaPlaylistUrl
  local mediaPlaylist
  local targetDuration
  local mediaSequence
  local access
  local token
  local sig

  access=$(getAccess "$channel" "$CLIENT_ID")
  token=$(getJSONField "$access" "token")
  sig=$(getJSONField "$access" "sig")

  masterPlaylist=$(getMasterPlaylist "$channel" "$token" "$sig")
  mediaPlaylistUrl=$(getMediaPlaylistUrl "$masterPlaylist")
  if [ -z "$mediaPlaylistUrl" ]; then
    echo "Error: Could not get media playlist url"
    return
  fi

  while true
  do
    mediaPlaylist=$(getMediaPlaylist "$mediaPlaylistUrl")
    targetDuration=$(getPlaylistTag "$mediaPlaylist" "EXT-X-TARGETDURATION")
    mediaSequence=$(getPlaylistTag "$mediaPlaylist" "EXT-X-MEDIA-SEQUENCE")
    if [ -z "$mediaSequence" ]; then
      echo "Error: Could not get media sequence"
      return
    fi

    echo "$mediaPlaylist" | grep -v "^#" | while IFS= read -r segmentUrl ; do processMediaSegment "$((mediaSequence++))" "$segmentUrl" "$outputDir"; done
    
    sleep "$targetDuration"
  done
}

main "$@"
