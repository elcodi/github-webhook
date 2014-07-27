#!/bin/bash
#
# This script is used to split the master version of elcodi/elcodi
# into several independent repositories. It now uses git filter-branch
# to execute the split. The same result, with a little more security,
# can be achieved by using "subtree split" in git v1.8
#
pushd /tmp
rm -rf elcodi.split
mkdir elcodi.split
pushd elcodi.split

rm -rf elcodi.main_repository
git clone git@github.com:elcodi/elcodi.git elcodi.main_repository
for i in $(ls -1 elcodi.main_repository/src/Elcodi/); do

    rm -rf elcodi.components.$i
    git clone git@github.com:elcodi/elcodi.git elcodi.components.$i;
    pushd elcodi.components.$i;
    git filter-branch --prune-empty --subdirectory-filter src/Elcodi/$i;
    git remote rm origin
    git remote add origin git@github.com:elcodi/$i.git
    git push origin master
    pwd
    popd
    rm -rf elcodi.components.$i
done
popd
rm -rf elcodi.split
