mkdir -p ./erln8
docker build -t reo/builder_centos6 .
docker run -i -v ${PWD}/erln8:/erln8 reo/builder_centos6 << COMMANDS
git clone https://github.com/erln8/erln8.git
cd /erln8
dub build
cp /erln8/reo /erln8/erln8
cp /erln8/reo /erln8/reo
cp /erln8/reo /erln8/reo3
COMMANDS
cp ../../LICENSE ./erln8/
cp ../install.sh ./erln8/
tar cvzf erln8_centos6.tgz ./erln8/*

