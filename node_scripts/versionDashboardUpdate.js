#!/usr/bin/env node

const { execFileSync } = require('child_process');
const { writeFileSync, mkdirSync } = require('fs');
const path = require('path');

const AWS_INSTANCE_MAP = {
    stg: 'aws-stg-eu00',
    prod: 'aws-prod-eu00',
};

const LAMBDA_TO_COMPONENT_MAP = {
    'personalisation-lobby-game-config': 'igaming_lobby_game_config_v3',
    'personalisation-lobby-suggested-for-you': 'igaming_lobby_suggested_games_v3',
    'personalisation-lobby-old-search': 'igaming_lobby_old_search_v3',
    'personalisation-lobby-view': 'igaming_lobby_view_v3',
    'personalisation-lobby-game-info': 'igaming_lobby_game_info_v3',
    'personalisation-lobby-personalised-extra-data': 'igaming_lobby_extra_personalised_data_v3',
    'personalisation-lobby-mini-games': 'igaming_lobby_mini_games_v3',
    'personalisation-lobby-get-bulk-game-data': 'igaming_lobby_bulk_game_data_v3',
    'personalisation-lobby-navigation': 'igaming_lobby_navigation_v3',
    'personalisation-lobby-section-view': 'igaming_lobby_section_view_v3',
    'personalisation-lobby-because-you-played': 'igaming_lobby_because_you_played_games_v3',
    'personalisation-lobby-recommended-games-on-exit': 'igaming_lobby_recommended_games_on_exit_v3',
    'personalisation-lobby-section-games': 'igaming_lobby_section_games_v3',
    'personalisation-lobby-historical-game-titles': 'igaming_lobby_historical_game_titles_v3',
    'personalisation-lobby-game-shuffle':'igaming_lobby_game_shuffle_v3',
    'personalisation-lobby-recently-played':'igaming_lobby_recently_played_games_v3'
};

const PROXY = '10.149.16.141:3546';
const BASE_ENDPOINT = 'http://10.149.16.95:30085/v1/kv/versions/coreplatform';
const OUT_DIR = path.join(__dirname, '..', 'out');
const OUTPUT_FILE = path.join(OUT_DIR, 'version_dashboard_curls.json');

function fetchLambdaVersions() {
    const scriptPath = path.join(__dirname, '..', 'scripts', 'get_latest_deployed_lambda_versions.sh');
    const output = execFileSync('bash', [scriptPath], { encoding: 'utf8' });
    return parseLambdaOutput(output);
}

function parseLambdaOutput(output) {
    const lines = output.trim().split(/\r?\n/);
    const versionMap = new Map();

    for (const line of lines) {
        if (!line || line.startsWith('ParsedVersion')) {
            continue;
        }

        const parts = line.trim().split(/\s+/);
        if (parts.length < 2) {
            continue;
        }

        const [version, func] = parts;
        versionMap.set(func, version);
    }

    return versionMap;
}

function buildCurlCommand(version, instance, component) {
    const url = buildEndpoint(instance, component);
    return `curl --request PUT --data '${version}' --proxy ${PROXY} ${url}`;
}

function buildEndpoint(instance, component) {
    return `${BASE_ENDPOINT}/${instance}/${component}`;
}

function main() {
    const environment = process.env.ENV ?? process.env.ENVIRONMENT;
    const mode = (process.env.MODE ?? 'manual').toLowerCase();

    if (!environment) {
        console.error('Please provide an environment via ENV or ENVIRONMENT (e.g. "stg" or "prod").');
        process.exit(1);
    }

    if (!['manual', 'auto'].includes(mode)) {
        console.error('MODE must be either "manual" or "auto".');
        process.exit(1);
    }

    const instance = AWS_INSTANCE_MAP[environment];
    if (!instance) {
        console.error(`Unknown environment "${environment}". Expected one of: ${Object.keys(AWS_INSTANCE_MAP).join(', ')}`);
        process.exit(1);
    }

    let lambdaVersions;

    try {
        lambdaVersions = fetchLambdaVersions();
    } catch (error) {
        console.error('Failed to fetch Lambda versions:', error.message);
        process.exitCode = 1;
        return;
    }

    const missingFunctions = [];
    const commands = [];

    for (const [lambdaName, componentName] of Object.entries(LAMBDA_TO_COMPONENT_MAP)) {
        const version = lambdaVersions.get(lambdaName);

        if (!version) {
            missingFunctions.push(lambdaName);
            continue;
        }

        commands.push({
            environment,
            instance,
            lambda: lambdaName,
            component: componentName,
            version,
            url: buildEndpoint(instance, componentName),
            curl: buildCurlCommand(version, instance, componentName),
        });
    }

    if (mode === 'manual') {
        const payload = {
            generatedAt: new Date().toISOString(),
            proxy: PROXY,
            baseEndpoint: BASE_ENDPOINT,
            environment,
            instance,
            mode,
            commands,
            missingFunctions,
        };

        mkdirSync(OUT_DIR, { recursive: true });
        writeFileSync(OUTPUT_FILE, JSON.stringify(payload, null, 2));
        console.log(`Wrote ${commands.length} curl commands to ${OUTPUT_FILE}`);

        if (missingFunctions.length) {
            console.warn('No version information for:', missingFunctions.join(', '));
        }

        return;
    }

    if (!commands.length) {
        console.warn('No Lambda versions matched the component map; nothing to update.');
        if (missingFunctions.length) {
            console.warn('Missing versions for:', missingFunctions.join(', '));
        }
        return;
    }

    console.log(`Executing ${commands.length} curl commands (mode=auto, environment=${environment}).`);

    for (const command of commands) {
        try {
            const putOutput = execFileSync('curl', ['--request', 'PUT', '--data', command.version, '--proxy', PROXY, command.url], { encoding: 'utf8' }).trim();
            console.log(`PUT ${command.component} (${command.lambda}) -> ${putOutput || 'success'}`);
        } catch (error) {
            const message = error.stderr?.toString().trim() || error.message;
            console.error(`Failed to PUT ${command.component} (${command.lambda}): ${message}`);
            continue;
        }

        try {
            const verifyOutput = execFileSync('curl', ['--proxy', PROXY, `${command.url}?raw`], { encoding: 'utf8' }).trim();
            console.log(``);
            console.log(``);
            console.log(`Verified ${command.component}: ${verifyOutput}`);
            console.log(``);
            console.log(``);
        } catch (error) {
            const message = error.stderr?.toString().trim() || error.message;
            console.error(`Failed to verify ${command.component} (${command.lambda}): ${message}`);
        }
    }

    if (missingFunctions.length) {
        console.warn('No version information for:', missingFunctions.join(', '));
    }
}

main();
