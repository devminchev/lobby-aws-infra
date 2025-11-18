# Version Dashboard Update Script

`versionDashboardUpdate.js` builds curl commands for keeping the version dashboard in sync with the latest Lambda container deployments. It can either write the commands to a JSON file for manual use or execute them directly and verify the stored values.

## Requirements

- Node.js 18+ (ships with `child_process.execFileSync`).
- AWS CLI credentials with permission to call `aws lambda get-function` for the selected account/region.
- The `curl` binary available on your PATH.

## Environment Variables

- `ENV` (or `ENVIRONMENT`): **Required.** Determines which Consul instance to target. Currently supported values:
  - `stg` → `aws-stg-eu00`
  - `prod` → `prod_eu00`
- `MODE`: Optional. Controls how results are handled. Defaults to `manual`.
  - `manual` → generate curl payloads and save them to `out/version_dashboard_curls.json`.
  - `auto` → execute each curl immediately and follow up with a `?raw` GET to confirm the value stored in Consul.
- `AWS_PROFILE` / `AWS_REGION`: Optional. Picked up by `scripts/get_latest_deployed_lambda_versions.sh` when you need to query a different account or region. They fall back to `lobby-playground` and `eu-west-2` respectively.

## How It Works

1. Invokes `../scripts/get_latest_deployed_lambda_versions.sh` to obtain the latest image tag version for each Lambda.
2. Maps Lambda names to dashboard component identifiers.
3. Depending on `MODE`:
   - **manual:** writes metadata and one-line curl commands to `out/version_dashboard_curls.json` (folder is created if missing).
   - **auto:** loops through each command, performs the PUT via `curl`, and immediately runs a `?raw` GET to print the stored value.
4. Logs any Lambdas that were missing version information.

## Usage Examples

Manual run for staging (produces JSON only):

```sh
ENV=stg MODE=manual node node_scripts/versionDashboardUpdate.js
```

Auto-run for production (writes values directly):

```sh
ENV=prod MODE=auto AWS_PROFILE=lobby-playground-prod node node_scripts/versionDashboardUpdate.js
```

The console output confirms each action. In auto mode you will see both the PUT result and the verification response for every component. In manual mode check `out/version_dashboard_curls.json` for the generated payload. Any missing Lambda-to-component mappings are surfaced as warnings so they can be addressed separately.

## Get Currently Deployed Versions

`getDeployedVersions.js` reads the current values stored in the version dashboard for both staging (`aws-stg-eu00`) and production (`prod_eu00`) components. It shares the same proxy and base endpoint configuration.

Run it with:

```sh
node node_scripts/getDeployedVersions.js
```

The script prints each component with its stored version, surfacing any errors encountered when querying Consul.
