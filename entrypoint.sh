#!/bin/bash

set -eu -o pipefail

env

[ -z "${INPUT_PIPELINE}" ] && (echo "pipeline input missing"; exit 1)
[ -z "${INPUT_REPO_TOKEN}" ] && (echo "repo-token input missing"; exit 1)
[ -z "${INPUT_API_KEY}" ] && (echo "api-key input missing"; exit 1)

# Grab PR info
PR_DATA=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request)
PR_NUMBER="$(echo $PR_DATA | jq -r .number)"

# Templatize the Pipeline name and inputs
PIPELINE=$(echo "${INPUT_PIPELINE}" | sed -e "s=\${PR_NUMBER}=$PR_NUMBER=g")
INPUTS=$(echo "${INPUT_INPUTS}" | sed -e "s=\${PR_NUMBER}=$PR_NUMBER=g")

echo ::set-output name=pipeline::$PIPELINE

# Set up auth
export GITHUB_TOKEN="${INPUT_REPO_TOKEN}"
export BL_API_KEY="${INPUT_API_KEY}"

if [ -n "$INPUT_CLONE" ]; then
	bl line clone "$INPUT_CLONE" $PIPELINE || true
fi

# Run the job in detached state
bl line run -d "$PIPELINE" ${INPUTS[@]} |& tee /tmp/output
SUCCESS=${PIPESTATUS[0]}
[ $SUCCESS -ne 0 ] && exit $SUCCESS

# Retrieve the job and wait for the pipeline to complete
JOB_ID=$(cat /tmp/output | sed -n -e 's/^success Submitted job \(.*\) to pipeline.*$/\1/p')
echo ::set-output name=job_id::$JOB_ID
bl line status -f "$PIPELINE" "$JOB_ID"

# If we're not in a pull request or commenting is disabled, stop here
if [ "$PR_DATA" = "null" ] || [ "$INPUT_COMMENT" = "false" ]; then
	exit 0
fi

# Otherwise, comment on the PR
OUTPUTS="$(bl line outputs $PIPELINE $JOB_ID)"
MARKDOWN_OUTPUTS=$(echo "$OUTPUTS" | \
	sed -n -e 's/^\(.*\) (\(.*\)) = "\(.*\)""*$/|\1|\2|\3|/p')
COMMENT="#### :white_check_mark: Blocklayer Pipeline Completed

##### Outputs

|Output|Type|Value|
|------|----|-----|
${MARKDOWN_OUTPUTS}
"
PAYLOAD=$(echo '{}' | jq --arg body "$COMMENT" '.body = $body')
COMMENTS_URL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
curl -s -S \
	-H "Authorization: token $GITHUB_TOKEN" \
	-H "Content-Type: application/json" \
	--data "$PAYLOAD" "$COMMENTS_URL" > /dev/null
