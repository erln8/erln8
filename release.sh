#!/bin/sh
# bump ./src/VERSION
perl -p -i -e 's/^((\d+\.)*)(\d+)(.*)$/$1.($3+1).$4/e' ./src/VERSION
next_version=`cat ./src/VERSION`
echo Generating $next_version
echo "const ERLN8_VERSION=\"${next_version}\";" > ./src/version_gen.d
git add ./src/version_gen.d
git commit -m "bumped versioon to ${next_version}"
git tag $next_version
git push origin master
git push origin --tags
make docs
cd ./binary_gen && make
