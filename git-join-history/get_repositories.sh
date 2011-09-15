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

pushd .

cd data

# Synchronise the local repositories with the master repositories.
sync_repo bhmain-sync https://www.bretth.com/repos/main
sync_repo osm-sync http://svn.openstreetmap.org

popd

