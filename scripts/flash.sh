#!/bin/bash
# Flash ATS-Mini firmware (skips if already up-to-date)
# Usage: ./scripts/flash.sh [esp32s3-ospi|esp32s3-qspi]
#   esp32s3-ospi  OPI PSRAM  — most ATS-Mini units (default)
#   esp32s3-qspi  Quad PSRAM — some alternative hardware variants

set -e

PROFILE="${1:-esp32s3-ospi}"
ARDUINO_CLI="${HOME}/bin/arduino-cli"

PORT=$(ls -ltr /dev/tty.usbmodem* 2>/dev/null | tail -n1 | awk '{print $NF}')
if [ -z "${PORT}" ]; then
    echo "Error: ATS-Mini not found. Check USB connection and try again." >&2
    exit 1
fi
echo "PORT: ${PORT}  PROFILE: ${PROFILE}"

cd "$(dirname "$0")/.."

git fetch origin

LOCAL_HEAD=$(git rev-parse HEAD)
REMOTE_HEAD=$(git rev-parse origin/main)
git diff --quiet; DIRTY=$?

if [ "${LOCAL_HEAD}" = "${REMOTE_HEAD}" ] && [ "${DIRTY}" = "0" ]; then
    echo "Already up-to-date. Nothing to flash."
    exit 0
fi

BEHIND=$(git rev-list HEAD..origin/main --count)
if [ "${BEHIND}" != "0" ]; then
    git pull
fi

"${ARDUINO_CLI}" compile --clean -e -m "${PROFILE}" \
    -p "${PORT}" -u ats-mini
