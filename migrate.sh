#!/bin/sh

set -x

function sync_repo() {
	local REPO_NAME=$1
	local SRC_REPO_URL=$2
	local DST_REPO_URL=file://`pwd`/${REPO_NAME}

	if [ ! -d "${REPO_NAME}" ]; then
                rm -rf "${REPO_NAME}"
                svnadmin create "${REPO_NAME}"
                echo "#!/bin/sh" > "${REPO_NAME}"/hooks/pre-revprop-change
                chmod +x "${REPO_NAME}"/hooks/pre-revprop-change

                svnsync init "${DST_REPO_URL}" "${SRC_REPO_URL}" 
        fi

        svnsync sync "${DST_REPO_URL}"
}


function init_target_repo() {
	if [ -d target ]; then
		rm -rf target
	fi
	svnadmin create target
	if [ -d target-wc ]; then
		rm -rf target-wc
	fi
	# Allow properties to be manipulated.
	echo "#!/bin/sh" > target/hooks/pre-revprop-change
	chmod +x target/hooks/pre-revprop-change
	# Initialise the repo to contain the standard trunk/tags/branches layout.
	svn co file://`pwd`/target target-wc
	mkdir target-wc/trunk
	mkdir target-wc/tags
	mkdir target-wc/branches
	svn add --depth infinity target-wc/*
	svn commit target-wc -m "GIT Migration.  Created SVN migration repository structure."
	# Manipulate the timestamp of initial checkin to match the first osmosis commit.
	svn propset -r 1 --revprop "svn:date" "2007-04-04T12:58:38.510894Z" file://`pwd`/target
}


function get_line_number() {
	local INFILE=$1
	local STARTLINE=$2
	local PATTERN=$3
	local LINE

	# Find the matching line.  It will have the line number followed by a ':' character.
	LINE=$(cat "${INFILE}" | sed -n -e "${STARTLINE},"'${p}' | grep -n -m 1 --binary-files=text "^${PATTERN}$")

	# Strip off the trailing text leaving just the line number.
	LINE=$(echo "${LINE}" | cut -d ":" -f 1)

	# Add the start offset back to the result
	let LINE=$LINE+$STARTLINE-1

	echo "${LINE}"
}


function delete_dump_section() {
	local DUMPFILE=$1
	local START_PATTERN=$2
	local FINISH_PATTERN=$3
	local START_LINE
	local FINISH_LINE

	START_LINE=$(get_line_number "${DUMPFILE}" 1 "${START_PATTERN}")
	FINISH_LINE=$(get_line_number "${DUMPFILE}" "${START_LINE}" "${FINISH_PATTERN}")
	sed -i.bak -e "${START_LINE},${FINISH_LINE}d" "${DUMPFILE}"
}


function update_dump_path() {
	local DUMPFILE=$1
	local INPATH=$2
	local OUTPATH=$3

	# Escape the paths for sed.
	INPATH=$(echo "${INPATH}" | sed -e 's/\//\\\//g')
	OUTPATH=$(echo "${OUTPATH}" | sed -e 's/\//\\\//g')

	# Update the dump file with the new paths.
	sed -i.bak -e 's/^Node-path: '"${INPATH}"'/Node-path: '"${OUTPATH}"'/;s/^Node-copyfrom-path: '"${INPATH}"'/Node-copyfrom-path: '"${OUTPATH}"'/' "${DUMPFILE}"
}


function update_copyfrom_revision() {
	local DUMPFILE=$1
	local REVISION=$2
	local NODE=$3
	local OLD_COPYFROM=$4
	local NEW_COPYFROM=$5
	local LINE

	# Go to the revision
	LINE=$(get_line_number "${DUMPFILE}" 1 "Revision-number: ${REVISION}")
	# Go to the node to be updated
	LINE=$(get_line_number "${DUMPFILE}" "$LINE" "Node-path: ${NODE}")
	# Go to the copyfrom line
	LINE=$(get_line_number "${DUMPFILE}" "$LINE" "Node-copyfrom-rev: ${OLD_COPYFROM}")

	# Replace the line with the new copyfrom revision
	sed -i.bak -e "${LINE}"'c\'"Node-copyfrom-rev: ${NEW_COPYFROM}" "${DUMPFILE}"
}


function update_copyfrom_path() {
	local DUMPFILE=$1
	local REVISION=$2
	local NODE=$3
	local OLD_COPYFROM=$4
	local NEW_COPYFROM=$5
	local LINE

	# Escape the paths for sed.
	OLD_COPYFROM=$(echo "${OLD_COPYFROM}" | sed -e 's/\//\\\//g')
	NEW_COPYFROM=$(echo "${NEW_COPYFROM}" | sed -e 's/\//\\\//g')

	# Go to the revision
	LINE=$(get_line_number "${DUMPFILE}" 1 "Revision-number: ${REVISION}")
	# Go to the node to be updated
	LINE=$(get_line_number "${DUMPFILE}" "$LINE" "Node-path: ${NODE}")
	# Go to the copyfrom line
	LINE=$(get_line_number "${DUMPFILE}" "$LINE" "Node-copyfrom-path: ${OLD_COPYFROM}")

	# Replace the line with the new copyfrom revision
	sed -i.bak -e "${LINE}"'c\'"Node-copyfrom-path: ${NEW_COPYFROM}" "${DUMPFILE}"
}


#sync_repo bhmain-sync https://www.bretth.com/repos/main
#sync_repo osm-sync http://svn.openstreetmap.org
if false; then
# Create a new repository to contain the complete history.
init_target_repo

# Select the conduit data from the bh repo.  Start from 417 (first revision) to avoid 0 revision.  Stop at 471 when the project was renamed from conduit to osmosis.
svnadmin dump bhmain-sync -r 417:471 | svndumpfilter include --drop-empty-revs conduit osmosis > osmosis.dmp

# Remove the first addition of conduit because we don't want to add the root directory.
delete_dump_section osmosis.dmp "Node-path: conduit" "PROPS-END"

# Remove the conduit portion of the path from all entries and replace with trunk.
update_dump_path osmosis.dmp "conduit" "trunk"

# Load the conduit history into the target repo.
svnadmin load target < osmosis.dmp

# Select the osmosis data from the bh repo.  Start from 473 (472 is a simple rename from conduit to osmosis which is irrelevant because we're importing to the repository root).  Stop at 474 which is immediately prior to the creation of trunk/tags/branches structure.
svnadmin dump bhmain-sync -r 473:474 --incremental | svndumpfilter include --drop-empty-revs conduit osmosis > osmosis.dmp

# Remove the osmosis portion of the path from all entries and replace with trunk.
update_dump_path osmosis.dmp "osmosis" "trunk"

# Load the osmosis history into the target repo.
svnadmin load target < osmosis.dmp

# Select the remaining osmosis data from the bh repo.  Start from 476 (475 is the re-organisation into trunk/tags/branches structure which we've already done).
svnadmin dump bhmain-sync -r 476:HEAD --incremental | svndumpfilter include --drop-empty-revs conduit osmosis > osmosis.dmp

# Remove the osmosis portion of the path from all entries.
update_dump_path osmosis.dmp "osmosis" ""

# Load the osmosis history into the target repo.
svnadmin load target < osmosis.dmp

# Select the initial history of osmosis from the osm repo.  Start from 4743 because that is the first revision *after* Osmosis being imported.  4742 contains the same data we've already imported from the bh repo.  Stop at 12410 because that's immediately prior to creation of trunk/tags/branches.
svnadmin dump osm-sync -r 4743:12410 --incremental | svndumpfilter include --drop-empty-revs /applications/utils/osmosis > osmosis.dmp

# Remove the first addition of osmosis because we don't want to add the root directory.
delete_dump_section osmosis.dmp "Node-path: applications/utils/osmosis" "PROPS-END"

# Remove the osmosis portion of the path from all entries and replace with trunk.
update_dump_path osmosis.dmp "applications/utils/osmosis" "trunk"

# Work around bug in svnadmin load.  Revision 8900 refers to TaskRegistrar from revision 8745 but going back 155 revisions fails in the new repo.  It hasn't changed since 8745 so update the reference to be 8899 (ie. the latest).
update_copyfrom_revision osmosis.dmp 8900 "trunk/src/com/bretth/osmosis/core/pipeline/common/TaskConfiguration.java" 8745 8899
# And more missing or invalid references ...
update_copyfrom_revision osmosis.dmp 10356 "trunk/src/com/bretth/osmosis/core/pgsql/v0_6/impl/EntityFeatureTableReader.java" 10160 10355
update_copyfrom_revision osmosis.dmp 10596 "trunk/src/com/bretth/osmosis/core/pgsql/common/BaseDao.java" 10571 10595

# Load the osmosis history into the target repo.
svnadmin load target < osmosis.dmp

else
        rm -rf target
        cp -a target.bak target
fi

# Select the remaining osmosis data from the osm repo.  Start from 12412 (12411 is the re-organisation into trunk/tags/branches structure which we've already done).
#svnadmin dump osm-sync -r 12412:HEAD --incremental | svndumpfilter include --drop-empty-revs "/applications/utils/osmosis" > osmosis.dmp

# Fix 0.28 and 0.29 tag copyfrom paths which were copied from a revision prior to the creation of trunk/tags/branches.
#update_copyfrom_path osmosis.dmp 12415 "applications/utils/osmosis/tags/0.29" "applications/utils/osmosis" "trunk"
#update_copyfrom_path osmosis.dmp 12416 "applications/utils/osmosis/tags/0.28" "applications/utils/osmosis" "trunk"

# Remove the osmosis portion of the path from all entries and replace with trunk.
#update_dump_path osmosis.dmp "applications/utils/osmosis" ""

# Fix copyfrom offsets.
update_copyfrom_revision osmosis.dmp 12415 "/tags/0.29" 8733 12304
update_copyfrom_revision osmosis.dmp 12416 "/tags/0.28" 7950 12277
update_copyfrom_revision osmosis.dmp 14515 "/trunk/src/org/openstreetmap/osmosis/core/apidb/v0_6/ApidbVersionConstants.java" 14498 14514
update_copyfrom_revision osmosis.dmp 15229 "/trunk/src/org/openstreetmap/osmosis/core/apidb/v0_6/impl/EntityDao.java" 15066 15228
update_copyfrom_revision osmosis.dmp 15980 "/trunk/src/org/openstreetmap/osmosis/core/merge/v0_6/IntervalDownloader.java" 15739 15979
update_copyfrom_revision osmosis.dmp 15980 "/trunk/src/org/openstreetmap/osmosis/core/merge/v0_6/IntervalDownloaderFactory.java" 15739 15979
update_copyfrom_revision osmosis.dmp 15980 "/trunk/src/org/openstreetmap/osmosis/core/merge/v0_6/IntervalDownloaderInitializer.java" 15739 15979

# Load the osmosis history into the target repo.
svnadmin load target < osmosis.dmp

