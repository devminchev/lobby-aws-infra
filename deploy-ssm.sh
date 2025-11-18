#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ── 1) AWS region constants ────────────────────────────────
EU_REGION="eu-west-1"
NA_REGION="us-east-1"    # North America
LAB_REGION="eu-west-1"
GEN_AI_REGION_EU="eu-west-1"


# ── 2) load & export .env ───────────────────────────────────
if [ ! -f .env ]; then
  echo "❌ .env file not found! Please create one."
  exit 1
fi
while IFS='=' read -r key val || [ -n "$key" ]; do
  key="$(echo -n "$key" | xargs)"
  val="$(echo -n "$val" | xargs)"
  case "$key" in
    ''|\#*) continue ;;
    *) export "$key"="$val" ;;
  esac
done < .env

# ── 3) debug: confirm shared vars loaded ─────────────────────
echo "🔍 Loaded global vars:"
echo "  CONTENTFUL_ENVIRONMENT=[$CONTENTFUL_ENVIRONMENT]"
echo "  ENABLE_XRAY=[$ENABLE_XRAY]"
echo "  EXECUTION_ENVIRONMENT=[$EXECUTION_ENVIRONMENT]"
echo

# ── 4) prompt for region ─────────────────────────────────────
echo "Please choose the deployment region:"
echo "  1) EU    ($EU_REGION)"
echo "  2) US    ($NA_REGION)"
echo "  3) Lab   ($LAB_REGION)"
echo "  4) EU GEN AI SPACE($GEN_AI_REGION_EU)"

read -p "Enter choice (1/2/3/4): " choice

case "$choice" in
  1) AWS_REGION="$EU_REGION"; PREFIX="EU"; STACK_SUFFIX="eu" ;;
  2) AWS_REGION="$NA_REGION"; PREFIX="US"; STACK_SUFFIX="us" ;;
  3) AWS_REGION="$LAB_REGION"; PREFIX="LAB"; STACK_SUFFIX="lab" ;;
  4) AWS_REGION="$GEN_AI_REGION_EU"; PREFIX="GEN_AI"; STACK_SUFFIX="eu" ;;
  *) echo "❌ Invalid choice. Exiting."; exit 1 ;;
esac

# ── 5) resolve AWS profile ───────────────────────────────────
PROFILE_VAR="${PREFIX}_AWS_PROFILE"
AWS_PROFILE="${!PROFILE_VAR:-}"
if [ -z "$AWS_PROFILE" ]; then
  echo "❌ $PROFILE_VAR is not set in .env"
  exit 1
fi

# ── 6) define parameter lists as arrays ─────────────────────
SHARED_PARAMS=(CONTENTFUL_ENVIRONMENT ENABLE_XRAY EXECUTION_ENVIRONMENT)
REGION_PARAMS=(CONTENTFUL_ACCESS_TOKEN CONTENTFUL_SIGNING_SECRET \
               CONTENTFUL_SPACE_LOCALE HOST OS_PASS OS_USER SPACE_ID)

# ── 7) helper to CamelCase your CFN keys ────────────────────
toCamelCase() {
  local input="$1" part lower first rest result=""
  IFS='_' read -ra parts <<< "$input"
  for part in "${parts[@]}"; do
    lower="$(echo "$part" | tr '[:upper:]' '[:lower:]')"
    first="$(echo "${lower:0:1}" | tr '[:lower:]' '[:upper:]')"
    rest="${lower:1}"
    result+="${first}${rest}"
  done
  printf "%s" "$result"
}

# ── 8) build the overrides array ────────────────────────────
PARAM_OVERRIDES=()

# 8a) shared (no prefix)
for VAR in "${SHARED_PARAMS[@]}"; do
  VAL="${!VAR:-}"
  if [ -z "$VAL" ]; then
    echo "❌ Required global var $VAR missing in .env"
    exit 1
  fi
  PARAM_OVERRIDES+=( "$(toCamelCase "$VAR")=$VAL" )
done

# 8b) region‑specific (prefix in .env)
for VAR in "${REGION_PARAMS[@]}"; do
  ENV_VAR="${PREFIX}_${VAR}"
  VAL="${!ENV_VAR:-}"
  if [ -z "$VAL" ]; then
    echo "❌ Required var $ENV_VAR missing in .env"
    exit 1
  fi
  PARAM_OVERRIDES+=( "$(toCamelCase "$VAR")=$VAL" )
done

# ── 9) debug: show parameter overrides ──────────────────────
echo
echo "🔧 Deploying with these parameter overrides:"
for o in "${PARAM_OVERRIDES[@]}"; do
  echo "  - $o"
done
echo

# ── 10) compose stack name & deploy ────────────────────────
STACK_NAME="personalised-lobby-ssm-$STACK_SUFFIX"

aws cloudformation deploy \
  --template-file templates/parameterStoreVariables.yml \
  --stack-name "$STACK_NAME" \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --parameter-overrides "${PARAM_OVERRIDES[@]}"

echo
echo "✅ Deployed to $AWS_REGION"
echo "   Profile: $AWS_PROFILE"
echo "   Stack:   $STACK_NAME"
