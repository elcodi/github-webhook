#!/bin/bash
#
# This script is used to update tags in subpackages
# of the main elcodi repository.
#
pushd /tmp
[ -d symfony.Elcodi.tmp ] && rm -rf symfony.Elcodi.tmp

git clone git@github.com:elcodi/elcodi.git symfony.Elcodi.tmp

pushd symfony.Elcodi.tmp
tags=$(git tag -l | sort -V)
popd

for i in $(ls -1 symfony.Elcodi.tmp/src/Elcodi/); do

    # Delete temporary subpackage
    rm -rf elcodi.$i
    # Clone master repo as subpackage
    git clone git@github.com:elcodi/elcodi.git elcodi.$i;

    pushd elcodi.$i

    # Change master repo remote to subpackage one
    git remote rm origin
    git remote add origin git@github.com:elcodi/$i.git

    for v in $tags; do

        git subtree split --prefix=src/Elcodi/$i --branch=branch-$v $v
        # Removing local tag
        git tag -d $v
        # Removing remote tag
        git push --tags origin :$v
        # Moving to filtered branch
        git checkout branch-$v
        # Creating tag pointing to temporary branch HEAD
        git tag $v
        # Push the new reference
        git push --tags origin $v

        # Go back to master and clean the temporary filtered branch
        git checkout master
        git branch -D branch-$v

    done

    popd
    rm -rf elcodi.$i
done
rm -rf /tmp/symfony.Elcodi.tmp
