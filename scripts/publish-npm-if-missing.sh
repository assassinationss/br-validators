#!/usr/bin/env bash
# Publish a workspace package only when that exact version is not on npm yet.
# Used by .github/workflows/release.yml — CI-only (see assert-ci-publish.mjs).
set -euo pipefail

FILTER="${1:?filter name (e.g. @br-validators/core)}"
NPM_NAME="${2:?npm package name}"
VERSION="${3:?semver}"
NPM_TAG="${4:?dist-tag (latest|alpha|beta|rc)}"

if npm view "${NPM_NAME}@${VERSION}" version 2>/dev/null | grep -qx "${VERSION}"; then
  echo "SKIP: ${NPM_NAME}@${VERSION} already on npm"
else
  if [ -z "${NODE_AUTH_TOKEN:-}" ] && [ -z "${NPM_TOKEN:-}" ]; then
    echo "::error::Missing npm auth token (NODE_AUTH_TOKEN/NPM_TOKEN) — cannot publish ${NPM_NAME}@${VERSION}." >&2
    echo "Configure repository secret NPM_TOKEN as an Automation (or granular, publish-enabled) token for @br-validators/*." >&2
    echo "Classic tokens that bypass 2FA are deprecated by npm (see https://gh.io/npm-gat-bypass2fa-deprecation)." >&2
    exit 1
  fi
  echo "PUBLISH: ${NPM_NAME}@${VERSION} (tag ${NPM_TAG})"
  set +e
  pnpm --filter "${FILTER}" publish --access public --tag "${NPM_TAG}" --no-git-checks
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    echo "::error::Failed to publish ${NPM_NAME}@${VERSION} (exit $status). npm PUT 404 usually means the token lacks publish permission." >&2
    echo "Check: NPM_TOKEN is a valid Automation/granular token with read/write + create on @br-validators/*," >&2
    echo "not expired/revoked, and 2FA is satisfied (Automation tokens bypass 2FA by design)." >&2
    echo "See https://gh.io/npm-gat-bypass2fa-deprecation for the 2FA-bypass token deprecation." >&2
    exit "$status"
  fi
fi
