mkdir -p ./erln8
docker build -t reo/builder_1404 .
docker run -i -v ${PWD}/erln8:/erln8 reo/builder_1404 << COMMANDS
git clone https://github.com/erln8/reo.git
cd /reo
dub build
cp /reo/reo /erln8/erln8
cp /reo/reo /erln8/reo
cp /reo/reo /erln8/reo3
COMMANDS
cp ../../LICENSE ./erln8/
cp ../install.sh ./erln8/
tar cvzf erln8.tgz ./erln8/*

