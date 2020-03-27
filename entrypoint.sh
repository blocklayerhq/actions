#!/bin/bash

set -eu -o pipefail

env

[ -z "${INPUT_REPO_TOKEN}" ] && (echo "repo_token input missing"; exit 1)
[ -z "${INPUT_BL_API_KEY}" ] && (echo "bl_api_key input missing"; exit 1)
[ -z "${INPUT_BL_DOMAIN}" ] && (echo "bl_domain input missing"; exit 1)
[ -z "${INPUT_BL_TARGET}" ] && (echo "bl_target input missing"; exit 1)

# Grab PR info
PR_DATA=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request)
PR_NUMBER="$(echo $PR_DATA | jq -r .number)"

# Set up auth
export GITHUB_TOKEN="${INPUT_REPO_TOKEN}"
export BL_API_KEY="${INPUT_BL_API_KEY}"


PAYLOAD=$(
	jq \
		--arg pr "$PR_NUMBER" \
		'setpath(["pr", $pr];{"status": "open"})'
)

bl push \
	"${INPUT_BL_DOMAIN}" \
	--kind json \
	--target "${INPUT_BL_TARGET}" \
	"$PAYLOAD"

# If we're not in a pull request, stop here
if [ "$PR_DATA" = "null" ]; then
	exit 0
fi
