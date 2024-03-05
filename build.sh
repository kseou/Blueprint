#!/bin/bash

# Determine the operating system
OS=$(uname)

COMMON_PATH="./source"
SOURCE_FILES="main.lua \
              $COMMON_PATH/blueprint.lua \
              $COMMON_PATH/chalk.lua \
              $COMMON_PATH/data_parser.lua \
              $COMMON_PATH/dependency.lua \
              $COMMON_PATH/lfs_ffi.lua \
              $COMMON_PATH/toml.lua \
              $COMMON_PATH/utils.lua \
              $COMMON_PATH/lummander/lummander.lua \
              $COMMON_PATH/lummander/command.lua \
              $COMMON_PATH/lummander/init.lua \
              $COMMON_PATH/lummander/parsed.lua \
              $COMMON_PATH/lummander/pcall.lua \
              $COMMON_PATH/lummander/themecolor.lua \
              $COMMON_PATH/lummander/themes/acid.lua \
              $COMMON_PATH/lummander/themes/default.lua \
              $COMMON_PATH/f/init.lua \
              $COMMON_PATH/f/string.lua \
              $COMMON_PATH/f/table.lua"

# Default library and include directory for Linux
LIBRARY="/usr/lib/x86_64-linux-gnu/libluajit-5.1.a"
INCLUDE_DIR="-I/usr/include/luajit-2.1"
BUILD_OPTIONS=""

# Adjust library, include directory, and build options for macOS
if [ "$OS" == "Darwin" ]; then
    LIBRARY="/opt/homebrew/Cellar/luajit/2.1.1703358377/lib/libluajit.a"
    INCLUDE_DIR="-I/opt/homebrew/Cellar/luajit/2.1.1703358377/include/luajit-2.1"
else
    BUILD_OPTIONS="-no-pie"
fi

OUTPUT_FILE="blueprint"

# Build the command
BUILD_COMMAND="luastatic $SOURCE_FILES $LIBRARY $INCLUDE_DIR $BUILD_OPTIONS -o $OUTPUT_FILE"

echo "Building Blueprint..."
$BUILD_COMMAND

if [ $? -eq 0 ]; then
    echo "Build successful! Executable '$OUTPUT_FILE' created."

    echo "Moving executable to /usr/local/bin..."
    sudo mv $OUTPUT_FILE /usr/local/bin/

    if [ $? -eq 0 ]; then
        echo "Executable moved successfully."
    else
        echo "Failed to move executable. You may need root privileges."
    fi
else
    echo "Build failed."
fi
