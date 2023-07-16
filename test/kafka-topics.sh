#!/usr/bin/env bash
# mock

[[ -z "$KAFKA_TOPICS_LOG" ]] && { echo "KAFKA_TOPICS_LOG is not set" ; exit 1; }

ARGS=$@
isListCommand=false
while [ $# -ne 0 ]
do
    arg="$1"
    case "$arg" in
        --list)
            isListCommand=true
            ;;
    esac
    shift
done;

exitCode=0
if [ "$isListCommand" = true ]; then
    # Assuming the file path is stored in the FILE variable and the substring is "pattern"
    if ! grep -q " --list " "$KAFKA_TOPICS_LOG"; then
      # first call `--list` must exit with error - to initiate retry call of this command during healthcheck
      exitCode=1
    fi
fi

echo " " "$ARGS" " " >> "${KAFKA_TOPICS_LOG}"
exit $exitCode
