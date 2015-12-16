# Installation

#### NOTE

## Latest Binary Releases

To install from a binary package:

```
tar xvzf ./erln8_<platform>.tgz
cd erln8_<platform>
./install.sh
```

![OSX Yosemite](img/apple_logo.png)

- [OSX Yosemite](https://s3.amazonaws.com/erln8/binaries/osx10.10/erln8_osx.tgz)

---

![Ubuntu](img/ubuntu_logo.png) &nbsp;&nbsp;&nbsp; ![Debian](img/debian_logo.png)

- [Ubuntu 15.04/Debian](https://s3.amazonaws.com/erln8/binaries/ubuntu1504/erln8_ubuntu1504.tgz)
- [Ubuntu 14.04/Debian](https://s3.amazonaws.com/erln8/binaries/ubuntu1404/erln8_ubuntu1404.tgz)

---

![Fedora](img/fedora_logo.png) &nbsp;&nbsp;&nbsp; ![CentOS](img/centos_logo.png)

- [Fedora/CentOS 7](https://s3.amazonaws.com/erln8/binaries/centos7/erln8_centos7.tgz)
- [Fedora/CentOS 6](https://s3.amazonaws.com/erln8/binaries/centos6/erln8_centos6.tgz)

---
![FreeBSD](img/freebsd_logo.png) FreeBSD (Currently unavailable)

---

## Building from source

### OSX Yosemite

To build manually, use the following:

```text
brew upgrade # required to pull in a newer version of DMD
brew install dmd dub
  # You MUST use DMD 2.076.1 or above
git clone https://github.com/erln8/erln8.git
cd erln8
make
make install

# erln8, reo, and reo3 are all installed in the local user home
# at ~/.erln8.d/bin
# YOU MUST ADD ~/.erln8.d/bin TO YOUR PATH!
```

### Ubuntu 14.04 / 15.04

```text
sudo apt-get install build-essential libncurses5-dev openssl libssl-dev fop xsltproc unixodbc-dev libglib2.0-dev git autoconf
sudo apt-get install xdg-utils

wget http://downloads.dlang.org/releases/2.x/2.067.1/dmd_2.067.1-0_amd64.deb
sudo dpkg -i dmd_2.067.1-0_amd64.deb

wget http://code.dlang.org/files/dub-0.9.23-linux-x86_64.tar.gz
tar xvzf dub-0.9.23-linux-x86_64.tar.gz
sudo mv dub /usr/local/bin/dub

git clone https://github.com/erln8/erln8.git
cd erln8
make
make install

# erln8, reo, and reo3 are all installed in the local user home
# at ~/.erln8.d/bin
# YOU MUST ADD ~/.erln8.d/bin TO YOUR PATH!
```

### Centos 6 / 7

```text
sudo yum install gcc glibc-devel make ncurses-devel openssl-devel autoconf git wget

wget http://downloads.dlang.org/releases/2.x/2.067.1/dmd-2.067.1-0.fedora.x86_64.rpm
sudo yum install dmd-2.067.1-0.fedora.x86_64.rpm

wget http://code.dlang.org/files/dub-0.9.23-1.x86_64.rpm
sudo yum install dub-0.9.23-1.x86_64.rpm


git clone https://github.com/erln8/erln8.git
cd erln8
make
make install

# erln8, reo, and reo3 are all installed in the local user home
# at ~/.erln8.d/bin
# YOU MUST ADD ~/.erln8.d/bin TO YOUR PATH!
```


## Ansible
[Tyler Cross](https://github.com/wtcross) put together an [Ansible playbook](https://galaxy.ansible.com/list#/roles/4412).

Soure located [here](https://github.com/wtcross/ansible-erln8).

## Chef

Here's a [Chef cookbook](https://github.com/erln8/erln8_chef) for installing erln8 in Ubuntu 15.04. You might be able to twist my arm to add other platforms.

## Puppet 

[Joseph Dunne](https://github.com/josephDunne) has started an erln8 [Puppet module](https://github.com/josephDunne/puppet-erln8).

## Docker

I release erln8 binaries via Docker. If you need to use a Dockerfile to build, check [this](https://github.com/erln8/erln8/tree/master/binary_gen) out.

---

© 2015 Dave Parfitt
