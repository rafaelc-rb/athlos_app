#!/usr/bin/env bash
# Build release with Supabase dart-defines.
# Usage: ./scripts/build_release.sh [appbundle|ipa]
# Requires .env in project root with SUPABASE_URL and SUPABASE_ANON_KEY.

set -e
cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
  echo "Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set."
  echo "Create a .env file in the project root (see .env.example) or export them."
  exit 1
fi

TARGET="${1:-appbundle}"
DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

case "$TARGET" in
  appbundle)
    flutter build appbundle --release $DEFINES
    echo "AAB: build/app/outputs/bundle/release/app-release.aab"
    ;;
  ipa)
    flutter build ipa $DEFINES
    echo "IPA: build/ios/ipa/"
    ;;
  *)
    echo "Usage: $0 [appbundle|ipa]"
    exit 1
    ;;
esac
