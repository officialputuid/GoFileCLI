#!/bin/bash
set -u

API="https://api.gofile.io"
UA="Mozilla/5.0"
QS="wt=4fd6sg89d7s6&cache=true&sortField=createTime&sortDirection=1"
GF_TOKEN="${GF_TOKEN:-}"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need curl; need jq; need sed; need grep; need awk; need sha256sum

log(){ printf "%s\n" "$*" >&2; }

mk_token(){
  [[ -n "$GF_TOKEN" ]] && return 0
  GF_TOKEN="$(curl -sS -X POST "$API/accounts" -H 'Content-Type: application/json' -d '{}' \
    | jq -r 'select(.status=="ok")|.data.token' 2>/dev/null || true)"
  [[ -n "$GF_TOKEN" ]] || { log "Gagal membuat token guest."; return 1; }
}

sha256hex(){ printf %s "$1" | sha256sum | awk '{print $1}'; }

get_json(){
  local cid="$1" passhex="${2:-}"
  local url="$API/contents/$cid?$QS"
  [[ -n "$passhex" ]] && url+="&password=$passhex"
  curl -sS -A "$UA" -H "Authorization: Bearer $GF_TOKEN" "$url" 2>/dev/null || true
}

download_file(){
  local path="$1" link="$2"
  mkdir -p "$(dirname "$path")"
  if curl -L --fail -C - -A "$UA" -o "$path" "$link" 2>/dev/null; then
    echo "OK: $path"
  else
    log "Download gagal: $path"
  fi
}

traverse_download(){
  local root="$1" id="$2" passhex="${3:-}"
  local j; j="$(get_json "$id" "$passhex")"
  [[ -n "$j" ]] || { log "Fetch gagal: $id"; return 1; }
  local st; st="$(jq -r '.status' <<<"$j" 2>/dev/null)"
  [[ "$st" == "ok" ]] || { log "Status bukan ok: $(jq -r '.message? // empty' <<<"$j")"; return 1; }

  local pstat; pstat="$(jq -r '.data.passwordStatus? // "passwordOk"' <<<"$j" 2>/dev/null)"
  [[ "$pstat" == "passwordOk" ]] || { log "Password salah/kurang untuk $id"; return 1; }

  local typ name; typ="$(jq -r '.data.type' <<<"$j" 2>/dev/null)"; name="$(jq -r '.data.name' <<<"$j" 2>/dev/null)"

  if [[ "$typ" == "file" ]]; then
    local link; link="$(jq -r '.data.link' <<<"$j" 2>/dev/null)"
    download_file "$root/$name" "$link"
    return 0
  fi

  mkdir -p "$root/$name"
  jq -c '.data.children | to_entries[]' <<<"$j" 2>/dev/null | while read -r e; do
    local ctype cid cname clink
    ctype="$(jq -r '.value.type' <<<"$e" 2>/dev/null)"
    cid="$(jq -r   '.value.id'   <<<"$e" 2>/dev/null)"
    cname="$(jq -r '.value.name' <<<"$e" 2>/dev/null)"
    if [[ "$ctype" == "folder" ]]; then
      traverse_download "$root/$name" "$cid" "$passhex"
    else
      clink="$(jq -r '.value.link' <<<"$e" 2>/dev/null)"
      download_file "$root/$name/$cname" "$clink"
    fi
  done
}

get_upload_server(){
  curl -sS "https://api.gofile.io/servers" \
    | jq -r 'select(.status=="ok") | .data.servers[0].name'
}

upload_file(){
  local fpath="$1"
  [[ -f "$fpath" ]] || { log "File tidak ditemukan: $fpath"; return 1; }

  local server; server="$(get_upload_server)"
  [[ -n "$server" ]] || { log "Gagal dapat server upload."; return 1; }

  local res; res="$(
    curl -sS -A "$UA" -H "Authorization: Bearer $GF_TOKEN" \
      -F "file=@${fpath}" -F "folderId=" \
      "https://${server}.gofile.io/uploadFile" 2>/dev/null || true
  )"

  if [[ "$(jq -r '.status // empty' <<<"$res" 2>/dev/null)" == "ok" ]]; then
    local dlink; dlink="$(jq -r '.data.downloadPage' <<<"$res" 2>/dev/null)"
    echo "Uploaded: ${dlink}"
  else
    log "Upload gagal: $(jq -r '.message? // empty' <<<"$res")"
  fi
}

menu_download(){
  read -rp "Masukkan URL Gofile (https://gofile.io/d/<ID>): " URL
  read -rsp "Password (jika ada, Enter jika tidak): " PASS; echo
  local id; id="$(awk -F'/d/' '{print $2}' <<<"$URL" | cut -d/ -f1)"
  [[ -n "$id" ]] || { log "URL tidak valid."; return; }
  local passhex=""; [[ -n "$PASS" ]] && passhex="$(sha256hex "$PASS")"
  mk_token || return
  local outdir; outdir="$(pwd)/$id"
  echo "Download ke: $outdir"
  traverse_download "$(pwd)" "$id" "$passhex" || log "Selesai dengan beberapa error."
  echo "Selesai → $outdir"
}

menu_upload(){
  read -rp "Path file yang diupload: " FP
  mk_token || return
  upload_file "$FP"
}

while :; do
  echo -e "\n  ____       _____ _ _        ____ _     ___ "
  echo -e " / ___| ___ |  ___(_) | ___  / ___| |   |_ _|"
  echo -e "| |  _ / _ \| |_  | | |/ _ \| |   | |    | | "
  echo -e "| |_| | (_) |  _| | | |  __/| |___| |___ | | "
  echo -e " \____|\___/|_|   |_|_|\___| \____|_____|___|"
  echo -e ""
  echo -e "by officialputuid\n"

  echo "1) Download"
  echo "2) Upload"
  echo "3) Keluar"
  read -rp "Pilih [1/2/3]: " ch
  case "${ch:-}" in
    1) menu_download ;;
    2) menu_upload ;;
    3) break ;;
    *) echo "Pilihan tidak dikenal." ;;
  esac
done
