#!/bin/sh

check_errs() {
	if [ "${1}" -ne "0" ]; then
		echo "ERROR # ${1} : ${2}"
		exit ${1}
    fi
}

pushd .
cd data

if false; then
if [ -d svn.git ]; then
	rm -rf svn.git
fi

git svn clone --stdlayout --no-metadata -A ../users.txt file://`pwd`/target svn.git
check_errs $? "Can't clone svn repository"

else
	rm -rf svn.git
	cp -a svn.git.bak svn.git
fi

cd svn.git

for TAG in $(git branch -r|grep tags/|cut -d / -f 2|grep -v test); do
	echo "Re-creating tag " ${TAG}
	git checkout -b ${TAG} remotes/tags/${TAG}
	check_errs $? "Can't checkout tag branch"
	git checkout master
	check_errs $? "Can't return to master branch"
	git tag ${TAG} ${TAG}
	check_errs $? "Can't create tag"
	git branch -D ${TAG}
	check_errs $? "Can't delete tag branch"
done

cd ..

if [ -d target.git ]; then
	rm -rf target.git
fi
git clone svn.git target.git

cd target.git

popd

