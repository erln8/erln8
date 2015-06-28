import tinys3
import os

S3_ACCESS_KEY = os.environ.get('AWSAccessKeyId')
S3_SECRET_KEY = os.environ.get('AWSSecretKey')

conn = tinys3.Connection(S3_ACCESS_KEY,S3_SECRET_KEY)

# osx upload is separate
# as it's the platform I'm developing on
fosx = open('../reo','rb')
conn.upload('erln8',fosx,'erln8/binaries/osx10.10')

def uploadObject(platform):
    localpath = os.path.join(platform,'artifacts/reo')
    remotepath = "erln8/binaries/" + platform
    print localpath
    print remotepath
    print "---"
    f = open(localpath,'rb')
    conn.upload('erln8',f,remotepath)

platforms = ["centos6", "centos7", "ubuntu1404", "ubuntu1504"]
map(uploadObject, platforms)
