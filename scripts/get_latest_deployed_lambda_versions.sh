# #!/bin/bash

# # Fetch all Node.js Lambda functions with their img URI to get the version

set -euo pipefail

profile=lobby-playground
region=eu-west-2

printf "%s\t%s\t%s\n" "ParsedVersion" "Function" "ImageUri"

aws lambda list-functions \
  --profile "$profile" --region "$region" \
  --query 'Functions[].FunctionName' --output text \
| tr '\t' '\n' \
| while read -r func; do
  uri=$(
    aws lambda get-function \
      --profile "$profile" --region "$region" \
      --function-name "$func" \
      --query 'Code.ImageUri' --output text 2>/dev/null
  )

  # skip if no image (zip-based or unavailable)
  [ -z "$uri" ] || [ "$uri" = "None" ] && continue

  tag=${uri##*:}
  parsed=${tag##*-}
  printf "%s\t%s\t%s\n" "$parsed" "$func" "$uri"
done
