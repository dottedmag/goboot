#!/bin/sh
set -e

if [ $# -gt 1 ]; then
  echo "Usage: gen-checksums [list|<version>]" >&2
  exit 2
fi

if [ "$1" = list ]; then
  curl -s "https://go.dev/dl/?mode=json&include=all" | jq -r '.[]|.version' | sed -e 's/^go//'
  exit 0
fi

VERSION="$1"
if [ -n "$VERSION" ]; then
  ALL_RELEASES=$(curl -s "https://go.dev/dl/?mode=json&include=all")
  RELEASES=$(echo "$ALL_RELEASES" | jq ".[]|select(.version==\"go$VERSION\")|.files|.[]")
else
  STABLE_RELEASES=$(curl -s "https://go.dev/dl/?mode=json")
  RELEASES=$(echo "$STABLE_RELEASES" | jq ".[]|.files|.[]")
fi

echo 'darwin amd64
darwin arm64
linux amd64
linux arm64' | while read os arch; do
  echo "$RELEASES" | jq -r "select(.os==\"$os\" and .arch==\"$arch\" and .kind==\"archive\")|\"\\(.sha256) \\(.version)\""  | while read checksum ver; do
    echo "${ver#go} $os $arch $checksum"
  done
done
