#!/bin/sh

TAG_REF_PREFIX=refs/remotes/tags/

fix_repository() {
	# Process all of the branches created from the SVN tags and convert to annotated tags
	git for-each-ref --format='%(refname)' 'refs/heads/svntags/*' | while read TAG_REFERENCE; do
		echo $TAG_REFERENCE

		# Get the bare tag name from the complete reference path
		TAG_NAME=${TAG_REFERENCE#refs/heads/svntags/}
		echo TAG_NAME: $TAG_NAME

		# Get the data that the branch object points to.  The ":" is followed by the
		# path to retrieve which when left empty means the root.
		DATA=$( git rev-parse "$TAG_REFERENCE": )
		echo DATA: $DATA

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
		echo PARENT: $PARENT

		# if this ancestor is in trunk then we can just tag it
		# otherwise the tag has diverged from trunk and it's actually more like a
		# branch than a tag
		MERGE_BASE=$( git merge-base "refs/remotes/trunk" $PARENT )
		echo MERGE_BASE: $MERGE_BASE
		if [ "$MERGE_BASE" = "$PARENT" ]; then
			TARGET_REFERENCE=$PARENT
		else
			echo "Tag $TAG_NAME was modified after copying from trunk"
			TARGET_REFERENCE="$TAG_REFERENCE"
		fi

		# Create an annotated tag using the commit message used to create the SVN tag.
		git show -s --pretty='format:%B' "$TAG_REFERENCE" | \
			env \
				GIT_COMMITTER_NAME="$(  git show -s --pretty='format:%an' "$TAG_REFERENCE" )" \
				GIT_COMMITTER_EMAIL="$( git show -s --pretty='format:%ae' "$TAG_REFERENCE" )" \
				GIT_COMMITTER_DATE="$(  git show -s --pretty='format:%ad' "$TAG_REFERENCE" )" \
        		git tag -a -F - "$TAG_NAME" "$TARGET_REFERENCE"
	done
}

cd data

if false; then
rm -rf bhstdlayout.git
cp -a bhstdlayout.git.bak bhstdlayout.git

cd bhstdlayout.git
fix_repository
cd ..
fi

rm -rf osmstdlayout.git
cp -a osmstdlayout.git.bak osmstdlayout.git

cd osmstdlayout.git
fix_repository
cd ..

