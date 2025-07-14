#!/bin/bash

set -e

# Ensure gh CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Usage: ./release.sh [major|minor|patch]
INCREMENT_TYPE=$1
if [[ "$INCREMENT_TYPE" != "major" && "$INCREMENT_TYPE" != "minor" && "$INCREMENT_TYPE" != "patch" ]]; then
    echo "Usage: $0 [major|minor|patch]"
    exit 1
fi

# Get latest tag (release)
LATEST_TAG=$(git describe --tags --abbrev=0)
echo "Latest release tag: $LATEST_TAG"

# Get commits since last tag
COMMITS=$(git log "$LATEST_TAG"..HEAD --pretty=format:"%h: %s")
if [ -z "$COMMITS" ]; then
    echo "No new commits since last release."
    exit 1
fi

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "${LATEST_TAG//v/}"

case $INCREMENT_TYPE in
    major)
        NEW_TAG="$((MAJOR + 1)).0.0"
        ;;
    minor)
        NEW_TAG="$MAJOR.$((MINOR + 1)).0"
        ;;
    patch)
        NEW_TAG="$MAJOR.$MINOR.$((PATCH + 1))"
        ;;
esac

echo "Creating new release: v$NEW_TAG"

# Create the release note
RELEASE_BODY=$(echo -e "$COMMITS")

# Create the new tag and push (optional if not tagging manually)
git tag "v$NEW_TAG"
git push origin "v$NEW_TAG"

# Create GitHub release using gh CLI
gh release create "v$NEW_TAG" --notes "$RELEASE_BODY"

echo "Release v$NEW_TAG created with notes:"
echo "$RELEASE_BODY"
