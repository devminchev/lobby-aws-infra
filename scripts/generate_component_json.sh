#!/bin/bash

# Function to map Lambda function names to deployable_name
get_deployable_name() {
  case "$1" in
    "personalisation-lobby-categories-ts") echo "igaming_lobby_categories" ;;
    "personalisation-lobby-game-config-ts") echo "igaming_lobby_game_config" ;;
    "personalisation-lobby-game-info-ts") echo "igaming_lobby_game_info" ;;
    "personalisation-lobby-game-titles-ts") echo "igaming_lobby_game_titles" ;;
    "personalisation-lobby-layouts-ts") echo "igaming_lobby_layouts" ;;
    "personalisation-lobby-mini-games-ts") echo "igaming_lobby_minigames" ;;
    "personalisation-lobby-old-search-ts") echo "igaming_lobby_old_search" ;;
    "personalisation-lobby-section-games-ts") echo "igaming_lobby_section_games" ;;
    "personalisation-lobby-suggested-for-you-ts") echo "igaming_lobby_recommended_games" ;;
    "personalisation-lobby-because-you-played-ts") echo "igaming_lobby_because_you_played_games" ;;
    "personalisation-lobby-personalised-extra-data-ts") echo "igaming_lobby_extra_personalised_data" ;;
    "personalisation-lobby-get-bulk-game-data-ts") echo "igaming_lobby_bulk_game_data" ;;
    "personalisation-lobby-historic-game-titles-ts") echo "igaming_lobby_historical_game_titles" ;;
    "personalisation-lobby-historic-game-titles-handler-ts") echo "igaming_lobby_historical_game_titles" ;;
    *) echo "" ;;  # If no match, return empty string
  esac
}

# Function arguments: Lambda function name & latest version
func="$1"
latest_version="$2"

# Get deployable_name from function mapping
deployable_name=$(get_deployable_name "$func")

# If there's no valid mapping, return empty JSON object
if [[ -n "$deployable_name" ]]; then
  cat <<EOF
{
  "deployable_name": "$deployable_name",
  "deployable_version": "$latest_version",
  "regions": ["eu"]
}
EOF
else
  echo ""
fi
