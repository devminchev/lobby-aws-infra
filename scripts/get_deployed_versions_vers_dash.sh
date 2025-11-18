#!/bin/bash
set -euo pipefail

PROXY="10.149.16.141:3546"
BASE_ENDPOINT="http://10.149.16.95:30085/v1/kv/versions/coreplatform"

map_env_to_instance() {
  case "$1" in
    stg)  printf '%s\n' "aws-stg-eu00" ;;
    prod) printf '%s\n' "prod_eu00" ;;
    *)    printf '%s\n' "$1" ;;
  esac
}

declare -a TARGET_INSTANCES=()

if [ "$#" -eq 0 ]; then
  TARGET_INSTANCES+=("$(map_env_to_instance stg)")
  TARGET_INSTANCES+=("$(map_env_to_instance prod)")
else
  for arg in "$@"; do
    TARGET_INSTANCES+=("$(map_env_to_instance "$arg")")
  done
fi

TMP_ERR=$(mktemp)
trap 'rm -f "$TMP_ERR"' EXIT

get_keys() {
  local instance="$1"
  local url="$BASE_ENDPOINT/$instance/?keys"
  curl --silent --show-error --fail --proxy "$PROXY" "$url" \
    | tr -d '[]"' | tr ',' '\n' | sed '/^$/d' | sed 's#^versions/coreplatform/##'
}

get_value() {
  local key="$1"
  curl --silent --show-error --fail --proxy "$PROXY" "$BASE_ENDPOINT/$key?raw"
}

format_table() {
  local keys=("$@")
  printf "%-45s %s\n" "Component" "Version"
  printf '%s\n' "-------------------------------------------------------------"
  if [ ${#keys[@]} -eq 0 ]; then
    printf "(no keys found)\n"
    return
  fi

  for key in "${keys[@]}"; do
    [[ "$key" == */ ]] && continue
    local component="${key##*/}"
    local value
    if value=$(get_value "$key" 2>"$TMP_ERR"); then
      printf "%-45s %s\n" "$component" "${value:- (empty)}"
    else
      printf "%-45s ERROR: %s\n" "$component" "$(< "$TMP_ERR" | tr -d '\n')"
    fi
  done
}

for instance in "${TARGET_INSTANCES[@]}"; do
  echo
  echo "=== $instance ==="
  if keys=$(get_keys "$instance" 2>"$TMP_ERR"); then
    key_array=()
    while IFS= read -r line; do
      key_array+=("$line")
    done <<<"$keys"
    format_table "${key_array[@]}"
  else
    echo "Failed to list keys: $(< "$TMP_ERR")"
  fi
done

