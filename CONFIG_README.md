# ZackWeg iOS Configuration Setup

## Overview

ZackWeg iOS uses a configuration system that separates environment-specific values from the main Info.plist file to avoid build conflicts. We use:

1. **xcconfig files** - Define environment variables for different build configurations
2. **ConfigurationManager** - Swift class to access these values in code

## Setup Steps

If you're experiencing the "Multiple commands produce Info.plist" error, follow these steps:

1. **Xcode Settings**:
   - Make sure "Generate Info.plist File" is enabled in project build settings
   - Don't specify a custom Info.plist file path in build settings

2. **Add variables to Info.plist**:
   - In your project's Info.plist, add user-defined keys for configuration variables
   - You can reference xcconfig variables using the syntax: `$(VARIABLE_NAME)`
   - Example: API_BASE_URL = `$(API_BASE_URL)`

3. **Update your xcconfig files**:
   - Remove any `INFOPLIST_FILE` settings in xcconfig files
   - Make sure all needed environment variables are defined in xcconfig files

4. **Clean and Build**:
   - Select Product → Clean Build Folder
   - Build and run the app

## How it Works

- The Info.plist file contains placeholders like `$(API_BASE_URL)`
- Xcode automatically substitutes these values from the active xcconfig file
- ConfigurationManager reads these values from Info.plist
- If variables aren't substituted properly, ConfigurationManager has fallback logic

## Troubleshooting

If you encounter issues:

1. Make sure your xcconfig files define all needed variables
2. Check that your project settings point to the correct xcconfig file for each configuration
3. Look at the ConfigurationManager's debug output to see which values are loading correctly
4. If you're using user-defined build settings in the Xcode GUI, make sure they don't conflict with xcconfig settings 
