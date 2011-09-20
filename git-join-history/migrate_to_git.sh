#!/bin/sh


branch_svn_tags_to_local() {
	git for-each-ref --format='%(refname)' 'refs/remotes/tags/*' | while read TAG_REFERENCE; do
		# Get the bare tag name from the complete reference path
		TAG_NAME=${TAG_REFERENCE#refs/remotes/tags/}
		echo TAG_NAME: $TAG_NAME

		git branch svntags/${TAG_NAME} $TAG_REFERENCE
	done
}


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
branch_svn_tags_to_local
cd ..

# Retrieve the osmosis part of the repo which existed without trunk/tags/branches from revisions 427 to 474, and name it "bhsimple"
mkdir bhsimple.git
cd bhsimple.git
git svn init file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r473:474 -A "${USERS_FILE}"
branch_svn_tags_to_local
cd ..

# Retrieve the osmosis part of the repo which existed with trunk/tags/branches from revisions 476 to HEAD, and name it "bhstdlayout"
mkdir bhstdlayout.git
cd bhstdlayout.git
git svn init -s file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r476:HEAD -A "${USERS_FILE}"
branch_svn_tags_to_local
# Tag 0.4 was re-tagged and the parent commit of the final tag shows up as being the initial tag.
# Reset the parent of the tag to be the correct trunk revision.
echo "`git rev-parse refs/heads/svntags/0.4` `git rev-parse ":/Fixed the osmosis launch script to reflect the updated mysql jar file."`" >> .git/info/grafts
git checkout svntags/0.4
git filter-branch
rm .git/info/grafts
git checkout master
cd ..

# Retrieve the part of the repo which existed without trunk/tags/branches from revisions 4743 to 12410, and name it "osmsimple"
mkdir osmsimple.git
cd osmsimple.git
git svn init file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r4743:12410 -A "${USERS_FILE}"
branch_svn_tags_to_local
cd ..

# Retrieve the part of the repo which existed with trunk/tags/branches from revisions 12412 to HEAD, and name it "osmstdlayout"
mkdir osmstdlayout.git
cd osmstdlayout.git
git svn init -s file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r12412:HEAD -A "${USERS_FILE}"
branch_svn_tags_to_local
# Tag 0.28 is missing its parent because it doesn't exist in this repository, we need to graft it in the final repository. (TODO: Fix in final repository)
# Tag 0.32 was modified after creation to fix an artefact version in the maven POM.  That can't be changed now.
# Tag 0.35.1 was re-tagged to fix the version number in ant and update changes.txt.
echo "`git rev-parse refs/heads/svntags/0.35.1` `git rev-parse ":/Updated changes.txt with the fixes applied in this version."`" >> .git/info/grafts
git checkout svntags/0.35.1
git filter-branch
rm .git/info/grafts
git checkout master
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

