#!/bin/sh

# Put version tag
git config --global --add safe.directory /github/workspace

version=$(cat VERSION)
message=$(echo $INPUT_MESSAGE | sed s/__VERSION__/$version/g)
git config user.name $(git log -1 --pretty=format:'%an')
git config user.email $(git log -1 --pretty=format:'%ae')

# replace version tag
sed -i "s/.*Version:.*/Version: $version/" worker-procs.spec

if $INPUT_FORCE; then
    git tag -af $version -m "$message" && git push -f origin $version
else
    git ls-remote --exit-code --tags origin $version > /dev/null 2>&1 || (git tag -a $version -m "$message" && git push origin $version)
fi

# Build RPM module
rpmdev-setuptree
cp -r /github/workspace/* /root/rpmbuild/SOURCES/

rpmbuild -ba /github/workspace/config.spec
cp /root/rpmbuild/RPMS/x86_64/*.rpm /github/workspace/

# Upload RPM module to ssh server
yumServer=${INPUT_USERNAME}'@'${INPUT_HOSTNAME}
basePath="$yumServer:/home/dnsops/repos"

main = 'prod/centos/7/x86_64/gd-dnsops-prod-dns'
unstable = 'unstable/centos/7/x86_64/gd-dnsops-unstable-dns'

if [ $( git rev-parse --abbrev-ref HEAD )  = 'main' ]; then
    sshpass -p ${INPUT_PASSWORD} scp /github/workspace/--project---name---$(cat VERSION).src.rpm $basePath/$main/
elif  [ $( git rev-parse --abbrev-ref HEAD )  = 'unstable' ]; then
    sshpass -p ${INPUT_PASSWORD} scp /github/workspace/--project---name---$(cat VERSION).src.rpm $basePath/$main/
fi


echo "::set-output name=tag::$version"
