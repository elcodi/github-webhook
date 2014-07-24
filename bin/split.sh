#!/bin/bash
#
# This script is used to split the master version of elcodi/elcodi
# into several independent repositories. It now uses git filter-branch
# to execute the split. The same result, with a little more security,
# can be achieved by using "subtree split" in git v1.8
#
pushd /tmp
rm -rf symfony.Elcodi.tmp
git clone git@github.com:elcodi/elcodi.git symfony.Elcodi.tmp
for i in $(ls -1 symfony.Elcodi.tmp/src/Elcodi/); do
    rm -rf elcodi.$i
    git clone git@github.com:elcodi/elcodi.git elcodi.$i;
    pushd elcodi.$i;
    git filter-branch --prune-empty --subdirectory-filter src/Elcodi/$i;
    git remote rm origin
    git remote add origin git@github.com:elcodi/$i.git
    git push origin master
    pwd
    popd
    rm -rf elcodi.$i
done
rm -rf /tmp/symfony.Elcodi.tmp
