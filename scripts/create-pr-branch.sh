#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <your-fork-clone-url>"
  echo "Example: $0 git@github.com:jmatias/ccmenu2.git"
  exit 2
fi

REPO_URL="$1"
BRANCH="feature/aws-codepipeline-ui"
WORKDIR="$(mktemp -d)"
echo "Working dir: $WORKDIR"

git clone "$REPO_URL" "$WORKDIR/ccmenu2"
cp -R CCMenu "$WORKDIR/ccmenu2/"
cp -R Tests "$WORKDIR/ccmenu2/" || true
cp -R scripts "$WORKDIR/ccmenu2/" || true

pushd "$WORKDIR/ccmenu2" >/dev/null
git checkout -b "$BRANCH"
git add CCMenu/Servers/CodePipeline Tests/CodePipelineUIProviderTests.swift || true
git commit -m "Add AWS CodePipeline provider + settings UI (shared profile, region)"
git push -u origin "$BRANCH"

echo
echo "Branch pushed: $BRANCH"
echo "Open a PR on GitHub and add the SPM dependency: https://github.com/awslabs/aws-sdk-swift (AWSCodePipeline, AWSClientRuntime)."
popd >/dev/null