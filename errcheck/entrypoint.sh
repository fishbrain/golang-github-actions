#!/bin/sh
set -e
cd "${GO_ACTION_WORKING_DIR:-.}"

if [ ! -e go.mod ]; then go mod init; fi
for i in {1..3}; do
	go mod download && break
done
if [ $? -ne 0 ]; then exit 1; fi

set +e
if [ "${IGNORE_DEFER}" = "1" ] || [ "${IGNORE_DEFER}" = "true" ]; then
    IGNORE_COMMAND="| grep -v defer"
fi

OUTPUT=$(sh -c "errcheck ${FLAGS} ./... ${IGNORE_COMMAND} $*" 2>&1)
test -z "${OUTPUT}"
SUCCESS=$?
echo "${OUTPUT}"
set -e

if [ ${SUCCESS} -eq 0 ]; then
    exit 0
fi

if [ "${GO_ACTION_COMMENT}" = "1" ] || [ "${GO_ACTION_COMMENT}" = "false" ]; then
    exit ${SUCCESS}
fi

COMMENT="## errcheck Failed

\`\`\`
${OUTPUT}
\`\`\`

"

PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT}" '.body = $body')
COMMENTS_URL=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${PAYLOAD}" "${COMMENTS_URL}" > /dev/null

exit ${SUCCESS}
