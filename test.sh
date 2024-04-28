#!/bin/sh
set -e

TESTDIR=test.$$
mkdir -p $TESTDIR
cleanup() {
	rm -rf $TESTDIR
}
trap cleanup EXIT

./gen-checksums.sh 1.19.1 > $TESTDIR/checksums
./gen-checksums.sh 1.20.1 >> $TESTDIR/checksums

# Download 1.19.1
./goboot.sh 1.19.1 $TESTDIR/checksums $TESTDIR/deps $TESTDIR/bin $TESTDIR/cache
$TESTDIR/bin/go version | grep -q 1.19.1

# Update to 1.20.1
./goboot.sh 1.20.1 $TESTDIR/checksums $TESTDIR/deps $TESTDIR/bin $TESTDIR/cache
$TESTDIR/bin/go version | grep -q 1.20.1

# Download to another place, cache is present
./goboot.sh 1.19.1 $TESTDIR/checksums $TESTDIR/deps2 $TESTDIR/bin2 $TESTDIR/cache
$TESTDIR/bin2/go version | grep -q 1.19.1

echo "Test succeeded"
