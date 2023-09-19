#!/bin/bash

# Paths to the files
SOURCE_FILE="./lib/demo_main.dart"
DESTINATION_FILE="./lib/main.dart"

# Replace the content of DESTINATION_FILE with the content of SOURCE_FILE
cp "$SOURCE_FILE" "$DESTINATION_FILE"

# Print a message to indicate the operation was successful
echo "Content of $DESTINATION_FILE has been replaced with the content of $SOURCE_FILE."
