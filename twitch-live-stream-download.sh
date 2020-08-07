#!/bin/bash

CLIENT_ID="kimne78kx3ncx6brgo4mv6wki5h1ko"
SEGMENTS=("test")

getAccess() {
  local channel="$1"
  curl "https://api.twitch.tv/api/channels/$channel/access_token?oauth_token=undefined&need_https=true&platform=_&player_type=site&player_backend=mediaplayer" -H "Client-ID: $CLIENT_ID" 2>/dev/null
}

getMasterPlaylist() {
  local channel="$1"
  local token="$2"
  local sig="$3"
  curl -G --data-urlencode "token=$token" "https://usher.ttvnw.net/api/channel/hls/$channel.m3u8?sig=$sig&allow_source=true" 2>/dev/null
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

rememberSegmentNumber() {
  local segmentNumber="$1"
  SEGMENTS+=("$segmentNumber")
}

isKnownSegmentNumber() {
  local segmentNumber="$1"
  
  for seg in "${SEGMENTS[@]}"
  do
    echo "segmentNumber: $segmentNumber, seg: $seg"
    if [[ $seg == "$segmentNumber" ]]; then
      echo "true"
      return
    fi
  done
  echo "false"
}

processMediaSegment() {
  local segmentNumber="$1"
  
  isKnownSegmentNumber "$segmentNumber"
  
  #if [[ $(isKnownSegmentNumber "$segmentNumber") == "true" ]]; then
  #  echo "skipping segment $segmentNumber"
  #  return
  #fi

  rememberSegmentNumber "$segmentNumber"
  local segmentUrl="$2"
  local segmentOutputName="$segmentNumber.ts"
  #wget -O "$segmentOutputName" "$segmentUrl"
  echo "$segmentOutputName" >> output.m3u8
}

main() {
  local channel="$1"
  local access=$(getAccess "$channel")
  local token=$(echo "$access" | jq -r ".token")
  local sig=$(echo "$access" | jq -r ".sig")
  local masterPlaylist=$(getMasterPlaylist "$channel" "$token" "$sig")
  local mediaPlaylistUrl=$(getMediaPlaylistUrl "$masterPlaylist")
  
  while true
  do
    echo "Processing next media playlist"
    for seg in "${SEGMENTS[@]}"
    do
      echo "segmentNumber: $seg"
    done
    local mediaPlaylist=$(getMediaPlaylist $mediaPlaylistUrl)
    local targetDuration=$(getPlaylistTag "$mediaPlaylist" "EXT-X-TARGETDURATION")
    local mediaSequence=$(getPlaylistTag "$mediaPlaylist" "EXT-X-MEDIA-SEQUENCE")
    echo "$mediaPlaylist" | grep -v "^#" | while IFS= read -r segmentUrl ; do processMediaSegment "$((mediaSequence++))" "$segmentUrl"; done
    
    echo "Waiting for $targetDuration seconds..."
    sleep "$targetDuration"
  done
}

main "$@"
