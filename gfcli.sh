#!/bin/bash
set -uo pipefail

# Configuration
API_BASE="${API_BASE:-https://api.gofile.io}"
USER_AGENT="${USER_AGENT:-Mozilla/5.0}"
GF_TOKEN="${GF_TOKEN:-}"

# Utility functions
log() { printf "%s\n" "$*" >&2; }

check_dependencies() {
  local deps=(curl jq awk du)
  for cmd in "${deps[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || {
      log "Error: Required command '$cmd' not found"
      exit 1
    }
  done
}

sha256hex() {
  printf %s "$1" | sha256sum | awk '{print $1}'
}

# API functions
create_guest_token() {
  [[ -n "$GF_TOKEN" ]] && return 0

  GF_TOKEN=$(curl -sS -X POST "$API_BASE/accounts" \
    -H 'Content-Type: application/json' \
    -d '{}' | jq -r '.data.token // empty' 2>/dev/null)

  if [[ -z "$GF_TOKEN" ]]; then
    log "Error: Failed to create guest token"
    return 1
  fi
}

get_content_info() {
  local content_id="$1"
  local password_hash="${2:-}"
  local url="$API_BASE/contents/$content_id?wt=4fd6sg89d7s6"

  [[ -n "$password_hash" ]] && url+="&password=$password_hash"

  curl -sS -A "$USER_AGENT" \
    -H "Authorization: Bearer $GF_TOKEN" \
    "$url" 2>/dev/null
}

get_upload_server() {
  curl -sS "$API_BASE/servers" \
    | jq -r '.data.servers[0].name // empty'
}

# Download functions
download_file() {
  local output_path="$1"
  local download_link="$2"
  local max_retries=3

  mkdir -p "$(dirname "$output_path")"

  for ((attempt=1; attempt<=max_retries; attempt++)); do
    echo "🕔 Downloading: $output_path (attempt $attempt/$max_retries)"

    if curl -L --progress-bar --fail -C - \
      -A "$USER_AGENT" \
      -H "Authorization: Bearer $GF_TOKEN" \
      -o "$output_path" "$download_link"; then
      
      local file_size
      file_size=$(du -h "$output_path" | awk '{print $1}')
      echo "✅ Downloaded: $output_path ($file_size)"
      return 0
    fi

    [[ $attempt -lt $max_retries ]] && sleep 2
  done

  log "❌ Failed to download after $max_retries attempts: $output_path"
  return 1
}

download_content() {
  local base_path="$1"
  local content_id="$2"
  local password_hash="${3:-}"

  local response
  response=$(get_content_info "$content_id" "$password_hash")

  if [[ -z "$response" ]]; then
    log "⚠️  Empty response for content ID: $content_id"
    return 1
  fi

  local status password_status
  status=$(jq -r '.status // empty' <<<"$response")
  password_status=$(jq -r '.data.passwordStatus // "passwordOk"' <<<"$response")

  if [[ "$status" != "ok" ]]; then
    log "⚠️  API error: $(jq -r '.message // "Unknown error"' <<<"$response")"
    return 1
  fi

  if [[ "$password_status" != "passwordOk" ]]; then
    log "⚠️  Invalid or missing password for content ID: $content_id"
    return 1
  fi

  local content_type content_name
  content_type=$(jq -r '.data.type' <<<"$response")
  content_name=$(jq -r '.data.name' <<<"$response")

  if [[ "$content_type" == "file" ]]; then
    local download_link
    download_link=$(jq -r '.data.link' <<<"$response")
    echo "📄 File: $content_name"
    download_file "$base_path/$content_name" "$download_link"
    return
  fi

  # Handle folder
  local folder_path="$base_path/$content_name"
  mkdir -p "$folder_path"
  echo "📁 Folder: $content_name"

  jq -c '.data.children | to_entries[]' <<<"$response" 2>/dev/null | while IFS= read -r entry; do
    local child_type child_id child_name child_link
    child_type=$(jq -r '.value.type' <<<"$entry")
    child_id=$(jq -r '.value.id' <<<"$entry")
    child_name=$(jq -r '.value.name' <<<"$entry")

    if [[ "$child_type" == "folder" ]]; then
      download_content "$folder_path" "$child_id" "$password_hash"
    else
      child_link=$(jq -r '.value.link' <<<"$entry")
      echo "📥 File: $child_name"
      download_file "$folder_path/$child_name" "$child_link"
    fi
  done
}

# Upload function
upload_file() {
  local file_path="$1"
  local max_retries=3

  if [[ ! -f "$file_path" ]]; then
    log "❌ File not found: $file_path"
    return 1
  fi

  local server
  server=$(get_upload_server)

  if [[ -z "$server" ]]; then
    log "❌ Failed to get upload server"
    return 1
  fi

  local file_size
  file_size=$(du -h "$file_path" | awk '{print $1}')

  for ((attempt=1; attempt<=max_retries; attempt++)); do
    echo "🚀 Uploading: $file_path ($file_size) → server: $server (attempt $attempt/$max_retries)"

    local temp_file
    temp_file=$(mktemp)

    curl --progress-bar -A "$USER_AGENT" \
      -H "Authorization: Bearer $GF_TOKEN" \
      -F "file=@${file_path}" \
      -o "$temp_file" \
      "https://${server}.gofile.io/uploadFile"

    local response
    response=$(cat "$temp_file")
    rm -f "$temp_file"

    local status
    status=$(jq -r '.status // empty' <<<"$response" 2>/dev/null)

    if [[ "$status" == "ok" ]]; then
      local download_link
      download_link=$(jq -r '.data.downloadPage' <<<"$response")

      echo "✅ Upload complete: $file_path ($file_size)"
      echo "🔗 Download link: $download_link"
      return 0
    fi

    local error_msg
    error_msg=$(jq -r '.message // "Unknown error"' <<<"$response" 2>/dev/null)
    log "⚠️  Upload failed: $error_msg"

    [[ $attempt -lt $max_retries ]] && sleep 2
  done

  log "❌ Failed to upload after $max_retries attempts: $file_path"
  return 1
}

# Menu functions
menu_download() {
  read -rp "Enter Gofile URL (https://gofile.io/d/<ID>): " url
  read -rsp "Password (press Enter if none): " password
  echo

  local content_id
  content_id=$(awk -F'/d/' '{print $2}' <<<"$url" | cut -d/ -f1)

  if [[ -z "$content_id" ]]; then
    log "Invalid URL format"
    return 1
  fi

  local password_hash=""
  [[ -n "$password" ]] && password_hash=$(sha256hex "$password")

  create_guest_token || return 1

  local output_dir="$PWD/$content_id"
  echo "Downloading to: $output_dir"

  download_content "$PWD" "$content_id" "$password_hash" || \
    log "Download completed with some errors"

  echo "✅ Completed, check your file here → $output_dir/*"
}

menu_upload() {
  echo -n "Enter file path to upload: "
  read -e -r file_path

  create_guest_token || return 1
  upload_file "$file_path"
}

show_banner() {
  cat << 'EOF'

  ____       _____ _ _        ____ _     ___ 
 / ___| ___ |  ___(_) | ___  / ___| |   |_ _|
| |  _ / _ \| |_  | | |/ _ \| |   | |    | | 
| |_| | (_) |  _| | | |  __/| |___| |___ | | 
 \____|\___/|_|   |_|_|\___| \____|_____|___|

by officialputuid

EOF
}

# Check for inline commands
if [[ "$#" -gt 0 ]]; then
  case "$1" in
    -u)
      if [[ -z "$2" ]]; then
        echo "Usage: gfcli -u <file_path>"
        exit 1
      fi
      create_guest_token || exit 1
      show_banner
      upload_file "$2"
      exit
      ;;
    -d)
      if [[ -z "$2" ]]; then
        echo "Usage: gfcli -d <full_link_or_content_id> [password]"
        exit 1
      fi
      create_guest_token || exit 1
      show_banner

      if [[ "$2" =~ https?:// ]]; then
        content_id=$(awk -F'/d/' '{print $2}' <<<"$2" | cut -d/ -f1)
      else
        content_id="$2"
      fi

      if [[ -z "$content_id" ]]; then
        echo "Invalid content ID or link."
        exit 1
      fi

      password_hash=""
      if [[ ${3-} != "" ]]; then
        password_hash=$(sha256hex "$3")
      fi

      download_content "$PWD" "$content_id" "$password_hash" || echo "Download completed with some errors"
      exit
      ;;
  esac
fi

# Main program
main() {
  check_dependencies

  while true; do
    show_banner
    echo "1) Download"
    echo "2) Upload"
    echo "3) Exit"
    read -rp "Choose [1/2/3]: " choice

    case "${choice}" in
      1) menu_download ;;
      2) menu_upload ;;
      3) echo "Goodbye!"; break ;;
      *) log "Invalid choice" ;;
    esac
  done
}

main
