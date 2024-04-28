#!/bin/sh
set -e

VERSION=$1
CHECKSUM_FILE="$2"
DEST_DIR="$3"
BIN_DIR="$4"
CACHE_DIR="${5:-$HOME/.cache/goboot}"

usage() {
  printf "Usage: bootstrap.sh <version> <checksum file> <dest dir> [<bin dir> [<cache dir>]]" >&2
  exit 2
}

if [ $# -lt 3 -o $# -gt 5 ]; then
  usage
fi

case $MACHTYPE in
  x86_64-apple-darwin*)
    OS=darwin
    ARCH=amd64;;
  arm64-apple-darwin*)
    OS=darwin
    ARCH=arm64;;
  x86_64-*linux*)
    OS=linux
    ARCH=amd64;;
  aarch64-*linux*)
    OS=linux
    ARCH=arm64;;
  *)
    echo "Unknown OS/architecture: $MACHTYPE" >&2
    exit 1;;
esac

GO_DIR="$DEST_DIR/go-${VERSION}-${OS}-${ARCH}"

fatal() {
  echo FATAL: "$@" >&2
  exit 255
}

sha256_check() { # $1=file $2=checksum
  if [ -x "$(command -v sha256sum)" ]; then
    echo "$2  $1" | sha256sum --status -c -
  elif [ -x "$(command -v shasum)" ]; then
    shasum -s -a 256 -c -
  else
    fatal Need sha256sum or shasum
  fi
}

dl() { # $1=dest $2=url
  if [ -x "$(command -v curl)" ]; then
    curl --continue-at - --location --show-error --retry 5 --no-progress-meter --output "$2" "$1"
  elif [ -x "$(command -v wget)" ]; then
    wget --continue --no-verbose --tries 5 --output-document="$2" "$1"
  else
    fatal Need curl or wget
  fi
}

get() { # $1=dest $2=url $3=checksum
  if [ -f "$1" ]; then
    return
  fi
  local tempfile
  tempfile="$(mktemp $1.XXXXXXXX)"
  dl $2 "$tempfile"
  if ! sha256_check "$tempfile" $3; then
    rm -f "$tempfile"
    fatal Checksum verification failed
  fi
  mv "$tempfile" "$1"
}

get_checksum() { # $1=version $2=os $3=arch
  while read version os arch checksum; do
    if [ "$version" = "$1" -a "$os" = "$2" -a "$arch" = "$3" ]; then
      echo "$checksum"
      return
    fi
  done < "$CHECKSUM_FILE"

  fatal "Haven't found a checksum for $1-$2-$3"
}

get_go() {
  echo "Downloading Go $VERSION-$OS-$ARCH..."

  # do not merge with assignments, or exit code from subshells is lost
  local url csum cachefile tempdir

  url=https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz
  csum=$(get_checksum "$VERSION" "$OS" "$ARCH")
  cachefile="$CACHE_DIR/$VERSION-$OS-$ARCH-$csum"

  mkdir -p "$CACHE_DIR"
  get "$cachefile" $url "$csum"

  mkdir -p "$DEST_DIR"
  tempdir="$(mktemp -d "${GO_DIR}.XXXXXXXX")"
  tar -m --strip-components 1 -C "$tempdir" -x -f "$cachefile"
  rm -rf "$GO_DIR"
  mv -f "$tempdir" "$GO_DIR"
}

realpath_relative() { # $1=from $2=to $3=go binary path
  if realpath --help 2>&1 | grep -q relative-to; then
    realpath --relative-to="$2" "$1"
  elif grealpath --help 2>&1 | grep -q relative-to; then # GNU Coreutils on macOS in Homebrew
    grealpath --relative-to="$2" "$1"
  else
    "$3" run github.com/dottedmag/realpath-fallback@v1.0.0 "$1" "$2"
  fi
}

update_link() { # $1=from $2=to_dir $3=to
  if ! [ "$1" -ef "$2/$3" ]; then
    mkdir -p "$2"
    ln -snf "$(realpath_relative "$1" "$2")" "$2/$3"
  fi
}

ensure_go() {
  if ! [ -f "$GO_DIR/bin/go" ]; then
    get_go
  fi
  if [ -n "$BIN_DIR" ]; then
    update_link "$GO_DIR/bin/go" "$BIN_DIR" go
    update_link "$GO_DIR/bin/gofmt" "$BIN_DIR" gofmt
  fi
}

ensure_go
