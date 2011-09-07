#!/bin/sh

check_errs() {
	if [ "${1}" -ne "0" ]; then
		echo "ERROR # ${1} : ${2}"
		exit ${1}
    fi
}

function init_target_repo() {
	if [ -d data/target ]; then
		rm -rf data/target
		check_errs $? "Can't remove existing target repo"
	fi
	svnadmin create data/target
	check_errs $? "Can't create target repo"
	if [ -d target-wc ]; then
		rm -rf data/target-wc
		check_errs $? "Can't remove target working copy"
	fi
	# Allow properties to be manipulated.
	echo "#!/bin/sh" > data/target/hooks/pre-revprop-change
	chmod +x data/target/hooks/pre-revprop-change
	# Initialise the repo to contain the standard trunk/tags/branches layout.
	svn co file://`pwd`/data/target data/target-wc
	check_errs $? "Can't checkout target working copy"
	mkdir data/target-wc/trunk
	mkdir data/target-wc/tags
	mkdir data/target-wc/branches
	svn add --depth infinity data/target-wc/*
	check_errs $? "Can't add new directories in working copy"
	svn commit data/target-wc -m "Fabricated revision.  Created SVN migration repository structure."
	check_errs $? "Can't commit target changes"
	# Manipulate the timestamp of initial checkin to match the first osmosis commit.
	svn propset -r 1 --revprop "svn:date" "2007-04-04T12:58:38.510894Z" file://`pwd`/data/target
	check_errs $? "Can't set date properties"
}

# Create a new repository to contain the complete history.
init_target_repo

# Load the fixed dump files into the target repo.
svnadmin load data/target < data/1-bh.fixed.dmp
check_errs $? "Can't load dump 1"
svnadmin load data/target < data/2-bh.fixed.dmp
check_errs $? "Can't load dump 2"
svnadmin load data/target < data/3-bh.fixed.dmp
check_errs $? "Can't load dump 3"
svnadmin load data/target < data/4-osm.fixed.dmp
check_errs $? "Can't load dump 4"
svnadmin load data/target < data/5-osm.fixed.dmp
check_errs $? "Can't load dump 5"
