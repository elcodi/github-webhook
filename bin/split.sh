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
pushd symfony.Elcodi.tmp

# Retrieve the las tag associated to HEAD, if any
TAG=$(git describe --exact-match --tags || echo "NOTAG");

echo TAG IS $TAG

# If a tag is present, we first have to REMOVE it
# and then add a tag with the same name to the HEAD
# of each splitted branch, push that branch along
# with the newly created tag to the subpackage remote
# and then repeate the process for the remaining subpackages
[ "$TAG" != "NOTAG" ] && git tag -d $TAG

# Split of all existing Bundles

for i in $(ls -1 src/Elcodi/Bundle/); do

    # Split the main repo according to the subpackage and
    # put the resulting commits in separate branch
    git subtree split -q --prefix=src/Elcodi/Bundle/$i --branch=branch-$i

    # Remove current remote
    git remote rm origin

    # Add a remote named after current subpackage
    git remote add origin git@github.com:elcodi/$i.git

    # Checkout the recently filtered branch (may be optional)
    git checkout branch-$i

    # Push the filtered commits to remote master
    git push origin branch-$i:master

    # If a tag exists, we need to create a new one named $TAG
    # pointing to the HEAD of the newly splitted commits and
    # then push it to the subpackage remote
    if [ "$TAG" != "NOTAG" ]
    then
        git tag -a $TAG -m "Created tag $TAG"
        COMMIT=$(git rev-list HEAD -1)
        echo "Pushing tag $TAG to repo $i as commit $COMMIT"
        git push origin $TAG

        # Tag must be deleted every time since we do not
        # want to push commits belonging to other subpackages
        # to current subpackage remote
        git tag -d $TAG
    fi

    # Go back to HEAD in master of the main repo
    git checkout master
done

# Split of all existing Components

for i in $(ls -1 src/Elcodi/Component/); do

    # Split the main repo according to the subpackage and
    # put the resulting commits in separate branch
    git subtree split -q --prefix=src/Elcodi/Component/$i --branch=branch-$i

    # Remove current remote
    git remote rm origin

    # Add a remote named after current subpackage
    git remote add origin git@github.com:elcodi/$i.git

    # Checkout the recently filtered branch (may be optional)
    git checkout branch-$i

    # Push the filtered commits to remote master
    git push origin branch-$i:master

    # If a tag exists, we need to create a new one named $TAG
    # pointing to the HEAD of the newly splitted commits and
    # then push it to the subpackage remote
    if [ "$TAG" != "NOTAG" ]
    then
        git tag -a $TAG -m "Created tag $TAG"
        COMMIT=$(git rev-list HEAD -1)
        echo "Pushing tag $TAG to repo $i as commit $COMMIT"
        git push origin $TAG

        # Tag must be deleted every time since we do not
        # want to push commits belonging to other subpackages
        # to current subpackage remote
        git tag -d $TAG
    fi

    # Go back to HEAD in master of the main repo
    git checkout master
done

# Split of all existing Plugins

for i in $(ls -1 src/Elcodi/Plugin/); do

    # Split the main repo according to the subpackage and
    # put the resulting commits in separate branch
    git subtree split -q --prefix=src/Elcodi/Plugin/$i --branch=branch-$i

    # Remove current remote
    git remote rm origin

    # Add a remote named after current subpackage
    git remote add origin git@github.com:elcodi-plugins/$i.git

    # Checkout the recently filtered branch (may be optional)
    git checkout branch-$i

    # Push the filtered commits to remote master
    git push origin branch-$i:master

    # If a tag exists, we need to create a new one named $TAG
    # pointing to the HEAD of the newly splitted commits and
    # then push it to the subpackage remote
    if [ "$TAG" != "NOTAG" ]
    then
        git tag -a $TAG -m "Created tag $TAG"
        COMMIT=$(git rev-list HEAD -1)
        echo "Pushing tag $TAG to repo $i as commit $COMMIT"
        git push origin $TAG

        # Tag must be deleted every time since we do not
        # want to push commits belonging to other subpackages
        # to current subpackage remote
        git tag -d $TAG
    fi

    # Go back to HEAD in master of the main repo
    git checkout master
done

rm -rf /tmp/symfony.Elcodi.tmp
