mkdir -p ./artifacts
docker build -t reo/builder_centos6 .
docker run -i -v ${PWD}/artifacts:/artifacts reo/builder_centos6 << COMMANDS
git clone https://github.com/erln8/reo.git
cd /reo
dub build
cp /reo/reo /artifacts
COMMANDS
