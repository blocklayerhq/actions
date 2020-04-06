#!/bin/bash

set -x
set -eu -o pipefail

[ -z "${INPUT_REPO_TOKEN:-}" ] && (echo "repo_token input missing"; exit 1)
[ -z "${INPUT_BL_API_KEY:-}" ] && (echo "bl_api_key input missing"; exit 1)
[ -z "${INPUT_BL_DOMAIN:-}" ] && (echo "bl_domain input missing"; exit 1)
[ -z "${INPUT_BL_TARGET:-}" ] && (echo "bl_target input missing"; exit 1)

# Print full environment for debugging
echo "Github action environment:"
echo "----- BEGIN ENVIRONMENT -----"
env
echo "----- END ENVIRONMENT -----"

# Print full event contents for debugging
echo "Received raw event:"
echo "---- BEGIN EVENT -----"
cat "$GITHUB_EVENT_PATH"
echo "---- END EVENT ------"

# Push the entire Github event to the Blocklayer domain + target


echo "---- pushing event to blocklayer ----"
bl push \
	--kind json \
	"$INPUT_BL_DOMAIN" \
	--target "$INPUT_BL_TARGET" \
	"$(cat $GITHUB_EVENT_PATH)"
echo "---- done ----"
exit 0
