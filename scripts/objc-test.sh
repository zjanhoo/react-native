#!/bin/bash

# This script contains common code to be run from scripts/objc-test-ios.sh or scripts/objc-test-tvos.sh

# Start the packager and preload the UIExplorerApp bundle for better performance in integration tests
open "./packager/launchPackager.command" || echo "Can't start packager automatically"
sleep 20
curl 'http://localhost:8081/Examples/UIExplorer/js/UIExplorerApp.ios.bundle?platform=ios&dev=true' -o temp.bundle
rm temp.bundle
curl 'http://localhost:8081/Examples/UIExplorer/js/UIExplorerApp.ios.bundle?platform=ios&dev=true&minify=false' -o temp.bundle
rm temp.bundle
curl 'http://localhost:8081/IntegrationTests/IntegrationTestsApp.bundle?platform=ios&dev=true' -o temp.bundle
rm temp.bundle
curl 'http://localhost:8081/IntegrationTests/RCTRootViewIntegrationTestApp.bundle?platform=ios&dev=true' -o temp.bundle
rm temp.bundle

function cleanup {
  EXIT_CODE=$?
  set +e

  if [ $EXIT_CODE -ne 0 ];
  then
    WATCHMAN_LOGS=/usr/local/Cellar/watchman/3.1/var/run/watchman/$USER.log
    [ -f $WATCHMAN_LOGS ] && cat $WATCHMAN_LOGS
  fi
  # kill whatever is occupying port 8081
  lsof -i tcp:8081 | awk 'NR!=1 {print $2}' | xargs kill
}
trap cleanup EXIT

# Support for environments without xcpretty installed
set +e
OUTPUT_TOOL=$(which xcpretty)
set -e

# TODO: We use xcodebuild because xctool would stall when collecting info about
# the tests before running them. Switch back when this issue with xctool has
# been resolved.
if [ -z "$OUTPUT_TOOL" ]; then
  xcodebuild \
    -project $XCODE_PROJECT \
    -scheme $XCODE_SCHEME \
    -sdk $XCODE_SDK \
    -destination "$XCODE_DESTINATION" \
    test
else
  xcodebuild \
    -project $XCODE_PROJECT \
    -scheme $XCODE_SCHEME \
    -sdk $XCODE_SDK \
    -destination "$XCODE_DESTINATION" \
    test | $OUTPUT_TOOL && exit ${PIPESTATUS[0]}
fi
