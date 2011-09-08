#!/bin/sh

pushd .

cd data

if [ -d git-tmp ]; then
	rm -rf git-tmp
fi

git svn clone --stdlayout --no-metadata -A ../users.txt file://`pwd`/target git-tmp

popd

