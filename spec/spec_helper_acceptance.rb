require 'beaker-rspec'
require 'pry'

hosts.each do |host|
  if host['platform'] =~ /debian-7/
    # We need augeas 1.2+
    on host, "echo deb http://pkg.camptocamp.net/apt wheezy/stable sysadmin > /etc/apt/sources.list.d/camptocamp.list"
    on host, 'wget http://pkg.camptocamp.net/packages-c2c-key.gpg'
    on host, 'apt-key add packages-c2c-key.gpg'
    on host, 'echo -e "Explanation: profiles_common: augeas\nPackage: augeas-lenses augeas-tools augeas-doc libaugeas0\nPin: release o=Camptocamp\nPin-Priority: 1100" > /etc/apt/preferences.d/augeas.pref'
  end
  # Install puppet
  if host['platform'] =~ /debian-8/
    install_package host, 'puppet'
  else
    install_puppet()
  end
  # Install ruby-augeas
  case fact('osfamily')
  when 'Debian'
    install_package host, 'libaugeas-ruby'
  when 'RedHat'
    install_package host, 'ruby-devel'
    install_package host, 'augeas-devel'
    on host, 'gem install ruby-augeas --no-ri --no-rdoc'
  else
    puts 'Sorry, this osfamily is not supported.'
    exit
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'varnish')
    hosts.each do |host|
      on host, puppet('module','install','camptocamp-systemd'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','herculesteam-augeasproviders_core'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','herculesteam-augeasproviders_shellvar'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-apt'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
