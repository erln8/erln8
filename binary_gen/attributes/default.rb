
default['apt']['compile_time_update'] = true

default['binary_gen']['git_repository'] = "https://github.com/metadave/reo.git"

default['binary_gen']['dub_url'] = "http://code.dlang.org/files/dub-0.9.23-linux-x86_64.tar.gz"
default['binary_gen']['dub_filename'] = "dub-0.9.23-linux-x86_64.tar.gz"

case node['platform_family']
when 'rhel', 'fedora'
  default['binary_gen']['dmd_url'] = "x"
  default['binary_gen']['dmd_filename'] = "x"
when 'debian'
  default['binary_gen']['dmd_url'] = "http://downloads.dlang.org/releases/2.x/2.067.0/dmd_2.067.0-0_amd64.deb"
  default['binary_gen']['dmd_filename'] = "dmd_2.067.0-0_amd64.deb"
else
  default['binary_gen']['dmd_url'] = "y"
  default['binary_gen']['dmd_filename'] = "y"
end
