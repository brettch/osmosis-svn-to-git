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


convert_svn_branches_to_tags() {
	# Process all of the branches created from the SVN tags and convert to annotated tags
	git for-each-ref --format='%(refname)' 'refs/heads/svntags/*' | while read TAG_REFERENCE; do
		echo $TAG_REFERENCE

		# Get the bare tag name from the complete reference path
		TAG_NAME=${TAG_REFERENCE#refs/heads/svntags/}
		echo "Processing tag : $TAG_NAME"

		# Get the data that the branch object points to.  The ":" is followed by the
		# path to retrieve which when left empty means the root.
		DATA=$( git rev-parse "$TAG_REFERENCE": )

		# Search back through the revision history to find the first commit that the
		# data was created in its current state.  In other words, we want to strip off
		# revisions that were used to create the tag path in SVN, but didn't modify
		# the underlying data.
		PARENT_REFERENCE="$TAG_REFERENCE";
		echo PARENT_REFERENCE: $PARENT_REFERENCE
		while [ $( git rev-parse --quiet --verify "$PARENT_REFERENCE"^: ) = "$DATA" ]; do
			PARENT_REFERENCE="$PARENT_REFERENCE"^
			echo PARENT_REFERENCE: $PARENT_REFERENCE
		done
		PARENT=$( git rev-parse "$PARENT_REFERENCE" )

		# if this ancestor is in trunk then we can just tag it
		# otherwise the tag has diverged from trunk and it's actually more like a
		# branch than a tag
		MERGE_BASE=$( git merge-base master $PARENT )
		if [ ! "$MERGE_BASE" = "$PARENT" ]; then
			echo "Check tag $TAG_NAME.  It appears to have been modified after branching from trunk, perhaps it was re-created and needs to be git grafted accordingly."
		fi
		TARGET_REFERENCE=$PARENT

		# Create an annotated tag using the commit message used to create the SVN tag.
		git show -s --pretty='format:%B' "$TAG_REFERENCE" | \
			env \
				GIT_COMMITTER_NAME="$(  git show -s --pretty='format:%an' "$TAG_REFERENCE" )" \
				GIT_COMMITTER_EMAIL="$( git show -s --pretty='format:%ae' "$TAG_REFERENCE" )" \
				GIT_COMMITTER_DATE="$(  git show -s --pretty='format:%ad' "$TAG_REFERENCE" )" \
			git tag -a -F - "$TAG_NAME" "$TARGET_REFERENCE"

		# Remove the now redundant tag branch.
		git update-ref -d "$TAG_REFERENCE"
	done
}


USERS_FILE=`pwd`/../users.txt
echo "${USERS_FILE}"

cd data

# Remove all git repositories created by a previous run of the script.
rm -rf *.git

# Retrieve the conduit part of the repo which existed up to revision 471
mkdir conduit.git
cd conduit.git
git svn init --no-metadata file://`pwd`/../bhmain-sync/conduit
git svn fetch -r417:471 -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the osmosis part of the repo which existed without trunk/tags/branches from revisions 427 to 474, and name it "bhsimple"
mkdir bhsimple.git
cd bhsimple.git
git svn init --no-metadata file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r473:474 -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the osmosis part of the repo which existed with trunk/tags/branches from revisions 476 to HEAD, and name it "bhstdlayout"
mkdir bhstdlayout.git
cd bhstdlayout.git
git svn init --no-metadata -s file://`pwd`/../bhmain-sync/osmosis
git svn fetch -r476:HEAD -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the part of the repo which existed without trunk/tags/branches from revisions 4743 to 12410, and name it "osmsimple"
mkdir osmsimple.git
cd osmsimple.git
git svn init --no-metadata file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r4743:12410 -A "${USERS_FILE}"
branch_svn_branches_to_local
cd ..

# Retrieve the part of the repo which existed with trunk/tags/branches from revisions 12412 to HEAD, and name it "osmstdlayout"
mkdir osmstdlayout.git
cd osmstdlayout.git
git svn init --no-metadata -s file://`pwd`/../osm-sync/applications/utils/osmosis
git svn fetch -r12412:26690 -A "${USERS_FILE}"
branch_svn_branches_to_local
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

# Remove the remotes which are unnecessary now that we have local branches.
git remote rm conduit
git remote rm bhsimple
git remote rm bhstdlayout
git remote rm osmsimple
git remote rm osmstdlayout

# Graft the trunk ranges together.
graft_branches svntrunks/conduit svntrunks/bhsimple
graft_branches svntrunks/bhsimple svntrunks/bhstdlayout
graft_branches svntrunks/bhstdlayout svntrunks/osmsimple
graft_branches svntrunks/osmsimple svntrunks/osmstdlayout

# Build master off the last branch.
git branch master svntrunks/osmstdlayout
git checkout

# Remove old range trunks because we now have complete history in master
git branch | grep "svntrunks/" | while read TRUNK; do
	git branch -d "${TRUNK}"
done

# Tag 0.4 was re-tagged and the parent commit of the final tag shows up as being the initial tag.
# Reset the parent of the tag to be the correct trunk revision.
echo "`git rev-parse refs/heads/svntags/0.4` `git rev-parse ":/Fixed the osmosis launch script to reflect the updated mysql jar file."`" >> .git/info/grafts

# Tag 0.28 is missing its parent because the parent doesn't exist in the bhstdlayout repository.  It was tagged after the fact, and the
# trunk revision was in the osmsimple repo.
echo "`git rev-parse refs/heads/svntags/0.28` `git log --grep="^Updated the version to 0.28.$" --format=%H`" >> .git/info/grafts

# As above but for 0.29.
echo "`git rev-parse refs/heads/svntags/0.29` `git log --grep="^Updated to version 0.29.$" --format=%H`" >> .git/info/grafts

# Tag 0.32 was modified after creation to fix an artefact version in the maven POM.  That can't be changed now.

# Tag 0.35.1 was re-tagged to fix the version number in ant and update changes.txt.
echo "`git rev-parse refs/heads/svntags/0.35.1` `git rev-parse ":/Updated changes.txt with the fixes applied in this version."`" >> .git/info/grafts

# Tag test was created and deleted straight away in SVN.  No longer required.
git branch -D svntags/test

# The ivybuild branch is missing its trunk parent
# The branch point is missing because the branch revision was the one that did the organisation into trunk/tags/branches and we've dropped
# that revision because it's a transition point between ranges and can't be represented properly.  We need to pick the revision prior which
# contains identical code.
echo "`git log --grep="^Create a new branch for experimenting with an ivy based build.$" --format=%H svnbranches/ivybuild` `git log --grep="^Updated mysql 0.5 and 0.6 schema versions to 17 and 24 respectively.$" --format=%H`" >> .git/info/grafts
# The ivybuild branch is missing a rebase merge from trunk because no svn:mergeinfo data is available (perhaps occurred prior to SVN version 1.5)
echo "`git log --grep="^Merged the latest changes from trunk.$" --format=%H svnbranches/ivybuild` `git log --grep="^Removed jars from the repository.$" --format=%H svnbranches/ivybuild` `git log --grep="^Added new svn:ignore values.$" --format=%H`" >> .git/info/grafts
# The ivybuild branch is missing its merge point back to trunk.
# The merge point to trunk is missing because no svn:mergeinfo data is available (perhaps occurred prior to SVN version 1.5)
echo "`git log --grep="^Updated the build scripts to use Ivy dependency management.$" --format=%H` `git log --grep="^Merged in JPF support from the jpf-plugin branch.$" --format=%H` `git log --grep="^Updated the junit tests not to fork during execution.$" --format=%H svnbranches/ivybuild`" >> .git/info/grafts
# Remove the now obsolete branch.
git branch -D svnbranches/ivybuild

# The jpf-plugin branch was created three times before getting it right.  Git shows this as an initial branch followed by two merges which isn't really correct.  Update the final branch point to have a single parent in the trunk.
echo "`git log --grep="^Created a jpf-plugin branch from a (hopefully) clean and latest version of trunk.$" --format=%H svnbranches/jpf-plugin` `git log --grep="^Removed the accidental checkin of JPF code to trunk after some epic svn mishaps ... hopefully this is the last of it.$" --format=%H`" >> .git/info/grafts
# The jpf-plugin merge to trunk is missing because no svn:mergeinfo is available (perhaps occurred prior to SVN version 1.5)
echo "`git log --grep="^Merged in JPF support from the jpf-plugin branch.$" --format=%H` `git log --grep="^Removed the accidental checkin of JPF code to trunk after some epic svn mishaps ... hopefully this is the last of it.$" --format=%H` `git log --grep="^Moved the core plugin registration into a separate method.$" --format=%H svnbranches/jpf-plugin`" >> .git/info/grafts
# Remove the now obsolete branch.
git branch -D svnbranches/jpf-plugin

# The mutable branch is missing its merge point back to trunk.
# The merge point to trunk is missing because no svn:mergeinfo data is available (perhaps occurred prior to SVN version 1.5)
echo "`git log --grep="^Introduced mutable entity support.  Entities can now be modified within the pipeline without requiring cloning.$" --format=%H` `git log --grep="^Explicitly depend on version 3.2.8 of the Woodstox stax xml parser in order to fix broken build.$" --format=%H` `git log --grep="^Fixed remaining tasks and tests to no longer use the builder classes.$" --format=%H svnbranches/mutable`" >> .git/info/grafts
# Remove the now obsolete branch.
git branch -D svnbranches/mutable

# The breakup branch has full svn:mergeinfo history and has no outstanding changes on the branch.
git branch -D svnbranches/breakup

# The write-dataset branch was never used therefore has no data to graft back to trunk.
git branch -D svnbranches/write-dataset

# The 0.35-fixes branch was branched from an older trunk, then specific fixes from trunk merged into it.  No changes were ever merged back to trunk.
git branch -D svnbranches/0.35-fixes

# Re-build the history based on the grafts file.
rewrite_branches
rm .git/info/grafts

# Convert all branches representing SVN tags into GIT annotated tags.
convert_svn_branches_to_tags

# Prune all unnecessary data from the repository.
git gc --prune=now

