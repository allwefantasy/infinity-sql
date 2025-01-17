#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    echo "You can install it using: brew install gh"
    exit 1
fi

# Authenticate with GitHub using personal key
echo "${GITHUB_KEY}" | gh auth login --with-token

# Configuration
version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
PROJECT="$( cd "$( dirname "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" )" >/dev/null 2>&1 && pwd )"

echo "Project directory: ${PROJECT}"

RELEASE_DIR="${PROJECT}/release"

# Check if release directory exists
if [ ! -d "${RELEASE_DIR}" ]; then
    echo "Release directory not found: ${RELEASE_DIR}"
    exit 1
fi

# Get all .tar.gz files in release directory
RELEASE_FILES=($(find "${RELEASE_DIR}" -name "*.tar.gz"))

if [ ${#RELEASE_FILES[@]} -eq 0 ]; then
    echo "No .tar.gz files found in release directory: ${RELEASE_DIR}"
    exit 1
fi

# Create a new release with all files
echo "Creating GitHub release ${version} with ${#RELEASE_FILES[@]} files..."
gh release create "${version}" \
    --title "Release ${version}" \
    --notes "Release ${version}" \
    "${RELEASE_FILES[@]}" \
    --target v1.0.0

if [ $? -eq 0 ]; then
    echo "Successfully created release ${version} and uploaded:"
    printf ' - %s\n' "${RELEASE_FILES[@]}"
else
    echo "Failed to create release"
    exit 1
fi
