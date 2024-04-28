# goboot

A bootstrap script to get you a specific version of Go installed.
It's fast enough on fast path to run any time you need Go.

It's tested on `darwin-arm64`, `linux-amd64` and `linux-arm64`,
and will be extended to other OS/arch combinations as the need arises.

Drop it into your project and run:

```
goboot.sh <version> <checksum file> <dest directory> [<bin directory> [<cache directory>]]
```
where

* version is the Go version, like `1.20.1`
* version file is the file with checksums, see below
* "dest directory" is the directory to download Go to.
* "bin directory" is the directory to link `go` and `gofmt` to. No linking is done if not specified.
* "cache directory" is a directory to use as a cache. Defaults to `~/.cache/goboot/`

## Checksum file

Checksum file has format
```
<version> <os> <arch> <sha256sum>
```
where `os` and `arch` are in Go format.

Use `gen-checksums.sh` to generate file in this format.

## Dependencies

This script requires:
- POSIX shell as `/bin/sh`, and basic utilities like `tar`, `rm`, `ln`, `mkdir`
- `curl` >= 7.67 or `wget`
- `sha256sum` or `shasum`

`gen-checksums.sh` additionally requires `jq`.
