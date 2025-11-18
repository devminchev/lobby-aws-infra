#!/usr/bin/env node

const { execFileSync } = require('child_process');

const PROXY = '10.149.16.141:3546';
const BASE_ENDPOINT = 'http://10.149.16.95:30085/v1/kv/versions/coreplatform';

const AWS_INSTANCE_MAP = {
    stg: 'aws-stg-eu00',
    prod: 'prod_eu00',
};

const COMPONENTS = Array.from(new Set([
    'igaming_lobby_game_config_v3',
    'igaming_lobby_suggested_games_v3',
    'igaming_lobby_old_search_v3',
    'igaming_lobby_view_v3',
    'igaming_lobby_game_info_v3',
    'igaming_lobby_extra_personalised_data_v3',
    'igaming_lobby_mini_games_v3',
    'igaming_lobby_bulk_game_data_v3',
    'igaming_lobby_navigation_v3',
    'igaming_lobby_section_view_v3',
    'igaming_lobby_because_you_played_games_v3',
    'igaming_lobby_recommended_games_on_exit_v3',
    'igaming_lobby_section_games_v3',
]));

function buildEndpoint(instance, component) {
    return `${BASE_ENDPOINT}/${instance}/${component}`;
}

function readComponent(instance, component) {
    const url = `${buildEndpoint(instance, component)}?raw`;

    try {
        const value = execFileSync('curl', ['--silent', '--show-error', '--proxy', PROXY, url], { encoding: 'utf8' }).trim();
        return { value: value || '(empty)' };
    } catch (error) {
        const message = error.stderr?.toString().trim() || error.message;
        return { error: message };
    }
}

function logEnvironment(env, instance) {
    const rows = COMPONENTS.map((component) => {
        const { value, error } = readComponent(instance, component);
        return {
            component,
            version: error ? `ERROR: ${error}` : value,
        };
    });

    console.log(`\n=== ${env.toUpperCase()} (${instance}) ===`);
    console.table(rows);
}

function main() {
    console.log('Version Dashboard deployed versions');

    for (const env of ['stg', 'prod']) {
        const instance = AWS_INSTANCE_MAP[env];
        if (!instance) {
            console.warn(`Skipping unknown environment: ${env}`);
            continue;
        }

        logEnvironment(env, instance);
    }
}

main();

