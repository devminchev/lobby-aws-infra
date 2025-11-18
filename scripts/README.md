# Scripts Overview

## `get_latest_deployed_lambda_versions.sh`

Fetches every Lambda function in the target AWS account/region, extracts the image tag version from each function’s ECR URI, and prints a tab-separated table (`ParsedVersion`, `Function`, `ImageUri`). The script uses `AWS_PROFILE` and `AWS_REGION` if they are set; otherwise it defaults to `lobby-playground` and `eu-west-2`.

### Usage

```sh
    ./scripts/get_latest_deployed_lambda_versions.sh
```

### Output (example)

```text
ParsedVersion    Function                               ImageUri
0.13.3          personalisation-lobby-game-config       658499212567.dkr.ecr.eu-west-2.amazonaws.com/...-0.13.3
...
```

Downstream tools (like `node_scripts/versionDashboardUpdate.js`) consume the parsed version column to drive updates.

## `get_deployed_versions_vers_dash.sh`

Queries version dashboard via proxy to list all keys under `versions/coreplatform/<instance>` and prints a formatted table of components and their stored versions. By default it reports both staging and production instances, but you can pass `stg`, `prod`, or explicit instance names.

### Usage

```sh
# list both staging and production
./scripts/get_deployed_versions_vers_dash.sh

# staging only
./scripts/get_deployed_versions_vers_dash.sh stg

# explicit instance name
./scripts/get_deployed_versions_vers_dash.sh aws-stg-eu00
```

### Output (example)

```text
=== aws-stg-eu00 ===
Component                                     Version
-------------------------------------------------------------
igaming_lobby_game_config_v3                  0.13.3
igaming_lobby_suggested_games_v3              0.15.4
...
```
