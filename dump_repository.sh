#!/bin/sh

check_errs() {
	if [ "${1}" -ne "0" ]; then
		echo "ERROR # ${1} : ${2}"
		exit ${1}
    fi
}


function sync_repo() {
	local REPO_NAME=$1
	local SRC_REPO_URL=$2
	local DST_REPO_URL=file://`pwd`/${REPO_NAME}

	if [ ! -d "${REPO_NAME}" ]; then
		rm -rf "${REPO_NAME}"
		check_errs $? "Can't remove repository"

		svnadmin create "${REPO_NAME}"
		check_errs $? "Can't create repo ${REPO_NAME}"

		echo "#!/bin/sh" > "${REPO_NAME}"/hooks/pre-revprop-change
		chmod +x "${REPO_NAME}"/hooks/pre-revprop-change

		svnsync init "${DST_REPO_URL}" "${SRC_REPO_URL}"
		check_errs $? "Can't initialise repository ${REPO_NAME} for syncing"
	fi

	svnsync sync "${DST_REPO_URL}"
	check_errs $? "Can't sync repository ${REPO_NAME}"
}

if [ ! -d "data" ]; then
	mkdir data
fi

# Synchronise the local repositories with the master repositories.
sync_repo data/bhmain-sync https://www.bretth.com/repos/main
sync_repo data/osm-sync http://svn.openstreetmap.org

# Select the conduit data from the bh repo.  Start from 417 (first revision) to avoid 0 revision.  Stop at 471 when the project was renamed from conduit to osmosis.
svnadmin dump data/bhmain-sync -r 417:471 | svndumpfilter include --drop-empty-revs conduit osmosis > data/1-bh.dmp
check_errs $? "Dump 1 failed"

# Select the osmosis data from the bh repo.  Start from 473 (472 is a simple rename from conduit to osmosis which is irrelevant because we're importing to the repository root).  Stop at 474 which is immediately prior to the creation of trunk/tags/branches structure.
svnadmin dump data/bhmain-sync -r 473:474 --incremental | svndumpfilter include --drop-empty-revs conduit osmosis > data/2-bh.dmp
check_errs $? "Dump 2 failed"

# Select the remaining osmosis data from the bh repo.  Start from 476 (475 is the re-organisation into trunk/tags/branches structure which we've already done).
svnadmin dump data/bhmain-sync -r 476:HEAD --incremental | svndumpfilter include --drop-empty-revs conduit osmosis > data/3-bh.dmp
check_errs $? "Dump 3 failed"

# Select the initial history of osmosis from the osm repo.  Start from 4743 because that is the first revision *after* Osmosis being imported.  4742 contains the same data we've already imported from the bh repo.  Stop at 12410 because that's immediately prior to creation of trunk/tags/branches.
svnadmin dump data/osm-sync -r 4743:12410 --incremental | svndumpfilter include --drop-empty-revs /applications/utils/osmosis > data/4-osm.dmp
check_errs $? "Dump 4 failed"

# Select the remaining osmosis data from the osm repo.  Start from 12412 (12411 is the re-organisation into trunk/tags/branches structure which we've already done).
svnadmin dump data/osm-sync -r 12412:HEAD --incremental | svndumpfilter include --drop-empty-revs "/applications/utils/osmosis" > data/5-osm.dmp
check_errs $? "Dump 5 failed"
