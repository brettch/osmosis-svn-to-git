#!/bin/sh

USERS_FILE=`pwd`/../users.txt
echo "${USERS_FILE}"

cd data

rm -rf *.git

mkdir target.git
cd target.git

# Get the conduit part of the repo which existed up to revision 471, and name it "conduit"
git svn init file://`pwd`/../bhmain-sync/conduit
sed -i "s/svn-remote \"svn\"/svn-remote \"conduit\"/" .git/config

# Retrieve the conduit history
git svn fetch -r417:471 -A "${USERS_FILE}" conduit

# Point at the osmosis part of the repo which existed without trunk/tags/branches from revisions 427 to 474, and name it "bh_simple"
git svn init file://`pwd`/../bhmain-sync/osmosis
sed -i "s/svn-remote \"svn\"/svn-remote \"bh_simple\"/" .git/config

# Retrieve the bh simple history
git svn fetch -r473:474 -A "${USERS_FILE}" bh_simple

