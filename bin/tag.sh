#!/bin/bash
#
# This script is used to tag all elcodi components when a new tag is created
# in the main elcodi repository
#
pushd /tmp
rm -rf elcodi.tags
mkdir elcodi.tags
pushd /elcodi.tags

rm -rf elcodi.main_repository
git clone git@github.com:elcodi/elcodi.git elcodi.main_repository
for i in $(ls -1 elcodi.main_repository/src/Elcodi/); do

    rm -rf elcodi.components.$i
    git clone git@github.com:elcodi/elcodi.git elcodi.components.$i;
    pushd elcodi.components.$i;
    git tag $1
    git push origin tag $1
    pwd
    popd
    rm -rf elcodi.components.$i
done
popd
rm -rf elcodi.tags