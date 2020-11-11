#!/bin/bash

set -eu -o pipefail

env

[ -z "${INPUT_STACK}" ] && (echo "stack input missing"; exit 1)
[ -z "${INPUT_ENV}" ] && (echo "env input missing"; exit 1)
[ -z "${INPUT_REPO_TOKEN}" ] && (echo "repo-token input missing"; exit 1)
[ -z "${INPUT_API_KEY}" ] && (echo "api-key input missing"; exit 1)

# Grab PR info
PR_DATA=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request)
PR_NUMBER="$(echo $PR_DATA | jq -r .number)"

# Set up auth
export GITHUB_TOKEN="${INPUT_REPO_TOKEN}"
export BL_API_KEY="${INPUT_API_KEY}"

# Templatize the Env name and sources
ENV_NAME=$(echo "${INPUT_ENV}" | sed -e "s=\${PR_NUMBER}=$PR_NUMBER=g")
SOURCES=$(echo "${INPUT_SOURCES}" | sed -e "s=\${PR_NUMBER}=$PR_NUMBER=g")

workspace="personal"
if [ -n "$INPUT_WORKSPACE" ]; then
	bl workspace set "$INPUT_WORKSPACE"
	workspace="$INPUT_WORKSPACE"
fi

# Create env if not exist
bl --stack "${INPUT_STACK}" env create "${ENV_NAME}" || true

# Select right stack / env
bl use "${INPUT_STACK}" "${ENV_NAME}"

# Run the job in detached state
for src in ${SOURCES[@]}; do
	component="$(echo $src | cut -d'=' -f1)"
	localpath="$(echo $src | cut -d'=' -f2)"
	bl push -d "$component" "$localpath"
done

bl workspace list | grep $workspace

# Retrieve the job and wait for the pipeline to complete
workspace_id=$(bl workspace list | grep "$workspace" | awk '{ print $2; }')
dashboard_url="https://beta.app.blocklayerhq.com/w/${workspace_id}/stacks/${INPUT_STACK}/envs/${INPUT_ENV}"
echo ::set-output name=dashboard_url::"$dashboard_url"

# If we're not in a pull request or commenting is disabled, stop here
if [ "$PR_DATA" = "null" ] || [ "$INPUT_COMMENT" = "false" ]; then
	exit 0
fi

# Otherwise, comment on the PR
COMMENT="#### :rocket: Blocklayer Deployment triggered

Follow the deployment progress: $dashboard_url
"
PAYLOAD=$(echo '{}' | jq --arg body "$COMMENT" '.body = $body')
COMMENTS_URL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
curl -s -S \
	-H "Authorization: token $GITHUB_TOKEN" \
	-H "Content-Type: application/json" \
	--data "$PAYLOAD" "$COMMENTS_URL" > /dev/null
