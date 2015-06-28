import tinys3
import os

S3_ACCESS_KEY = os.environ.get('AWSAccessKeyId')
S3_SECRET_KEY = os.environ.get('AWSSecretKey')

conn = tinys3.Connection(S3_ACCESS_KEY,S3_SECRET_KEY)

# osx upload is separate
# as it's the platform I'm developing on
print "Uploading OSX binaries"
fosx = open('./osx/erln8.tgz','rb')
conn.upload('erln8_osx.tgz', fosx, 'erln8/binaries/osx10.10')

def uploadObject(platform):
    filename = 'erln8_' + platform + ".tgz"
    localpath = os.path.join(platform, filename)
    remotepath = "erln8/binaries/" + platform
    print localpath
    print remotepath
    print "---"
    f = open(localpath,'rb')
    conn.upload(filename,f,remotepath)

platforms = ["centos6", "centos7", "ubuntu1404", "ubuntu1504"]
map(uploadObject, platforms)
