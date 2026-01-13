#!/bin/bash

# Define the target Go version
TARGET_GO_VERSION="1.24.11"
PROJECT_DIR="/Users/tgvu/Documents/AI/ai_projects/caro_chess/server"

echo "Started update process for Go dependencies..."

# Navigate to the server directory
if [ -d "$PROJECT_DIR" ]; then
  cd "$PROJECT_DIR" || { echo "Failed to navigate to $PROJECT_DIR"; exit 1; }
else
  echo "Directory $PROJECT_DIR does not exist."
  exit 1
fi

# Check if go.mod exists
if [ ! -f "go.mod" ]; then
  echo "go.mod not found in $PROJECT_DIR"
  exit 1
fi

# Update the go version in go.mod
# This uses sed to replace the line starting with 'go'
echo "Updating go.mod to version $TARGET_GO_VERSION..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS requires an empty string argument for -i
  sed -i '' "s/^go [0-9.]*/go $TARGET_GO_VERSION/" go.mod
else
  sed -i "s/^go [0-9.]*/go $TARGET_GO_VERSION/" go.mod
fi

# Run go mod tidy
echo "Running go mod tidy..."
if command -v go &> /dev/null; then
    go mod tidy
    if [ $? -eq 0 ]; then
        echo "Successfully updated go.mod and ran go mod tidy."
    else
        echo "Error: 'go mod tidy' failed. Please ensure you have Go $TARGET_GO_VERSION installed on your system."
    fi
else
    echo "Error: 'go' command not found. Please install Go."
fi

echo "Done."
