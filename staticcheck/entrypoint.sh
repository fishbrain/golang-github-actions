#!/bin/sh
set -e
cd "${GO_ACTION_WORKING_DIR:-.}"

if [ ! -e go.mod ]; then go mod init; fi
for i in {1..3}; do
	go mod download && break
done
if [ $? -ne 0 ]; then exit 1; fi

set +e
OUTPUT=$(sh -c "staticcheck ${FLAGS} ./... $*" 2>&1)
SUCCESS=$?
echo "${OUTPUT}"
set -e

if [ ${SUCCESS} -eq 0 ]; then
    exit 0
fi

if [ "${GO_ACTION_COMMENT}" = "1" ] || [ "${GO_ACTION_COMMENT}" = "false" ]; then
    exit ${SUCCESS}
fi

COMMENT="## staticcheck Failed

\`\`\`
${OUTPUT}
\`\`\`

[Checks Document](https://staticcheck.io/docs/checks)
"

PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT}" '.body = $body')
COMMENTS_URL=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${PAYLOAD}" "${COMMENTS_URL}" > /dev/null

# dry run, ignore SUCCESS
# exit ${SUCCESS}
exit 0
