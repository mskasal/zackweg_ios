#!/bin/bash

# Exit on error
set -e

# Load environment variables
source "$CI_WORKSPACE/Staging.xcconfig"

# Build the app
xcodebuild -scheme zackWeg \
           -configuration Release \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           -xcconfig "$CI_WORKSPACE/Staging.xcconfig" \
           clean build

# Archive the app
xcodebuild -scheme zackWeg \
           -configuration Release \
           -destination generic/platform=iOS \
           -xcconfig "$CI_WORKSPACE/Staging.xcconfig" \
           archive -archivePath "$CI_WORKSPACE/build/zackWeg.xcarchive"

# Export IPA for TestFlight
xcodebuild -exportArchive \
           -archivePath "$CI_WORKSPACE/build/zackWeg.xcarchive" \
           -exportOptionsPlist "$CI_WORKSPACE/ci_scripts/exportOptions_testflight.plist" \
           -exportPath "$CI_WORKSPACE/build"

echo "TestFlight build completed successfully!" 