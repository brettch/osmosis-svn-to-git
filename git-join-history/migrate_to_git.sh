#!/bin/sh


graft_branches() {
	local PARENT=$1
	local CHILD=$2

	# Get the identifier of the last commit on the parent branch
	# Looking for the first line like: commit <sha-commit-id>
	local PARENT_LAST_COMMIT=$(git log ${PARENT}|grep "^commit "|head -1|cut -d " " -f 2)

	# Get the identifier of the first commit on the bhsimple branch
	# Looking for the last line like: commit <sha-commit-id>
	local CHILD_FIRST_COMMIT=$(git log ${CHILD}|grep "^commit "|tail -1|cut -d " " -f 2)

	# Create the graft entry
	echo "${CHILD_FIRST_COMMIT} ${PARENT_LAST_COMMIT}" >> .git/info/grafts
}


USERS_FILE=`pwd`/../users.txt
echo "${USERS_FILE}"

cd data

rm -rf *.git

# Retrieve the conduit part of the repo which existed up to revision 471
mkdir conduit.git
cd conduit.git
git svn init file://`pwd`/../bhmain-sync/conduit
git svn fetch -r417:471 -A "${USERS_FILE}"
cd ..

# Retrieve the osmosis part of the repo which existed without trunk/tags/branches from revisions 427 to 474, and name it "bhsimple"
mkdir bhsimple.git
cd bhsimple.git
git svn init file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r473:474 -A "${USERS_FILE}"
cd ..

# Retrieve the osmosis part of the repo which existed with trunk/tags/branches from revisions 476 to HEAD, and name it "bhstdlayout"
mkdir bhstdlayout.git
cd bhstdlayout.git
git svn init -s file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r476:HEAD -A "${USERS_FILE}"
cd ..

# Retrieve the part of the repo which existed without trunk/tags/branches from revisions 4743 to 12410, and name it "osmsimple"
mkdir osmsimple.git
cd osmsimple.git
git svn init file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r4743:12410 -A "${USERS_FILE}"
cd ..

# Retrieve the part of the repo which existed with trunk/tags/branches from revisions 12412 to HEAD, and name it "osmstdlayout"
mkdir osmstdlayout.git
cd osmstdlayout.git
git svn init -s file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r12412:HEAD -A "${USERS_FILE}"
cd ..

# Create a target repository and add remotes to the other repos.
rm -rf target.git
mkdir target.git
cd target.git
git init
git remote add conduit ../conduit.git
git remote add bhsimple ../bhsimple.git
git remote add bhstdlayout ../bhstdlayout.git
git remote add osmsimple ../osmsimple.git
git remote add osmstdlayout ../osmstdlayout.git

# Retrieve all data from the repositories
git fetch conduit
git fetch bhsimple
git fetch bhstdlayout
git fetch osmsimple
git fetch osmstdlayout

# Graft the branches together.
graft_branches conduit/master bhsimple/master
graft_branches bhsimple/master bhstdlayout/master
graft_branches bhstdlayout/master osmsimple/master
graft_branches osmsimple/master osmstdlayout/master

# Build master off the last branch.
git branch master osmstdlayout/master
git checkout

# Re-build the history based on the grafts file.
git filter-branch
rm .git/info/grafts

