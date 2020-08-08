#!/bin/bash

if [[ -z "$INPUT_FILE" ]]; then
  echo "Missing file input in the action"
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Missing GITHUB_REPOSITORY env variable"
  exit 1
fi

REPO=$GITHUB_REPOSITORY
if ! [[ -z ${INPUT_REPO} ]]; then
  REPO=$INPUT_REPO ;
fi

# Optional personal access token for external repository
TOKEN=$GITHUB_TOKEN
if ! [[ -z ${INPUT_TOKEN} ]]; then
  TOKEN=$INPUT_TOKEN
fi

echo "Repo: $REPO"
echo "Version: $INPUT_VERSION"
echo "File: $INPUT_FILE"

RELEASE_DATA=$(curl -u :$TOKEN $GITHUB_API_URL/repos/$REPO/releases/${INPUT_VERSION})

if [[ "$?" -ne "0" ]]; then
  echo 'Failed to fetch release data'
  exit 1
fi

echo "$RELEASE_DATA"

ASSET_ID=$(echo $RELEASE_DATA | jq -r ".assets | map(select(.name == \"${INPUT_FILE}\"))[0].id")
echo "Asset ID: $ASSET_ID"

TAG_VERSION=$(echo $RELEASE_DATA | jq -r ".tag_name" | sed -e "s/^v//" | sed -e "s/^v.//")
echo "Tag version: $TAG_VERSION"

if [[ -z "$ASSET_ID" ]]; then
  echo "Could not find asset id"
  exit 1
fi

curl \
  -J \
  -L \
  -u :$TOKEN \
  -H "Accept: application/octet-stream" \
  "$GITHUB_API_URL/repos/$REPO/releases/assets/$ASSET_ID" \
  -o ${INPUT_FILE}

echo "::set-output name=version::$TAG_VERSION"
