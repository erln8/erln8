mkdir -f ./artifacts
docker build -t reo/builder_1504 .
docker run -i -v ${PWD}/artifacts:/artifacts reo/builder_1504 << COMMANDS
git clone https://github.com/erln8/reo.git
cd /reo
dub build
cp /reo/reo /artifacts
COMMANDS
