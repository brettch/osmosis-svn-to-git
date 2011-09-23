#!/bin/sh


branch_svn_branches_to_local() {
	git for-each-ref --format='%(refname)' 'refs/remotes/tags/*' | while read TAG_REFERENCE; do
		echo "Processing tag reference: ${TAG_REFERENCE}"
		# Get the bare tag name from the complete reference path
		TAG_NAME=${TAG_REFERENCE#refs/remotes/tags/}
		echo TAG_NAME: $TAG_NAME

		git branch svntags/${TAG_NAME} $TAG_REFERENCE
	done

	git for-each-ref --format='%(refname)' 'refs/remotes/*' | while read BRANCH_REFERENCE; do
		echo "Processing branch reference: ${BRANCH_REFERENCE}"
		if echo "${BRANCH_REFERENCE}" | grep "refs/remotes/git-svn" > /dev/null; then
			# Ignore the branch representing trunk on a flat repo
			true

		elif echo "${BRANCH_REFERENCE}" | grep "refs/remotes/trunk" > /dev/null; then
			# Ignore the branch representing trunk on a structured repo
			true

		else
			# Get the branch name from the complete reference path
			BRANCH_NAME=${BRANCH_REFERENCE#refs/remotes/}
			echo BRANCH_NAME: $BRANCH_NAME

			git branch svnbranches/${BRANCH_NAME} $BRANCH_REFERENCE

		fi
	done
}


branch_svn_branches_to_target() {
	git branch -r | grep "/master$" | while read REMOTE_BRANCH; do
		echo "Creating local branch for remote svn trunk branch: ${REMOTE_BRANCH}"
		REMOTE_NAME=$(echo -n "${REMOTE_BRANCH}" | cut -d "/" -f 1)
		git branch "svntrunks/${REMOTE_NAME}" "remotes/${REMOTE_BRANCH}"
	done
	git branch -r | grep "/svntags/" | while read REMOTE_BRANCH; do
		echo "Creating local branch for remote svn tag branch: ${REMOTE_BRANCH}"
		TAG_NAME=$(echo -n "${REMOTE_BRANCH}" | cut -d "/" -f 3)
		git branch "svntags/${TAG_NAME}" "remotes/${REMOTE_BRANCH}"
	done
	git branch -r | grep "/svnbranches/" | while read REMOTE_BRANCH; do
		echo "Creating local branch for remote svn branch branch: ${REMOTE_BRANCH}"
		BRANCH_NAME=$(echo -n "${REMOTE_BRANCH}" | cut -d "/" -f 3)
		git branch "svnbranches/${BRANCH_NAME}" "remotes/${REMOTE_BRANCH}"
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


rewrite_branches() {
	git branch | while read BRANCH; do
		if [ "${BRANCH}" = "* master" ]; then
			BRANCH="master"
		fi
		echo "Re-writing branch ${BRANCH}"

		git checkout "$BRANCH"
		git filter-branch
		# Remove the backups of the updated references.
		# If you don't do this the subsequent loop will fail when it finds a reference backup already existing.
		# In addition, we will never need the original references again.
		rm -rf .git/refs/original
	done
	git checkout master
}


USERS_FILE=`pwd`/../users.txt
echo "${USERS_FILE}"

cd data

rm -rf *.git

# Clone each time range into its own git repo.
# Clone all svn tags into local branches so they're visible as remotes in the target repo.
# * Convert refs/remotes/tags/<tag> into svntags/<tag>
# Clone all svn branches into local branches so they're visible as remotes in the target repo.
# * Convert refs/remotes/<branch> into svnbranches/<branch>
# * Ignore refs/remotes/git-svn (flat repo) and refs/remotes/trunk (structured repo) which are already created as the local master branch

# Create a target repo with remotes pointing at the range repos.
# * Create remotes
# * Fetch each remote
# Create local branches for all remote svn branches and tags.
# Checkout latest range master as the current master.
# Graft the various ranges together on the master line.
# Filter all branches to re-write according to grafts and remove grafts.
# Create grafts to fix broken tags.
# * Tag 0.4 was re-tagged and the parent commit of the final tag shows up as being the initial tag.  Reset the parent of the tag to be the correct trunk revision.
# Tag 0.28 is missing its parent because it was copied from a revision that didn't exist in the range repository it originated from (ie. copied from trunk in an earlier range).
# Tag 0.32 was modified after creation to fix an artefact version in the maven POM.  That can't be changed now.
# Tag 0.35.1 was re-tagged to fix the version number in ant and update changes.txt.
# Filter all branches to re-write according to grafts and remove grafts.


# Retrieve the conduit part of the repo which existed up to revision 471
mkdir conduit.git
cd conduit.git
git svn init file://`pwd`/../bhmain-sync/conduit
git svn fetch -r417:471 -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the osmosis part of the repo which existed without trunk/tags/branches from revisions 427 to 474, and name it "bhsimple"
mkdir bhsimple.git
cd bhsimple.git
git svn init file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r473:474 -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the osmosis part of the repo which existed with trunk/tags/branches from revisions 476 to HEAD, and name it "bhstdlayout"
mkdir bhstdlayout.git
cd bhstdlayout.git
git svn init -s file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r476:HEAD -A "${USERS_FILE}"
branch_svn_branches_to_local
if false; then
# Tag 0.4 was re-tagged and the parent commit of the final tag shows up as being the initial tag.
# Reset the parent of the tag to be the correct trunk revision.
echo "`git rev-parse refs/heads/svntags/0.4` `git rev-parse ":/Fixed the osmosis launch script to reflect the updated mysql jar file."`" >> .git/info/grafts
git checkout svntags/0.4
git filter-branch
rm .git/info/grafts
git checkout master
fi
cd ..

# Retrieve the part of the repo which existed without trunk/tags/branches from revisions 4743 to 12410, and name it "osmsimple"
mkdir osmsimple.git
cd osmsimple.git
git svn init file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r4743:12410 -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the part of the repo which existed with trunk/tags/branches from revisions 12412 to HEAD, and name it "osmstdlayout"
mkdir osmstdlayout.git
cd osmstdlayout.git
git svn init -s file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r12412:HEAD -A "${USERS_FILE}"
branch_svn_branches_to_local
if false; then
# Tag 0.28 is missing its parent because it doesn't exist in this repository, we need to graft it in the final repository. (TODO: Fix in final repository)
# Tag 0.32 was modified after creation to fix an artefact version in the maven POM.  That can't be changed now.
# Tag 0.35.1 was re-tagged to fix the version number in ant and update changes.txt.
echo "`git rev-parse refs/heads/svntags/0.35.1` `git rev-parse ":/Updated changes.txt with the fixes applied in this version."`" >> .git/info/grafts
git checkout svntags/0.35.1
git filter-branch
rm .git/info/grafts
git checkout master
fi
cd ..

# Create a target repository and add remotes to the other repos.
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

# Create local branches of all remote svn branches and tags
branch_svn_branches_to_target

# Graft the branches together.
graft_branches svntrunks/conduit svntrunks/bhsimple
graft_branches svntrunks/bhsimple svntrunks/bhstdlayout
graft_branches svntrunks/bhstdlayout svntrunks/osmsimple
graft_branches svntrunks/osmsimple svntrunks/osmstdlayout

# Build master off the last branch.
git branch master svntrunks/osmstdlayout
git checkout

# Re-build the history based on the grafts file.
rewrite_branches
rm .git/info/grafts

